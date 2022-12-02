{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.gitlab;
  gitlab_secret = name: libdata.set_secret {
    user = "gitlab";
    path = ["services" "gitlab" config.base.hostname name];
  };
in
libconf.create_common_confs [
  {
    name = "gitlab";
    parents = [ "services" ];
    add_pkgs = [
      pkgs.nginx
    ];
    add_opts.backup = {
      repo_path = lib.mkOption {
        type = lib.types.str;
        description = "Path to the restic repository";
        default = "/var/backup/gitlab";
      };
      timerConfig = lib.mkOption {
        type = lib.types.anything;
        description = "Timer config for the systemd service";
        default = { OnCalendar = "daily"; };
      };
      pruneOpts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Options of snapshots forget";
        default = ["-y 10" "-m 12" "-w 4" "-d 30" "-l 5"];
      };
      gdrive = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable saving the backup to Google Drive";
      };
    };
    cfg = {
      setup.directories = [
        { path = cfg.backup.repo_path; perms = "700"; owner = "gitlab"; }
      ];
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40080; guest.port = 80; };
        https= { from = "host"; host.port = 40443; guest.port = 443; };
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];

      networking.extraHosts = ''
        127.0.0.1 ${config.services.gitlab.host}
        127.0.0.1 smtp.${config.base.networking.domain}
      '';

      users.users."${config.base.user}".extraGroups = [ "gitlab" ];
      users.extraUsers.gitlab.extraGroups = [ "nginx" ];

      base.secrets.store = {
        gitlab_secretFile = gitlab_secret "secretfile";
        gitlab_otpFile = gitlab_secret "otp";
        gitlab_jwsFile = gitlab_secret "session";
        gitlab_dbFile = gitlab_secret "db";
        gitlab_dbpwd = gitlab_secret "dbpwd";
        gitlab_initialrootpwd = gitlab_secret "initial_root_pwd";
        gitlab_restic_repo_pwd = gitlab_secret "restic_repo_pwd";
      };

      services.nginx = {
        enable = true;
        virtualHosts."git.${config.base.networking.domain}" = {
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
        virtualHosts."git.localhost" = {
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
      };

      # TODO  Modify the default database port to postgresql in nixpkgs (upstream)
      services.gitlab = rec {
        enable = true;
        packages.gitlab = pkgs.gitlab-ee;

        host = "git.${config.base.networking.domain}";
        port = 80;
        extraDatabaseConfig.port = config.services.postgresql.port;

        databasePasswordFile = config.base.secrets.store.gitlab_dbpwd.dest;
        initialRootEmail = config.base.email;
        initialRootPasswordFile = config.base.secrets.store.gitlab_initialrootpwd.dest;

        # TODO Set up HTTPS with
        # https://nixos.org/manual/nixos/stable/#module-security-acme-nginx
        # https://nixos.wiki/wiki/Nginx
        https = false; #true;
        smtp.enable = true;
        secrets = {
          dbFile = config.base.secrets.store.gitlab_dbFile.dest;
          secretFile = config.base.secrets.store.gitlab_secretFile.dest;
          otpFile = config.base.secrets.store.gitlab_otpFile.dest;
          jwsFile = config.base.secrets.store.gitlab_jwsFile.dest;
        };

        extraConfig = {
          gitlab = {
            email_from = "gitlab-no-reply@example.com";
            email_display_name = "Example GitLab";
            email_reply_to = "gitlab-no-reply@example.com";
            default_projects_features = { builds = false; };
          };
        };
        backup.path = "/var/gitlab/backup/";
      };

      services.restic.backups.gitlab = {
        initialize = true;
        passwordFile = config.base.secrets.store.gitlab_restic_repo_pwd.dest;
        repository = cfg.backup.repo_path;
        timerConfig = {
          Persistent = true;
        } // cfg.backup.timerConfig;
        pruneOpts = cfg.backup.pruneOpts;
        user = "gitlab";
        paths = [ "/tmp/gitlab_backup_restic/" ];
        backupPrepareCommand = ''
          set -e
          export PATH="/run/current-system/sw/bin/"
          export CRON=1
          export RAILS_ENV="production"
          export BACKUP="restic"
          gitlab-rake gitlab:backup:create

          extract_part() {
              name=$1
              echo "Extracting part \"$name\""
              mkdir -p ./$name
              tar xf "$name.tar" -C ./$name
              rm "$name.tar"
          }

          SOURCE=/var/gitlab/backup/restic_gitlab_backup.tar
          OUTPUT=/tmp/gitlab_backup_restic/

          echo "Extract the archive"
          rm -rf $OUTPUT && mkdir $OUTPUT
          tar xf $SOURCE --directory $OUTPUT

          echo "Decompress the parts"
          find $OUTPUT -name "*.gz" | xargs gunzip
          pushd $OUTPUT 1>/dev/null

          extract_part "artifacts"
          extract_part "builds"
          extract_part "lfs"
          extract_part "packages"
          extract_part "pages"
          extract_part "terraform_state"
          extract_part "uploads"
          popd 1>/dev/null

          rm $SOURCE
      '';
      } // (if (builtins.isNull cfg.backup.gdrive) then {} else {
        rcloneOptions.drive-use-trash = "false";
        rcloneConfigFile = config.base.secrets.store.gitlab_rclone_conf.dest;
        backupCleanupCommand = let
          rclone = "${pkgs.rclone}/bin/rclone -q --config /tmp/rclone_gitlab/gdrive.conf";
        in ''
          mkdir -p /tmp/rclone_gitlab
          cp ${config.base.secrets.store.gitlab_rclone_conf.dest} /tmp/rclone_gitlab/gdrive.conf
          chmod 700 -R /tmp/rclone_gitlab
          ${rclone} sync ${cfg.backup.repo_path} gdrive:${config.base.hostname}_gitlab_backup
          rm -r /tmp/rclone_gitlab
        '';
      });
      base.secrets.store.gitlab_rclone_conf = lib.mkIf cfg.backup.gdrive (
        gitlab_secret "gdrive.conf"
      );
    };
  }

  {
    name = "runners";
    parents = [ "services" "gitlab" ];
    add_opts = {
      nb_jobs = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of jobs to start in parallel";
      };
      services = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Images to use for services";
      };
      add_nix_service = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Wether to add a service to build using the host's nix store";
      };
    };
    cfg = {
      virtualisation.docker.enable = true;
      base.secrets.store.gitlab_runner_registrationConfigFile = libdata.write_secret_file {
        user = "root";
        filename = "gitlab_runner_registrationConfigFile";
        text = let
          vars = {
            CI_SERVER_URL="http://git.${config.base.networking.domain}";
            REGISTRATION_TOKEN=builtins.readFile (libdata.get_data_path
              [ "secrets" "services" "gitlab" config.base.hostname "runner_registration_token"]
            );
          } // (if config.cmn.services.gitlab.enable then {
            DOCKER_NETWORK_MODE="host";
          } else {});
        in (builtins.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList (name: var: "${name}=\"${var}\"") vars));
        };

        services.gitlab-runner = {
          enable = true;
          settings.concurrent = cfg.runners.nb_jobs;
          services = (builtins.mapAttrs (name:
            { runnerOpts ? {}, runnerEnvs ? {}, ...} : lib.attrsets.recursiveUpdate {
            registrationConfigFile =
                config.base.secrets.store.gitlab_runner_registrationConfigFile.dest;
            environmentVariables = runnerEnvs;
          } runnerOpts) cfg.runners.services) // (if cfg.runners.add_nix_service then
          { nix = {
            registrationConfigFile = config.base.secrets.store.gitlab_runner_registrationConfigFile.dest;
            dockerImage = "alpine";
            dockerVolumes = [
              "/nix/store:/nix/store:ro"
              "/nix/var/nix/db:/nix/var/nix/db:ro"
              "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            ];
            dockerDisableCache = true;
            preBuildScript = pkgs.writeScript "setup-container" ''
              mkdir -p -m 0755 /nix/var/log/nix/drvs
              mkdir -p -m 0755 /nix/var/nix/gcroots
              mkdir -p -m 0755 /nix/var/nix/profiles
              mkdir -p -m 0755 /nix/var/nix/temproots
              mkdir -p -m 0755 /nix/var/nix/userpool
              mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
              mkdir -p -m 1777 /nix/var/nix/profiles/per-user
              mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
              mkdir -p -m 0700 "$HOME/.nix-defexpr"

              . ${pkgs.nix}/etc/profile.d/nix.sh

              ${pkgs.nix}/bin/nix-env -i ${builtins.concatStringsSep " " (with pkgs; [ nix cacert git openssh ])}

              ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
              ${pkgs.nix}/bin/nix-channel --update nixpkgs
            '';
            environmentVariables = {
              ENV = "/etc/profile";
              USER = "root";
              NIX_REMOTE = "daemon";
              PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
              NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
            };
            tagList = [ "nix" ];
          };} else {});
        };
    };
  }
]

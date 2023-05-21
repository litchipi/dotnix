{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libextbk = import ../../lib/external_backup.nix {inherit config lib pkgs;};

  cfg = config.services.gitlab;
in
  {
    options.services.gitlab = {
      secrets = lib.mkOption {
        type = lib.types.attrsets;
        description = "Secrets to use for the gitlab configuration";
      };
      backup = {
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
        external_copy = libextbk.mkOption;
      };
    };
    config = {
      setup.directories = [
        { path = cfg.backup.repo_path; perms = "700"; owner = "gitlab"; }
      ];
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40080; guest.port = 80; };
        https= { from = "host"; host.port = 40443; guest.port = 443; };
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];

      base.networking.subdomains = [
        "git"
        "smtp"
      ];

      users.users."${config.base.user}".extraGroups = [ "gitlab" ];
      users.extraUsers.gitlab.extraGroups = [ "nginx" ];

      secrets.store.services.gitlab = pkgs.secrets.set_common_config {
        enable = true;
        user = config.services.gitlab.user;
      } cfg.secrets;

      services.nginx = {
        enable = true;
        virtualHosts = {
          "git.${config.base.networking.domain}" = {
            locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
          };
        } // (if config.base.networking.domain != "localhost" then {
          "git.localhost" = {
            locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
          };
        } else {});
      };

      # TODO  Modify the default database port to postgresql in nixpkgs (upstream)
      services.gitlab = rec {
        enable = true;
        packages.gitlab = pkgs.gitlab-ee;

        host = "git.${config.base.networking.domain}";
        port = 80;
        extraDatabaseConfig.port = config.services.postgresql.port;

        databasePasswordFile = cfg.secrets.dbpwd.file;
        initialRootEmail = config.base.email;
        initialRootPasswordFile = cfg.secrets.initial_root_pwd.file;

        # TODO Set up HTTPS with
        # https://nixos.org/manual/nixos/stable/#module-security-acme-nginx
        # https://nixos.wiki/wiki/Nginx
        https = false; #true;
        smtp.enable = true;
        secrets = {
          dbFile = cfg.secrets.db.file;
          secretFile = cfg.secrets.secretfile.file;
          otpFile = cfg.secrets.otp.file;
          jwsFile = cfg.secrets.session.file;
        };

        extraConfig = {
          gitlab = {
            email_from = "gitlab-no-reply@example.com";
            email_display_name = "Example GitLab";
            email_reply_to = "gitlab-no-reply@example.com";
            default_projects_features = { builds = false; };
          };
        };
        # TODO    Make this path configurable
        backup.path = "/var/gitlab/backup/";
      };

      services.restic.backups.gitlab = {
        initialize = true;
        passwordFile = cfg.secrets.restic_repo_pwd.file;
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
      };
      fileSystems = libextbk.mkFileSystems cfg.backup.external_copy;
      systemd.services = libextbk.mkSystemdService cfg.backup.external_copy {
        basename = "restic_gitlab_backup";
        bind = "restic-backups-gitlab.service";
        paths.${cfg.backup.repo_path} = "${config.base.hostname}/gitlab";
      } // (libextbk.mkGdriveBckService {
        basename = "restic_gitlab_backup";
        enabled = cfg.backup.gdrive;
        bind = "restic-backups-gitlab.service";
        rclone_conf = cfg.secrets.rclone_gdrive.file;
        paths.${cfg.backup.repo_path} = "${config.base.hostname}_gitlab_backup";
      });
    };
  }

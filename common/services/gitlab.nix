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
    cfg = {
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

      base.secrets.store = {
        gitlab_secretFile = gitlab_secret "secretfile";
        gitlab_otpFile = gitlab_secret "otp";
        gitlab_jwsFile = gitlab_secret "session";
        gitlab_dbFile = gitlab_secret "db";
        gitlab_dbpwd = gitlab_secret "dbpwd";
        gitlab_initialrootpwd = gitlab_secret "initial_root_pwd";
      };

      services.nginx = {
        enable = true;
        virtualHosts."git.${config.base.networking.domain}" = {
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
      };

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
        smtp = {
          enable = true;
          address = "smtp.${config.base.networking.domain}";
          port = 25;
        };
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

      cmn.services.restic.global = {
        prepare_script = let 
          gitlab_unpack_backup = pkgs.writeShellScript "gitlab_unpack_backup" ''
            extract_part() {
                name=$1
                echo "Extracting part \"$name\""
                mkdir -p ./$name
                tar xf "$name.tar" -C ./$name
                rm "$name.tar"
            }

            if [ $# -ne 2 ]; then
                echo "Usage: $0 <gitlab backup archive path> <output directory>"
                exit 1;
            fi

            SOURCE=$1
            OUTPUT=$2

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
            echo "Done"
          '';
        in [''
          export PATH="/run/current-system/sw/bin/"
          export BACKUP=restic
          export RAILS_ENV=production
          export CRON=1
          mkdir -p /var/gitlab/backup
          gitlab-rake gitlab:backup:create

          cd /var/gitlab/backup
          ${gitlab_unpack_backup} ./restic_gitlab_backup.tar ./unpacked
          rm ./restic_gitlab_backup.tar
        ''];
        cleanup_script = [''
          rm -r /var/gitlab/backup/unpacked
        ''];
        backup_paths = [ "/var/gitlab/backup/unpacked" ];
        groups = ["gitlab"];
      };
    };
  }
]

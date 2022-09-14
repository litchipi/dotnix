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
      };
    };
  }

  {
    name = "restic_backup";
    parents = ["services", "gitlab"];
    add_opts = {
      repo_path = lib.mkOption {
        type = lib.types.str;
        description = "Path of the restic repo on the disk";
        default = "/var/userbackup/gitlab/";
      };
      timerConfig = lib.mkOption {
        type = lib.attrs;
        description = "Timer configuration in the format of systemd.time";
        default = { OnCalendar = "daily"; };
      };
      gdrive = lib.types.submodule {
        options.enable = lib.mkEnableOption { description = "Enable google drive backup" };
        options.rcloneConfigFile = lib.mkOption {
          type = lib.types.str;
          description = "Path to the Rclone config file";
        };
      };
    };
    cfg = {
      # TODO  Set up systemd service that backups gitlab data into a restic repo on disk
      #   Then (if set) upload everything to google drive via rclone
    };
  }
]

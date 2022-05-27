{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.gitlab;
  gitlab_secret = name: libdata.set_secret "gitlab" ["services" "gitlab" config.base.hostname name] {};
in
libconf.create_common_confs [
  {
    name = "gitlab";
    parents = [ "services" ];
    add_opts = {
      port = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Gitlab server";
        default = 4005;
      };
    };
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

      base.secrets.secrets = {
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

      services.gitlab = {
        enable = true;
        packages.gitlab = pkgs.gitlab-ee;
        host = "git.${config.base.networking.domain}";
        databasePasswordFile = config.base.secrets.gitlab_dbpwd.dest;
        initialRootPasswordFile = config.base.secrets.gitlab_initialrootpwd.dest;
        # TODO Set up HTTPS with
        # https://nixos.org/manual/nixos/stable/#module-security-acme-nginx
        # https://nixos.wiki/wiki/Nginx
        https = false; #true;
        port = cfg.port;
        smtp = {
          enable = true;
          address = "smtp.${config.base.networking.domain}";
          port = 25;
        };
        secrets = {
          dbFile = config.base.secrets.gitlab_dbFile.dest;
          secretFile = config.base.secrets.gitlab_secretFile.dest;
          otpFile = config.base.secrets.gitlab_otpFile.dest;
          jwsFile = config.base.secrets.gitlab_jwsFile.dest;
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
]

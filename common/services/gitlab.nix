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
    virtualisation_cfg.forwardPorts = [
      { from = "host"; host.port = 40000 + cfg.port; guest.port = cfg.port; }
    ];
    cfg = {
      networking.firewall.enable = false; #allowedTCPPorts = [ cfg.port ];

      base.secrets = {
        gitlab_secretFile = gitlab_secret "secretfile";
        gitlab_otpFile = gitlab_secret "otp";
        gitlab_jwsFile = gitlab_secret "session";
        gitlab_dbFile = gitlab_secret "db";
        gitlab_dbpwd = gitlab_secret "dbpwd";
        gitlab_smtp = gitlab_secret "smtp";
        gitlab_initialrootpwd = gitlab_secret "initial_root_pwd";
      };

      services.nginx = {
        enable = true;
        virtualHosts."git.${config.base.networking.domain}" = {
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
      };

      # TODO FIXME  Doesn't work yet: Bind the socket file to the port
      # unix:/tmp/socktest.sock
      #"http://unix:/run/gitlab/gitlab-workhorse.socket";
      services.gitlab = {
        enable = true;
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
        # TODO Assertions on the password strength
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

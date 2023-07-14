{ config, lib, pkgs, ... }:
let
  libbck = import ../../lib/services/restic.nix {inherit config lib pkgs;};

  cfg = config.services.paperless;
  sub = "paper";
  fqdn = "${sub}.${config.base.networking.domain}";
in
  {
    options.services.paperless = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Paperless";
      backup = libbck.mkBackupOptions {
        name = "paperless";
        basedir = "/var/backup/";
      };
    };
    config = lib.attrsets.recursiveUpdate {
      secrets.setup.paperless = {
        user = config.services.paperless.user;
        secret = cfg.secrets;
      };
      base.networking.subdomains = [ sub ];

      services.paperless = {
        enable = true;
        dataDir = lib.mkDefault "/var/lib/paperless";
        passwordFile = cfg.secrets.admin_pwd.file;
      };

      services.nginx = {
        enable = true;
        virtualHosts.${fqdn}.locations."/".proxyPass =
          "http://${config.services.paperless.address}:${
            builtins.toString config.services.paperless.port
          }";
      };
    } (libbck.mkBackupConfig {
      name = "paperless";
      cfg = cfg.backup;
      user = config.services.paperless.user;
      paths = [ config.services.paperless.dataDir ];
      secrets = cfg.secrets;
    });
  }

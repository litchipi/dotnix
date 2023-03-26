{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libbck = import ../../lib/services/restic.nix {inherit config lib pkgs;};

  cfg = config.services.paperless;
  sub = "paper";
  fqdn = "${sub}.${config.base.networking.domain}";
in
  {
    options.services.paperless = {
      secrets = lib.mkOption {
        type = lib.types.attrsets;
        description = "Secrets for the Paperless service";
      };
      backup = libbck.mkBackupOptions {
        name = "paperless";
      };
    };
    config = lib.attrsets.recursiveUpdate {
      base.networking.subdomains = [ sub ];

      secrets.store.services.paperless = libdata.set_common_secret_config {
        user = config.services.paperless.user;
      } config.secrets.store.services.paperless;

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

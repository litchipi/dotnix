{ config, lib, pkgs, ... }:
let
  libbck = import ../../lib/services/restic.nix {inherit config lib pkgs;};

  cfg = config.services.shiori;
  sub = "bookmarks";
  fqdn = "${sub}.${config.base.networking.domain}";
in
  # TODO    Upstream changes
  {
    options.services.shiori = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Shiori";
      backup = libbck.mkBackupOptions {
        name = "shiori";
        basedir = "/var/backup";
      };
    };

    config = lib.attrsets.recursiveUpdate {
      base.networking.subdomains = [ sub ];

      services.nginx = {
        enable = true;
        virtualHosts.${fqdn}.locations."/".proxyPass =
          "http://${cfg.address}:${builtins.toString cfg.port}";
      };
    } (libbck.mkBackupConfig {
      name = "shiori";
      cfg = cfg.backup;
      user = "root";
      paths = [ "${config.systemd.services.shiori.environment.SHIORI_DIR}" ];
      secrets = cfg.secrets;
    });
  }

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
      port = lib.mkOption {
        type = lib.types.int;
        default = 45631;
        description = "On which port serve the Shiori service";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "On which address serve the Shiori service";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/shiori";
        description = "Where to store the Shiori data";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "shiori";
        description = "User running the service";
      };
      backup = libbck.mkBackupOptions {
        name = "shiori";
      };
    };

    config = lib.attrsets.recursiveUpdate {
      base.networking.subdomains = [ sub ];
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.user;
      };
      users.groups.${cfg.user} = {};

      systemd.services.shiori = {
        description = "Shiori simple bookmarks manager";
        wantedBy = [ "multi-user.target" ];
        environment.SHIORI_DIR = cfg.dataDir;
        script = ''
          ${pkgs.shiori}/bin/shiori migrate
          ${pkgs.shiori}/bin/shiori serve \
            --address '${cfg.address}' \
            --port '${builtins.toString cfg.port}'
        '';
      };

      services.nginx = {
        enable = true;
        virtualHosts.${fqdn}.locations."/".proxyPass =
          "http://${cfg.address}:${builtins.toString cfg.port}";
      };
    } (libbck.mkBackupConfig {
      name = "shiori";
      cfg = cfg.backup;
      user = cfg.user;
      paths = [ "${cfg.dataDir}/shiori.db" ];
      secrets = config.secrets.store.services.shiori.${config.base.hostname};
    });
  }

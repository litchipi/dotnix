{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libbck = import ../../lib/services/restic.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.shiori;
  fqdn = "bookmarks.${config.base.networking.domain}";
in
  # TODO    Upstream changes
libconf.create_common_confs [
  {
    name = "shiori";
    parents = [ "services" ];
    add_opts = {
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
    cfg = lib.attrsets.recursiveUpdate {
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
    });
  }
]

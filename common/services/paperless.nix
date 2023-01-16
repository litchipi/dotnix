{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libbck = import ../../lib/services/restic.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.paperless;
  sub = "paper";
  fqdn = "${sub}.${config.base.networking.domain}";
in
libconf.create_common_confs [
  {
    name = "paperless";
    parents = [ "services" ];
    add_opts.backup = libbck.mkBackupOptions {
      name = "paperless";
    };
    cfg = lib.attrsets.recursiveUpdate {
      base.networking.subdomains = [ sub ];
      base.secrets.store.paperless_admin_pwd = libdata.set_secret {
        user = config.services.paperless.user;
        path = [ "services" "paperless" config.base.hostname "admin_pwd" ];
      };

      services.paperless = {
        enable = true;
        dataDir = "/var/paperless";
        passwordFile = config.base.secrets.store.paperless_admin_pwd.dest;
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
      cfg = config.cmn.services.paperless.backup;
      user = config.services.paperless.user;
      paths = [ config.services.paperless.dataDir ];
    });
  }
]

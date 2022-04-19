{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../../lib/utils.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.nextcloud;
  nextcloud_secret = name: libdata.set_secret "nextcloud" ["services" "nextcloud" config.base.hostname name] {};
in
libconf.create_common_confs [
  {
    name = "nextcloud";
    parents = [ "services" ];

    add_opts = {
      port = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Nextcloud server";
        default = 4006;
      };
      dbport = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Nextcloud database";
        default = 4007;
      };
      dbhost = lib.mkOption {
        type = lib.types.str;
        description = "Host of the Nextcloud database";
        default = "localhost";
      };
    };
    add_pkgs = with pkgs; [
      nextcloud23
    ];
    virtualisation_cfg.forwardPorts = [
      { from = "host"; host.port = 40080; guest.port = 80; }
      { from = "host"; host.port = 40443; guest.port = 443; }
    ];
    cfg = {
      base.secrets = {
        nextcloud_dbpass = nextcloud_secret "dbpass";
        nextcloud_adminpass = nextcloud_secret "adminpass";
      };

      services.nextcloud = {
        enable = true;
        hostName = "nextcloud.${config.base.networking.domain}";
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          adminpassFile = config.base.secrets.nextcloud_adminpass.dest;
          adminuser = "root";
        };
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "nextcloud" ];
        ensureUsers = [
         { name = "nextcloud";
           ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
         }
        ];
      };

      # ensure that postgres is running *before* running the setup
      systemd.services."nextcloud-setup" = {
        requires = ["postgresql.service"];
        after = ["postgresql.service"];
      };

      networking.firewall.enable = false; #allowedTCPPorts = [ 80 443 ];
    };
  }

  {
    name = "maps";
    parents = [ "services" "nextcloud"];
    cfg.services.nextcloud.extraApps.maps = pkgs.fetchNextcloudApp {
      name = "maps";
      sha256 = "007y80idqg6b6zk6kjxg4vgw0z8fsxs9lajnv49vv1zjy6jx2i1i";
      url = "https://github.com/nextcloud/maps/releases/download/v0.1.9/maps-0.1.9.tar.gz";
      version = "0.1.9";
    };
  }
]

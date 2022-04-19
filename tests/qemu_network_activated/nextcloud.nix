{ config, lib, pkgs, ... }:
let
  cfg = config.cmn.services.nextcloud;
in
{
  options.cmn.services.nextcloud = {
    enable = lib.mkEnableOption {
      description = "Enable nextcloud service";
    };

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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nextcloud23
    ];
    
    services.nextcloud = {
      enable = true;
      hostName = "localhost";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminpassFile = "/etc/nextcloud-password";
        adminuser = "root";
      };
    };

    environment.etc."nextcloud-password" = {
      text = "adminpass";
      mode = "0400";
      uid = 0;
      gid = 0;
      user = "nextcloud";
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

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
# {
#   name = "maps";
#   parents = [ "services" "nextcloud"];
#   cfg.services.nextcloud.extraApps.maps = pkgs.fetchNextcloudApp {
#     name = "maps";
#     sha256 = "007y80idqg6b6zk6kjxg4vgw0z8fsxs9lajnv49vv1zjy6jx2i1i";
#     url = "https://github.com/nextcloud/maps/releases/download/v0.1.9/maps-0.1.9.tar.gz";
#     version = "0.1.9";
#   };
# }

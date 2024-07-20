{ config, lib, pkgs, ... }:
let
  cfg = config.services.firefly-iii.data-importer;
  pkg = import ./package.nix pkgs;
in
{
  options.services.firefly-iii.data-importer = {
    enable = lib.mkEnableOption { description = "Firefly-iii Data importer service"; };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address on which the service should listen.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Port on which to serve the Mealie service.";
    };

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
      description = ''
        Configuration of the Firefly-iii Data importer service.

        See [the documentation](https://docs.firefly-iii.org/how-to/data-importer/how-to-configure/) for available options and default values.
      '';
      example = {
        FIREFLY_III_URL = "http://app.url:8000";
      };
    };
  };

  config = let 
    user = config.services.firefly-iii.user;
  in lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    users.users.${user} = lib.mkDefault {  # We be overriden by firefly-iii config if needed
      isSystemUser = true;
      group = "firefly-iii";
    };
    users.groups.${user} = lib.mkDefault {};

    systemd.services.firefly-iii-data-importer = {
      description = "Firefly-iii Data importer service";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        STORAGE_PATH = "/var/lib/firefly-iii-data-importer";
      } // (builtins.mapAttrs (_: val: toString val) cfg.settings);

      serviceConfig.StateDirectory = "firefly-iii-data-importer";
      serviceConfig.User = user;
      script = ''
        cp -r ${pkg}/storage/* $STORAGE_PATH/
        chmod -R 770 $STORAGE_PATH/
        ${lib.getExe pkgs.php83} -S ${cfg.listenAddress}:${builtins.toString cfg.port} -t ${pkg}/public
      '';
    };
  };
}

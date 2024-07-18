{ config, lib, pkgs, ... }:
let
  cfg = config.services.firefly-iii;
in {
  imports = [ ../system/backup.nix ];

  options.services.firefly-iii = {
    secrets = pkgs.secrets.mkSecretOption "Secrets for Firefly-iii";
    backup = lib.mkEnableOption {
      description = "Enable the backup service for Firefly-iii";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port on which to serve the service";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ config.services.firefly-iii.port ];

    secrets.setup.firefly-iii = {
      user = cfg.user;
      secret = cfg.secrets;
    };

    systemd.services.firefly-iii-serve = {
      description = "Firefly iii accounting tool";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      script = ''
        ${lib.getExe pkgs.php83} -S ${builtins.toString cfg.port} -t ${cfg.package}
      '';
    };

    services.firefly-iii = {
      settings.DB_PASSWORD_FILE = cfg.secrets.db_password.file;
      settings.APP_KEY_FILE = cfg.secrets.app_key.file;
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      firefly-iii = {
        inherit (cfg) user secrets;
        paths = [ cfg.dataDir ];
      };
    };
  };
}

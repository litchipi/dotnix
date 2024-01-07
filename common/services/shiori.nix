{ config, lib, pkgs, ... }:
let
  cfg = config.services.shiori;
in
  {
    options.services.shiori = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Shiori";
      backup = lib.mkEnableOption { 
        description = "Enable the backup service for shiori";
      };
    };

    config = {
      backup.services.shiori = if cfg.backup then {
        user = "root";
        paths = [ config.systemd.services.shiori.environment.SHIORI_DIR ];
        secrets = cfg.secrets;
      } else {};
    };
  }

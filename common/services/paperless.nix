{ config, lib, pkgs, ... }:
let
  cfg = config.services.paperless;
in
  {
    imports = [ ../system/backup.nix ];
    options.services.paperless = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Paperless";
      backup = lib.mkEnableOption {
        description = "Enable the backup service for paperless";
      };
    };

    config = {
      secrets.setup.paperless = {
        user = config.services.paperless.user;
        secret = cfg.secrets;
      };

      services.paperless = {
        enable = true;
        passwordFile = cfg.secrets.admin_pwd.file;
      };

      backup.services.paperless = if cfg.backup then {
        user = cfg.user;
        paths = [ cfg.dataDir ];
        secrets = cfg.secrets;
      } else {};
    };
  }

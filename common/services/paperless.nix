{ config, lib, pkgs, ... }:
let
  cfg = config.services.paperless;
in {
  imports = [ ../system/backup.nix ];

  options.services.paperless = {
    secrets = pkgs.secrets.mkSecretOption "Secrets for Paperless";
    backup = lib.mkEnableOption {
      description = "Enable the backup service for paperless";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      config.services.paperless.port
    ];

    secrets.setup.paperless = {
      user = cfg.user;
      secret = cfg.secrets;
    };

    services.paperless = {
      address = "0.0.0.0";
      passwordFile = cfg.secrets.admin_pwd.file;
      settings.PAPERLESS_OCR_LANGUAGE = "fra+eng";
      settings.PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
        optimize = 1;
        pdfa_image_compression = "lossless";
        invalidate_digital_signatures = true;
      };
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      paperless = {
        inherit (cfg) user secrets;
        paths = [ cfg.dataDir ];
      };
    };
  };
}

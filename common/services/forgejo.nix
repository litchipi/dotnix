{ config, lib, pkgs, ... }:
let
  cfg = config.services.forgejo;
in
  {
    imports = [ ../system/backup.nix ];

    options.services.forgejo = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for forgejo";
      backup = lib.mkEnableOption { 
        description = "Enable the backup service for forgejo";
      };
      localCiRunner = lib.mkOption {
        description = "Allow to host a CI runner on the same host";
        default = true;
        type = lib.types.bool;
      };
    };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      config.services.forgejo.settings.server.HTTP_PORT
    ];

    services.forgejo = {
      lfs.enable = lib.mkDefault true;
      dump = lib.mkDefault {
        enable = true;
        type = "tar";
        interval = "04:31";
      };
      mailerPasswordFile = cfg.secrets.mailer_pwd.file;
      database.passwordFile = cfg.secrets.db_pwd.file;
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      forgejo = {
        inherit (cfg) user secrets;
        paths = [ cfg.dump.backupDir ];
      };
    };

    services.gitea-actions-runner.instances = lib.attrsets.optionalAttrs cfg.localCiRunner {
    };
  };
}

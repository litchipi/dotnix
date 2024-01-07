{ config, lib, pkgs, ... }:
let
  cfg = config.services.shiori;
in
  {
    imports = [ ../system/backup.nix ];

    options.services.shiori = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Shiori";
      backup = lib.mkEnableOption { 
        description = "Enable the backup service for shiori";
      };
    };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      config.services.shiori.port
    ];

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      shiori = {
        user = "root";
        inherit (cfg) secrets;
        # Defined in https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/web-apps/shiori.nix#L47C32-L47C49
        paths = [ "/var/lib/shiori" ];
      };
    };
  };
}

{ config, lib, pkgs, inputs, ...}: let

  cfg = config.services.ifm;

in {
  imports = [
    ../system/backup.nix
    (inputs.nixpkgs_unstable + "/nixos/modules/services/web-apps/ifm.nix")
  ];

  options.services.ifm = {
    backup = lib.mkEnableOption {
      description = "Enable the backup service for IFM";
    };
    secrets = pkgs.secrets.mkSecretOption "Secrets for IFM";
  };

  config = lib.mkIf cfg.enable {
    services.ifm.listenAddress = "0.0.0.0";

    networking.firewall.allowedTCPPorts = [ cfg.port ];
    users.users.ifm = {
      group = "ifm";
      isSystemUser = true;
    };
    users.groups.ifm = {};

    systemd.services.ifm.wants = ["network-online.target"];

    secrets.setup.ifm = {
      user = "ifm";
      secret = cfg.secrets;
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      ifm = {
        user = "ifm";
        inherit (cfg) secrets;
        paths = [ cfg.dataDir ];
      };
    };
  };
}

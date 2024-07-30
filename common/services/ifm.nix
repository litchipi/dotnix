{ config, lib, pkgs, inputs, ...}: let
  cfg = config.services.ifm;
in {
  imports = [
    ../system/backup.nix
    (inputs.nixpkgs_unstable + "/nixos/modules/services/web-apps/ifm.nix")
  ];
  config = lib.mkIf cfg.enable {
    services.ifm.listenAddress = "0.0.0.0";
    networking.firewall.allowedTCPPorts = [ cfg.port ];
    systemd.services.ifm.wants = ["network-online.target"];
  };
}

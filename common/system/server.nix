{ config, lib, pkgs, ... }: let
  cfg = config.server;
in {
  imports = [ ../software/shell/tui.nix ];
  options.server.full = lib.mkEnableOption {
    description = "Enable the full server mode";
    default = true;
  };
  config = {
    base.networking.vm_forward_ports = {
      ssh = { from = "host"; host.port = 40022; guest.port = 22;};
    };

    environment.systemPackages = with pkgs; if cfg.full then [
      certbot
      mtr
      nettools
    ] else [];

    services.fail2ban = {
      enable = cfg.full;
      maxretry = 5;
      bantime-increment = {
        enable = true;
        factor = "4";
      };
    };
  };
}

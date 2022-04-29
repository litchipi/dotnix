{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "server";
    add_pkgs = with pkgs; [
      certbot
      mtr
      nettools
    ];
    cfg = {
      base.networking.ssh = true;

      base.networking.vm_forward_ports = {
        ssh = { from = "host"; host.port = 40022; guest.port = 22;};
      };

      networking.wireless.enable = false;

      cmn.software.tui.minimal.enable = true;
      cmn.software.tui.neovim.enable = true;
      cmn.software.tui.tmux.enable = true;
      cmn.shell.aliases = {
        filesystem.enable = true;
        network.enable = true;
        nix.enable = true;
      };

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime-increment = {
          enable = true;
          factor = "4";
        };
      };

      networking.stevenBlackHosts.enable = false;
      networking.extraHosts = ''
        127.0.0.1 ${config.base.networking.domain}
      '';
    };
  }
]

{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    # Minimal server config
    name = "server";
    minimal.cli = true;
    cfg = {
      base.networking.ssh = true;
      base.networking.vm_forward_ports = {
        ssh = { from = "host"; host.port = 40022; guest.port = 22;};
      };

      cmn.software.tui = {
        enable = true;
        full.enable = false;
      };

      networking.extraHosts = ''
        127.0.0.1 ${config.base.networking.domain}
      '';
    };
  }

  {
    name = "full";
    default_enabled = config.cmn.server.enable;
    parents = ["server"];
    add_pkgs = with pkgs; [
      certbot
      mtr
      nettools
    ];
    cfg = {
      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime-increment = {
          enable = true;
          factor = "4";
        };
      };
    };
  }
]

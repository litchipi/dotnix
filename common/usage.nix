{ config, lib, pkgs, ... }:
let
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
in
  build_lib.create_common_confs "usage" [
 
  # Basic usage
  {
    name = "basic";
    cfg = {
      services.printing.enable = true;
      commonconf.software.basic.enable = true;
    };
  }

  # Server 
  {
    name = "server";
    cfg = {
      commonconf.software.tui_tools.enable = true;
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
        permitRootLogin = "no";
        kbdInteractiveAuthentication = false;
      };
    };
  }
]

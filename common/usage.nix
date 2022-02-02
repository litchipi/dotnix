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
    };
  }

  # Server 
  {
    name = "server";
    cfg = {
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
        permitRootLogin = "no";
        kbdInteractiveAuthentication = false;
      };
    };
  }
]
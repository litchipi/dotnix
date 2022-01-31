{ config, lib, pkgs, ... }:
let
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
in
  build_lib.create_common_conf {
    name = "server";
  } {
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
        permitRootLogin = "no";
        kbdInteractiveAuthentication = false;
      };
  }

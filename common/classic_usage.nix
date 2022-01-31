{ config, lib, pkgs, ... }:
let
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
in
 build_lib.create_common_conf {
    name = "classic_usage";
  } {
    services.printing.enable = true;
  }

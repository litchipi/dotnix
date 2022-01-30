{ config, lib, pkgs, ... }:
let 
  build_lib = import ../lib/build.nix {config=config; lib=lib; pkgs=pkgs;};
in
  build_lib.create_common_conf {
    name = "infosec";
  } {
  }

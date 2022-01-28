{ config, lib, pkgs, ... }:
let
  build_lib = import ../lib/build.nix {config=config; lib=lib; pkgs=pkgs;};
  bootstrap = build_lib.bootstrap_machine 
    "nixostest" "nx"                # Hostname, username
    ["server" "gnome" "infosec"]    # Common configuration
    ["john"]                        # Authorized SSH keys
  ;
in
{
  users.mutableUsers = false;
} // bootstrap

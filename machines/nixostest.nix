{ config, lib, pkgs, ... }:
let
  # Library containing wrappers for machine definition
  build_lib = import ../lib/build.nix {config=config; lib=lib; pkgs=pkgs;};

  # Creating the base configuration for user, hostName and authentication method
  bootstrap = build_lib.bootstrap_machine {
    hostname = "nixostest";
    user = "nx";
    ssh_auth_keys = ["john"];
    base_hosts = false;
  };
in
  {
  # Common configuration to use
  commonconf.server.enable = true;
  commonconf.gnome.enable = true;
  commonconf.infosec.enable = true;

  # Custom configuration for this machine
  users.mutableUsers = false;
} // bootstrap

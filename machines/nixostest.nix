{ config, lib, pkgs, ... }:
let
  # Library containing wrappers for machine definition
  build_lib = import ../lib/build.nix {config=config; lib=lib; pkgs=pkgs;};

  # Creating the base configuration for the machine and user.
  # Look at the `lib/build.nix` file to see all the optionnal arguments
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
  commonconf.music_production.enable = true;
  commonconf.music_production.electro.enable = true;
  commonconf.music_production.guitar.enable = false;

  # Custom configuration for this machine
  users.mutableUsers = false;
} // bootstrap

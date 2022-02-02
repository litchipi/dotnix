{ config, lib, pkgs, ... }:
let
  # Library containing wrappers for machine definition
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};

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
  commonconf.usage.basic.enable = true;
  commonconf.usage.server.enable = true;

  commonconf.software.infosec.enable = true;
  commonconf.software.music_production.enable = true;
  commonconf.software.music_production.electro.enable = true;

  commonconf.wm.gnome.enable = true;

  # Custom configuration for this machine
  users.mutableUsers = false;
} // bootstrap

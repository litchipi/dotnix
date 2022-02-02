{ config, lib, pkgs, ... }:
let
  # Library containing wrappers for machine definition
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
in

# Arguments:
#   hostname:       The system hostname
#   user:           The main user of the system
#   ssh_auth_keys:  The authorized SSH public keys (can be empty)
#   base_hosts:     Add the pre-defined hostnames in /etc/hosts ? (default true)
#   add_hosts:      Additionnal hosts to add to /etc/hosts ? (default "")
#   add_pkgs:       Additionnal packages to add to the list ? (default [])
#
# If a password is defined for this user in data/secrets/passwords.toml, will use it
# If none, you must provide at least one ssh_auth_keys.

build_lib.build_machine {
    hostname = "nixostest";
    user = "nx";
    ssh_auth_keys = ["john"];
    base_hosts = false;
} {
  # Common configuration to use
  commonconf.usage.basic.enable = true;
  commonconf.usage.server.enable = true;

  commonconf.software.infosec.enable = true;
  commonconf.software.music_production.enable = true;
  commonconf.software.music_production.electro.enable = true;

  commonconf.wm.gnome.enable = true;

  # Custom configuration for this machine
  users.mutableUsers = false;
}

{ config, lib, pkgs, ... }:
{
  # The name of the main user of the system
  base.user = "nx";
  # The system hostname
  base.hostname = "nixostest";
  # What SSH key to allow for remote login
  #   (has to be a file in data/ssh/pubkeys/<name>.pub)
  base.ssh_auth_keys = ["john"];
  # Set up pre-defined base of custom host for IPs ?
  base.base_hosts = false;

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

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
  commonconf.basic.enable = true;
  commonconf.server.enable = true;

  commonconf.infosec.enable = true;
  commonconf.software.musicprod.enable = true;
  commonconf.software.musicprod.electro.enable = true;

  commonconf.gnome.enable = true;

  # Custom configuration for this system
  users.mutableUsers = false;

  # Additionnal packages to install
  environment.systemPackages = with pkgs; [
    cowsay #litchipi.pomodoro
  ];
}

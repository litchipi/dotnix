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
  # Load the wifi password for the SSID "nixostest"
  base.networking.connect_wifi = [ "nixostest" ];

  # The desktop software to use
  commonconf.wm.custom.hackerline.enable = true;

  # Common configuration to use
  commonconf.basic.enable = true;
  commonconf.server.enable = true;
  commonconf.server.headless = false;
  commonconf.infosec.enable = true;

  # Some software sets to use
  commonconf.software.musicprod.enable = true;
  commonconf.software.musicprod.electro.enable = true;

  # Custom configuration for this system
  users.mutableUsers = false;

  # Custom configuration for the user "nx" of the system
  base.user_cfg = {
    home.keyboard.layout = "fr";
  };

  # Additionnal packages to install
  environment.systemPackages = with pkgs; [
    cowsay
  ];
}

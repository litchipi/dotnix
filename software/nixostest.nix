{ config, lib, pkgs, ... }:
{
  # The name of the main user of the system
  base.user = "nx";

  # What SSH key to allow for remote login
  #   (has to be a file in data/ssh/pubkeys/<name>.pub)
  base.networking.ssh_auth_keys = ["john" "tim"];

  # Load the wifi password for the SSID "nixostest"
  base.networking.connect_wifi = [ "nixostest" ];

  installscript.nixos_config_branch = "dev";

  # The desktop software to use
  cmn.wm.gnome.enable = true;
  cmn.wm.bck-img = "we-must-conquer-mars.jpg";

  # Common configuration to use
  cmn.basic.enable = true;
  cmn.server.enable = true;

  cmn.software.infosec.enable = true;
  cmn.software.infosec.internet = true;

  # Some software sets to use
  cmn.software.musicprod.enable = true;
  cmn.software.musicprod.electro.enable = true;

  cmn.remote.gogs.enable = true;
  cmn.remote.gogs.ipaddr = "185.167.99.178";

  cmn.software.dev.enable = true;
  cmn.software.dev.all = true;

  # Custom configuration for the user "nx" of the system
  base.home_cfg = {
    home.keyboard.layout = "fr";
  };

  # Additionnal packages to install
  base.add_pkgs = with pkgs; [
    cowsay
  ];

  base.disks.add_swapfile = 5000;
}

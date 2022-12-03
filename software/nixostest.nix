{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix { inherit config lib pkgs; };
in {
  # The name of the main user of the system
  base.user = "nx";
  base.hostname = "nixostest";

  # What SSH key to allow for remote login
  #   (has to be a file in data/ssh/pubkeys/<name>.pub)
  base.networking.ssh_auth_keys = ["john@sparta" "tim@diamond"];

  # Load the wifi password for the SSID "nixostest"
  base.networking.connect_wifi = [ "nixostest" ];

  installscript.nixos_config_branch = "dev";

  # The desktop software to use
  cmn.wm.gnome.enable = true;
  cmn.wm.bck-img = libdata.get_wallpaper "we-must-conquer-mars.jpg";

  # Common configuration to use
  cmn.basic.enable = true;
  cmn.server.enable = true;

  cmn.software.infosec.enable = true;
  cmn.software.infosec.internet = true;

  # Some software sets to use
  cmn.software.musicprod.enable = true;
  cmn.software.musicprod.electro.enable = true;

  cmn.software.dev.basic = true;

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

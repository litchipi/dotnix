{ config, lib, pkgs, ... }:
{
  # The name of the main user of the system
  base.user = "nx";

  # The system hostname
  base.hostname = "nixostest";

  # What SSH key to allow for remote login
  #   (has to be a file in data/ssh/pubkeys/<name>.pub)
  base.ssh_auth_keys = ["john"];

  # Load the wifi password for the SSID "nixostest"
  base.networking.connect_wifi = [ "nixostest" ];

  # Additionnal packages to install
  base.add_pkgs = with pkgs; [
    cowsay
  ];

  # Configure the disk setup
  base.disks.disk_uuid = "Virtualbox";
  base.disks.swapsize = 4;
  base.disks.add_partition = [
    { label = "part0"; size.Gib = 4; fstype = "ntfs"; }
    { label = "part1"; size.Mib = 500; fstype = "ext4"; }
  ];

  # The desktop software to use
  commonconf.wm.gnome.enable = true;
  commonconf.wm.bck-img = "we-must-conquer-mars.jpg";

  # Common configuration to use
  commonconf.basic.enable = true;
  commonconf.server.enable = true;
  commonconf.server.headless = false;
  commonconf.infosec.enable = true;

  # Some software sets to use
  commonconf.software.musicprod.enable = true;
  commonconf.software.musicprod.electro.enable = true;

  # Custom configuration for the user "nx" of the system
  base.user_cfg = {
    home.keyboard.layout = "fr";
  };
}

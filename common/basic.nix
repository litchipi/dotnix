{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "basic";
    cfg = {
      commonconf.software.basic.enable = true;
      commonconf.software.multimedia.enable = true;
      commonconf.software.systools.enable = true;
      services.printing.enable = true;
    };
  }

  {
    name = "basic";
    parents = [ "software" ];
    add_pkgs = with pkgs; [
      evince                      # PDF viewer
      gnome.nautilus              # File manager
      gnome.eog                   # Image viewer
      gnome.gedit                 # Notepad
      alacritty                   # Terminal
      firefox                     # Internet browser
      deluge                      # Torrent client
    ];
  }

  {
    name = "multimedia";
    parents = [ "software" ];
    add_pkgs = with pkgs; [
      vlc                         # Video player
    ];
  }

  {
    name = "systools";
    parents = [ "software" ];
    add_pkgs = with pkgs; [
      gnome.gnome-disk-utility    # Manage disks
      gnome-usage                 # Ressources monitor
      baobab                      # Disk space monitor
    ];
  }
]

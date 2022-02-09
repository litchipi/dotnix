{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "software";
    default_enabled = true;
    add_opts = {
      default_terminal_app = lib.mkOption {
        type = with lib.types; package;
        default = pkgs.alacritty;
        description = "Terminal application to use";
      };

      # TODO assert that the name of the default_terminal_app is contained in the command
      terminal_cmd = lib.mkOption {
        type = with lib.types; str;
        default = "alacritty -e";
        description = "Command used to spawn a terminal running an application";
      };
    };
    add_pkgs = [ config.commonconf.software.default_terminal_app ];
  }

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

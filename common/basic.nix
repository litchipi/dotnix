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

      terminal_cmd = lib.mkOption {
        type = with lib.types; str;
        default = "alacritty -e";
        description = "Command used to spawn a terminal running an application";
      };
    };
    assertions = let 
      cfg = config.cmn.software;
    in
    [
      {
        assertion = lib.strings.hasInfix (lib.strings.getName cfg.default_terminal_app) cfg.terminal_cmd;
        message = "Terminal execution command does not contain the name of the default terminal application";
      }
    ];
    add_pkgs = [ config.cmn.software.default_terminal_app ];
  }

  {
    name = "basic";
    cfg = {
      cmn.software.basic.enable = true;
      cmn.software.multimedia.enable = true;
      cmn.software.systools.enable = true;
      services.printing.enable = true;
      # TODO    Set up default applications for each type of file
    };
  }

  {
    name = "basic";
    parents = [ "software" ];
    add_pkgs = with pkgs; [
      libreoffice                 # Office suite
      evince                      # PDF viewer
      gnome.nautilus              # File manager
      gnome.eog                   # Image viewer
      # TODO    Set up gedit theme
      gnome.gedit                 # Notepad
      # TODO  Set up alacritty theme
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
      rhythmbox                   # Music player
      drawing                     # Paint replacement tool
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

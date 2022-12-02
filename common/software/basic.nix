{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libcolors = import ../../lib/colors.nix {inherit config lib pkgs;};
in
libconf.create_common_confs [
  {
    name = "software";
    default_enabled = true;
    minimal.cli = true;
    add_pkgs = [
      config.cmn.software.default_terminal_app
    ];
    add_opts = {
      # Not supposed to be changed other by editing this config
      default_terminal_app = lib.mkOption {
        type = lib.types.package;
        description = "Application to use for terminal emulation";
        default = pkgs.alacritty;
      };
      terminal_cmd = lib.mkOption {
        type = lib.types.str;
        description = "Terminal command to execute a program";
        default = "alacritty -e";
      };
    };
    home_cfg = {
      programs.alacritty = {
        enable = config.cmn.software.default_terminal_app.pname == "alacritty";
        settings = {
          env.TERM = "xterm-256color";
          window = {
            decorations = "none";
            opacity = 0.85;
            padding = {
              x = 15;
              y = 15;
            };
          };
          scrolling = {
            history = 10000;
            multiplier = 3;
          };
          mouse.hide_when_typing = false;
          font.normal = {
            family = "Fira Code";
            style = "Regular";
          };
          font.bold = {
            family = "Fira Code";
            style = "Bold";
          };
          font.italic = {
            family = "Fira Code";
            style = "Italic";
          };
          cursor.unfocused_hollow = true;
          colors = {
            primary = {
              background = "0x000000";
              foreground = "0xffffff";
            };
            dim.black  = "0x333333";
          };
        };
      };
    };
  }
  {
    name = "basic";
    minimal.gui = true;
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
    minimal.gui = true;
    add_pkgs = with pkgs; [
      libreoffice                 # Office suite
      evince                      # PDF viewer
      gnome.nautilus              # File manager
      gnome.eog                   # Image viewer
      gnome-text-editor           # Notepad
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

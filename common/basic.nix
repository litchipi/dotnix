{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
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
      home.file.".alacritty.yml".source = libdata.get_data_path ["config" "alacritty.yml"];
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

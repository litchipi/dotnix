{ config, lib, pkgs, ... }@args:
let
  cfg = config.software;
  libsoft = import ../../lib/software/package_set.nix args;

  all_packages_sets = with pkgs; {
    basic = [
      libreoffice                 # Office suite
      evince                      # PDF viewer
      gnome.nautilus              # File manager
      gnome.eog                   # Image viewer
      gnome-text-editor           # Notepad
      firefox                     # Internet browser
      deluge                      # Torrent client
    ];

    multimedia = [
      vlc                         # Video player
      rhythmbox                   # Music player
      drawing                     # Paint replacement tool
    ];

    systools = [
      gnome.gnome-disk-utility    # Manage disks
      gnome-usage                 # Ressources monitor
      baobab                      # Disk space monitor
    ];
  };
in
  {
    imports = [
      ./alacritty.nix
    ];
    options.software = {
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
      package_sets = libsoft.mkPackageSetsOptions all_packages_sets;
    };
    config = {
      environment.systemPackages = [
        cfg.default_terminal_app
      ] ++ (libsoft.mkPackageSetsConfig cfg.package_sets all_packages_sets);
    };
  }

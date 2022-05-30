{ config, lib, pkgs, home-manager, ... }:
let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  utils_lib = import ../../lib/utils.nix {inherit config lib pkgs;};
  cfg = config.cmn.wm;

  theme_type = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name to use when enabling the theme";
      };
      package = lib.mkOption {
        type = lib.types.package;
        description = "Package to use to install the theme on the system";
      };
    };
  };
in
conf_lib.create_common_confs [
  {
    name = "wm";
    add_opts = {
      bck-img = lib.mkOption {
        type = lib.types.str;
        description = "The background image to set";
      };
      iconTheme = lib.mkOption {
        type = lib.types.nullOr theme_type;
        default = null;
        description = "Icon theme to use";
      };
      gtkTheme = lib.mkOption {
        type = lib.types.nullOr theme_type;
        default = null;
        description = "The GTK theme to set";
      };
      cursorTheme = lib.mkOption {
        type = lib.types.nullOr theme_type;
        default = null;
        description = "The cursor theme to set";
      };
      font = lib.mkOption {
        type = lib.types.nullOr theme_type;
        default = null;
        description = "The Font to use";
      };
      add_dconf = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Additionnal dconf configuration";
      };
      autologin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Wether to enable autologin into the session";
      };
    };
    add_pkgs = with pkgs; [
    ] ++ (if builtins.isNull cfg.cursorTheme then [] else [ cfg.cursorTheme.package ]);
    cfg = {
      services.xserver.enable = true;
      programs.xwayland.enable = true;
      programs.dconf.enable = true;
      cmn.dconf.apps.enable = true;
      cmn.software.infosec = lib.mkIf config.cmn.software.infosec.enable { gui.enable = true; };
      services.xserver.displayManager.autoLogin = {
        enable = true;
        user = config.base.user;
      };
      services.xserver.desktopManager.wallpaper.mode = lib.mkIf config.services.xserver.enable "fill";
    };

    home_cfg = {
      gtk = {
        enable = true;
      }
      // (if builtins.isNull cfg.gtkTheme then {} else { theme = cfg.gtkTheme; })
      // (if builtins.isNull cfg.iconTheme then {} else { iconTheme = cfg.iconTheme; })
      // (if builtins.isNull cfg.font then {} else { font = cfg.font; });

      dconf.settings = cfg.add_dconf
      // (if builtins.isNull cfg.cursorTheme then {} else {
        "org/gnome/desktop/interface".cursor-theme = cfg.cursorTheme.name;
      });
    };
  }
]

# Other themes
  # Icons
    # paper-gtk-theme

  # Gtk
    # matcha-gtk-theme

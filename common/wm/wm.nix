{ config, lib, pkgs, ... }:
let
  cfg = config.wm;

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
  {
    imports = [
      ../dconf/apps.nix
    ];

    options.wm = {
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
    config = {
      environment.systemPackages = with pkgs; [
        glxinfo
        wl-clipboard
      ] ++ (if builtins.isNull cfg.cursorTheme then [] else [ cfg.cursorTheme.package ]);
      xdg.portal.enable = true;

      programs.dconf.enable = true;

      services.libinput.enable = true;
      services.displayManager.autoLogin = {
        enable = cfg.autologin;
        user = config.base.user;
      };

      services.xserver = {
        enable = true;
        xkb = {
          variant = "";
          options = "eurosign:e";
          layout = "fr";
        };
        desktopManager.wallpaper.mode = lib.mkIf config.services.xserver.enable "fill";
      };

      # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
      systemd.services."getty@tty1".enable = false;
      systemd.services."autovt@tty1".enable = false;

      home-manager.users.${config.base.user} = {
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
    };
  }

# Other themes
  # Icons
    # paper-gtk-theme

  # Gtk
    # matcha-gtk-theme

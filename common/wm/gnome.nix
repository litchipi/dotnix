{ config, lib, pkgs, pkgs_unstable, ... }:
let
  libgnome = import ../../lib/software/gnome.nix { inherit config lib pkgs; };

  cfg = config.wm.gnome;
  gnome_theme_type = lib.types.submodule {
    options = {
      dark = lib.mkOption {
        type = lib.types.bool;
        description = "Wether to enable dark mode with this theme";
      };
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
      ./wm.nix
      ./plymouth.nix
      ../dconf/gnome.nix
    ];

    options.wm.gnome = {
      add_extensions = lib.mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        description = "Extensions to add to the gnome shell";
      };
      # user_icon = lib.mkOption {
      #   type = with lib.types; nullOr path;
      #   default = null;
      #   description = "Icon to use for the user";
      # };
      theme = lib.mkOption {
        type = lib.types.nullOr gnome_theme_type;
        description = "Gnome Shell theme to set";
        default = null;
      };
      mutter_dynamic_buffering = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Wether to add the dynamic buffering patch";
      };
    };

    config = {
      environment.systemPackages = (with pkgs_unstable.gnomeExtensions; libgnome.adaptGnomeExtensions "44" [
        caffeine
        runcat
        tray-icons-reloaded
        bluetooth-quick-connect
        dash-to-dock
      ]) ++ (cfg.add_extensions) ++ (with pkgs; [
        gnome.gnome-tweaks
      ]) ++ (if builtins.isNull cfg.theme then [] else [ cfg.theme.package ]);

      environment.shellAliases = {
      };

      services.xserver = {
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };

      security.pam.services.login.enableGnomeKeyring = true;

      programs.dconf.enable = true;
      # TODO  FIXME
      # nixpkgs.config.firefox.enableGnomeExtensions = true;
      services.gnome = {
        core-os-services.enable = true;
        core-shell.enable = true;
        gnome-browser-connector.enable = true;   # TODO  FIXME   Controller not found in firefox ?
        gnome-keyring.enable = true;
        gnome-online-accounts.enable = true;
        gnome-settings-daemon.enable = true;
        gnome-user-share.enable = true;
        sushi.enable = true;
      };

      environment.gnome.excludePackages = with pkgs.gnome; [
        gnome-software
        gnome-music
        epiphany
        geary
      ];

      # system.activationScripts.setup_gnome_user_icon = if builtins.isNull cfg.user_icon then "" else let
      #   gdm_user_conf = ''
      #     [User]
      #     Session=
      #     XSession=
      #     Icon=${cfg.user_icon}
      #     SystemAccount=false
      #   '';
      # in ''
      #   mkdir -p /var/lib/AccountsService/users/
      #   echo '${gdm_user_conf}' > /var/lib/AccountsService/users/${config.base.user}
      # '';

      base.home_cfg = {
        gtk = if builtins.isNull cfg.theme then {} else {
          gtk3.extraConfig.gtk-application-prefer-dark-theme = cfg.theme.dark;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = cfg.theme.dark;
        };
        dconf.settings = if builtins.isNull cfg.theme then {} else {
          "org/gnome/shell/extensions/user-theme" = {
            name = cfg.theme.name;
          };
        };
      };
    };
  }

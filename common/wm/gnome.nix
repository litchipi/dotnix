{ config, lib, pkgs, ... }:
let
  utils_lib = import ../../lib/utils.nix {inherit config lib pkgs;};
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.wm.gnome;
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
conf_lib.create_common_confs [
  {
    name = "gnome";
    minimal.gui = true;
    parents = ["wm"];

    add_opts = {
      add_extensions = lib.mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        description = "Extensions to add to the gnome shell";
      };
      user_icon = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "Icon to use for the user";
      };
      theme = lib.mkOption {
        type = lib.types.nullOr gnome_theme_type;
        description = "Gnome Shell theme to set";
        default = null;
      };
    };

    cfg = {
      cmn.wm.enable = true;
      cmn.wm.boot.enable = true;
      programs.dconf.enable = true;
      cmn.dconf.gnome.enable = true;
      cmn.dconf.gnome_keyboard_shortcuts.enable = true;

      services.xserver = {
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };

      security.pam.services.login.enableGnomeKeyring = true;

      nixpkgs.config.firefox.enableGnomeExtensions = true;

      services.gnome = {
        core-os-services.enable = true;
        core-shell.enable = true;
        chrome-gnome-shell.enable = true;
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

      # TODO  FIXME User icon not set for gnome session
      boot.postBootCommands = if builtins.isNull cfg.user_icon then "" else let
        gdm_user_conf = ''
          [User]
          Session=
          XSession=
          Icon=${cfg.user_icon}
          SystemAccount=false
        '';
      in ''
        mkdir -p /var/lib/AccountsService/users/
        echo '${gdm_user_conf}' > /var/lib/AccountsService/users/${config.base.user}
      '';
    };

    home_cfg = {
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

    add_pkgs = (with pkgs.gnomeExtensions; [
      caffeine
      bluetooth-quick-connect
      bring-out-submenu-of-power-offlogout-button
      disconnect-wifi
      hide-activities-button
      # night-light-slider  # Hopefully will be compatible one day
      runcat
      tray-icons-reloaded
      static-background-in-overview
      dash-to-dock
    ] ++ cfg.add_extensions) ++ (with pkgs; [
      gnome.gnome-tweaks
    ]) ++ (if builtins.isNull cfg.theme then [] else [ cfg.theme.package ]);
  }
]

{ config, lib, pkgs, home-manager, ... }:
let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  utils_lib = import ../../lib/utils.nix {inherit config lib pkgs;};
  cfg = config.commonconf.wm;
in
conf_lib.create_common_confs [
  {
    name = "wm";
    default_enabled = true;
    add_opts = {
      bck-img = lib.mkOption {
        type = with lib.types; str;
        description = "The background image to set";
      };
      iconTheme = lib.mkOption {
        type = with lib.types; anything;
        default = pkgs.papirus-icon-theme;
        description = "Icon theme to use";
      };
      gtkTheme = lib.mkOption {
        type = with lib.types; anything;
        default = pkgs.layan-gtk-theme;
        description = "The GTK theme to set";
      };
      add_dconf = lib.mkOption {
        type = with lib.types; anything;
        default = {};
        description = "Additionnal dconf configuration";
      };
    };

    cfg = {
      services.xserver.enable = true;
      commonconf.dconf.apps.enable = true;
    };

    home_cfg = {
      gtk = {
        enable = true;
        theme = {
          name = "GtkTheme";
          package = cfg.gtkTheme;
        };
        iconTheme = {
          name = "IconTheme";
          package = cfg.iconTheme;
        };
      };

      dconf.settings = cfg.add_dconf;
    };
  }
]

# Other themes
  # Icons
    # paper-gtk-theme

  # Gtk
    # matcha-gtk-theme

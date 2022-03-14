{ config, lib, pkgs, ... }:
let
  utils_lib = import ../../lib/utils.nix {inherit config lib pkgs;};
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.cmn.wm.gnome;
  gsettings_path = [ "wm" "gsettings" ];
  basic_gsettings = ''
  '';
in
conf_lib.create_common_confs [
  {
    name = "gnome";
    parents = ["wm"];

    add_opts = {
      add_extensions = lib.mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        description = "Extensions to add to the gnome shell";
      };
      default_terminal_app = lib.mkOption {
        type = with lib.types; package;
        default = pkgs.alacritty;
        description = "Terminal to use by default";
      };
    };

    cfg = {
      cmn.wm.enable = true;
      cmn.dconf.gnome.enable = true;
      cmn.dconf.gnome_keyboard_shortcuts.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    };

    add_pkgs = with pkgs.gnomeExtensions; [
      caffeine
      dash-to-dock
      bluetooth-quick-connect
      bring-out-submenu-of-power-offlogout-button
      disconnect-wifi
      freon
      gnome-40-ui-improvements
      hide-activities-button
      night-light-slider
      runcat
      tray-icons-reloaded
      unite
      cfg.default_terminal_app
    ] ++ cfg.add_extensions;
  }
]

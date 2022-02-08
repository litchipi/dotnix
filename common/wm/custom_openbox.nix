{ config, lib, pkgs, ... }:
let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  openbox_base_cfg = {
    cfg = {
        services.xserver.enable = true;
        services.xserver.windowManager.openbox.enable = true;
      };
    home_cfg = user: hconfig: {

    };
  };
in
conf_lib.create_common_confs [
  {
    name = "hackerline";
    cfg = openbox_base_cfg.cfg;
    home_cfg = user: hconfig: {
      home.file = data_lib.copy_dirs_to_home [
        { home_path_dir = ".config"; asset_path_dir = [ "wm" "custom" "hackerline" ];}
        { home_path_dir = ".fonts"; asset_path_dir = [ "fonts" ];}
        { home_path_dir = ".themes"; asset_path_dir = [ "wm" "openbox" "themes" ];}
      ];
    } // (openbox_base_cfg.home_cfg user hconfig);
    parents = [ "wm" "custom"];
    add_pkgs = with pkgs; [
      conky
      dunst
      picom
      polybar
      rofi
      tint2
      feh
    ];
  }
]

{ config, lib, pkgs, ... }:
let
  utils_lib = import ../../lib/utils.nix {inherit config lib pkgs;};
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "gnome";
    cfg = {
      commonconf.dconf.gnome.enable = true;
      commonconf.dconf.gnome_keyboard_shortcuts.enable = true;
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    };
  }
]

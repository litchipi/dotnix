{ config, lib, pkgs, ... }:
let 
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "gnome";
    cfg = {
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    };
  }
]

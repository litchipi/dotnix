{ config, lib, pkgs, ... }:
let 
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
in
  build_lib.create_common_confs [

  # Gnome
  {
    name = "gnome";
    cfg = {
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    };
  }
]

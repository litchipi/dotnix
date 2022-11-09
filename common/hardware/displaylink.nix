{ config, lib, pkgs, ... }:
let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "displaylink";
    parents = ["hardware"];
    cfg = {
      services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
    };
  }
]

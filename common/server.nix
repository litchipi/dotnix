{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "server";
    cfg = {
      cmn.software.tui.enable = true;
      base.networking.ssh = true;
    };
  }
]

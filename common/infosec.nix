{ config, lib, pkgs, ... }:
let 
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "infosec";
    cfg = {
      commonconf.software.basic.enable = true;
      commonconf.software.tui_tools.enable = true;
    };
  }
]

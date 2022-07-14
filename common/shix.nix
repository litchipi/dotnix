{ config, lib, pkgs, extra, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  cfg = config.cmn.nix;
in
conf_lib.create_common_confs [
  {
    name = "shix";
    parents = ["nix"];
    add_opts = {
    };
    cfg = {
    };
  }
]

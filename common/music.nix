{ config, lib, pkgs, ... }:
let 
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "musicprod";
    cfg = {
      commonconf.shell.aliases.music.enable = true;
    };
    add_pkgs = with pkgs; [
      youtube-dl
      audacity
    ];
    parents = [ "software" ];
  }

  {
    name = "electro";
    add_pkgs = with pkgs; [
      lmms
      mixxx
    ];
    parents = [ "software" "musicprod" ];
  }

  {
    name = "guitar";
    add_pkgs = with pkgs; [
      guitarix
      gxplugins-lv2
    ];
    parents = [ "software" "musicprod" ];
  }

  {
    name = "score";
    add_pkgs = with pkgs; [
      musescore
    ];
    parents = [ "software" "musicprod" ];
  }
]

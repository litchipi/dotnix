{ config, lib, pkgs, ... }:
let 
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "musicprod";
    chain_enable_opts  = {
      all = ["electro" "guitar" "score"];
    };
    cfg = {
      cmn.shell.aliases.music.enable = true;
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
      reaper
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

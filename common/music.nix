{ config, lib, pkgs, ... }:
let 
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "musicprod";
    cfg = {
      environment.interactiveShellInit = data_lib.load_aliases [
        "music"
      ];
      environment.systemPackages = with pkgs; [
        youtube-dl
        audacity
      ];
    };
    parents = [ "software" ];
  }

  {
    name = "electro";
    cfg = {
      environment.systemPackages = with pkgs; [
        lmms
        mixxx
      ];
    };
    parents = [ "software" "musicprod" ];
  }
  
  {
    name = "guitar";
    cfg = {
      environment.systemPackages = with pkgs; [
        guitarix
        gxplugins-lv2
      ];
    };
    parents = [ "software" "musicprod" ];
  }

  {
    name = "score";
    cfg = {
      environment.systemPackages = with pkgs; [
        musescore
      ];
    };
    parents = [ "software" "musicprod" ];
  }
]

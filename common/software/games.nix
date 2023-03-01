{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
libconf.create_common_confs [
  {
    name = "retroarch";
    parents = ["software" "games"];
    add_pkgs = with pkgs; [
      retroarchFull
    ];
  }
  {
    name = "dofus";
    parents = ["software" "games"];
    cfg.environment.interactiveShellInit = let
      appimg = "~/.ankama_launcher.AppImage";
    in ''
      function dofus {
        if ! [ -f ${appimg} ]; then
          echo "Please download the Ankama launcher and put it in ${appimg}"
          exit 1;
        fi
        ${pkgs.appimage-run}/bin/appimage-run ${appimg}
      }
    '';
  }
]

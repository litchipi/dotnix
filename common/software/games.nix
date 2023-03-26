{ config, lib, pkgs, ... }:
let
  cfg = config.software.games;
in
  {
    options.software.games = {
      dofus.appimg = lib.mkOption {
        description = "Path to the AppImage for the Dofus game";
        default = "~/.ankama_launcher.AppImage";
        type = lib.types.str;
      };
    };
    config.environment.shellAliases = {
      dofus = ''
        if ! [ -f ${cfg.dofus.appimg} ]; then
          echo "Please download the Ankama launcher and put it in ${cfg.dofus.appimg}"
          exit 1;
        fi
        ${pkgs.appimage-run}/bin/appimage-run ${cfg.dofus.appimg}
      '';
    };
  }

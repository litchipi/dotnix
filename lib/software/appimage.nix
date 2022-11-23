{ config, lib, pkgs, ...}: {

  appimg_type = lib.types.submodule {
    options = {
      appimg = lib.mkOption {
        type = lib.types.path;
        description= "Path to the AppImage file";
      };
      runtimeInputs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "Packages to install as dependencies";
        default = [];
      };
      desktop_options = lib.mkOption {
        type = with lib.types; nullOr attrs;
        description = "Create a desktop shortcut or not";
        default = null;
      };
    };
  };

  mkAppImageDerivation = name: { appimg, runtimeInputs ? [] , desktop_options ? {}}: let
    app = pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        ${pkgs.appimage-run}/bin/appimage-run ${appimg}
      '';
    };
  in
    if (builtins.isNull desktop_options)
    then app
    else pkgs.makeDesktopItem ({
      inherit name;
      exec = "${app}/bin/${name}";
    } // desktop_options);
}

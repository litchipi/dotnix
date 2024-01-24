{ config, lib, pkgs, home-manager-lib, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.hardware.keyboard;

  layout_type = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the keyboard layout";
      };

      languages = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Languages of the layout";
      };

      description = lib.mkOption {
        type = lib.types.str;
        description = "Description of the keyboard layout";
        default = "";
      };
    };
  };
in
  {
    options.hardware.keyboard = {
      layout = lib.mkOption {
        type = with lib.types; nullOr layout_type;
        default = null;
        description = "Keyboard layout to use";
      };
    };
    config = lib.mkIf (! builtins.isNull cfg.layout) {
      services.xserver.extraLayouts.${cfg.layout.name} = {
        inherit (cfg.layout) description languages;
        symbolsFile = libdata.get_data_path [ "config" "xkb_${cfg.layout.name}" ];
      };

      base.home_cfg = {
        dconf.settings."org/gnome/desktop/input-sources".sources = [
          (home-manager-lib.gvariant.mkTuple [ "xkb" cfg.layout.name ])
        ];
      };
    };
  }

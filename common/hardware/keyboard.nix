{ config, lib, pkgs, home-manager-lib, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.cmn.hardware.keyboard;

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
libconf.create_common_confs [
  {
    name = "keyboard";
    default_enabled = true;
    parents = ["hardware"];
    add_opts.layout = lib.mkOption {
      type = with lib.types; nullOr layout_type;
      default = null;
      description = "Keyboard layout to use";
    };
    cfg = lib.mkIf (! builtins.isNull cfg.layout) {
      services.xserver.extraLayouts.${cfg.layout.name} = {
        inherit (cfg.layout) description languages;
        symbolsFile = libdata.get_data_path [ "config" "xkb_${cfg.layout.name}" ];
      };
    };
    home_cfg = lib.mkIf (! builtins.isNull cfg.layout) {
      dconf.settings."org/gnome/desktop/input-sources".sources = [
        (home-manager-lib.gvariant.mkTuple [ "xkb" cfg.layout.name ])
      ];
    };
  }
]

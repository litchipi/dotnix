{ config, lib, pkgs, ...}:
let
  cfg = config.colors;

  colors = import ../lib/colors.nix {inherit config lib pkgs;};
in
{
  config = {
  };

  options.colors = {
    primary = colors.mk_color_option {
      description = "Primary color to use in the system";
      value = {r=255; g=128; b=0;};
    };

    palette = lib.mkOption {
      type = with lib.types; listOf colors.colortype;
      description = "Palette of colors to be used in different themes";
      default = [];
    };

    ok = colors.mk_color_option {
      description = "Color to use when everything goes well";
      value = {r=151; g=240; b=148;}; # #97F094
      style = colors.style.bold;
    };

    warn = colors.mk_color_option {
      description = "Color to use when warning the user about something";
      value = {r=245; g=207; b=91;};  # #F5CF5B
      style = colors.style.bold;
    };

    bad = colors.mk_color_option {
      description = "Color to use when everything goes shit";
      value = {r=245; g=91; b=91;};   # #F55B5B
      style = colors.style.bold;
    };

    # Colors for PS1 prompt
    ps1 = {
      username = colors.mk_color_option {
        description = "Color for PS1 username";
        value = config.colors.primary;
        style = colors.style.bold;
      };

      wdir = colors.mk_color_option {
        description = "Color for PS1 word directory";
        value = {r=200; g=200; b=200;};
        style = colors.style.italic;
      };

      gitps1 = colors.mk_color_option {
        description = "Color for PS1 git information";
        value = colors.get_palette 0;
      };

      dollarsign = colors.mk_color_option {
        description = "Color for PS1 dollar sign";
        value = colors.get_palette 3;
        style = colors.style.bold;
      };
    };
  };
}

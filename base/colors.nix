{ config, lib, pkgs, ...}:
let
  cfg = config.colors;

  colors = import ../lib/colors.nix {inherit config lib pkgs;};
in
{
  config = {
  };

  options.colors = {

    primary_color = colors.mk_color_option {
      description = "Primary color to use in the system";
      default = {r=154; g=36; b=98;};
    };

    secondary_color = colors.mk_color_option {
      description = "Secondary color to use in the system";
      default = {r=217; g=155; b=98;};
    };

    tertiary_color = colors.mk_color_option {
      description = "Tertiary color to use in the system";
      default = {r=98; g=160; b=217;};
    };

    ok_color = colors.mk_color_option {
      description = "Color to use when everything goes well";
      default = {r=36; g=154; b=92;};
    };
    
    bad_color = colors.mk_color_option {
      description = "Color to use when everything goes shit";
      default = {r=173; g=61; b=61;};
    };
  };
}

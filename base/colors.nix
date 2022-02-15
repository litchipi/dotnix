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
      default = {r=0; g=128; b=255;}; # TODO default primary color
    };

    secondary_color = colors.mk_color_option {
      description = "Secondary color to use in the system";
      default = {r=0; g=128; b=255;}; # TODO default secondary color
    };

    tertiary_color = colors.mk_color_option {
      description = "Tertiary color to use in the system";
      default = {r=0; g=128; b=255;}; # TODO default tertiary color
    };

    ok_color = colors.mk_color_option {
      description = "Color to use when everything goes well";
      default = {r=0; g=255; b=0;};
    };
    
    bad_color = colors.mk_color_option {
      description = "Color to use when everything goes shit";
      default = {r=255; g=0; b=0;};
    };
  };
}


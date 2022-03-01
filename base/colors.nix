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
      value = {r=174; g=79; b=129;};
    };

    secondary = colors.mk_color_option {
      description = "Secondary color to use in the system";
      value = {r=217; g=155; b=98;};
    };

    tertiary = colors.mk_color_option {
      description = "Tertiary color to use in the system";
      value = {r=98; g=160; b=217;};
    };

    ok = colors.mk_color_option {
      description = "Color to use when everything goes well";
      value = {r=36; g=154; b=92;};
      style = colors.style.bold;
    };
    
    bad = colors.mk_color_option {
      description = "Color to use when everything goes shit";
      value = {r=173; g=61; b=61;};
      style = colors.style.bold;
    };

    # Colors for PS1 prompt
    ps1 = {
      username = colors.mk_color_option {
        description = "Color for PS1 username";
        value = {r=154; g=36; b=98;};
        style = colors.style.bold;
      };

      wdir = colors.mk_color_option {
        description = "Color for PS1 word directory";
        value = {r=200; g=200; b=200;};
        style = colors.style.italic;
      };

      gitps1 = colors.mk_color_option {
        description = "Color for PS1 git information";
        value = {r=146; g=233; b=178;};
      };

      dollarsign = colors.mk_color_option {
        description = "Color for PS1 dollar sign";
        value = {r=255; g=210; b=71;};
        style = colors.style.bold;
      };
    };
  };
}

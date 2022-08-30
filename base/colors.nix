{ config, lib, pkgs, ...}:
let
  cfg = config.colors;

  colors = import ../lib/colors.nix {inherit config lib pkgs;};


  palette_options = with colors; {
    primary = mk_color_option { color={r=217; g=83; b=79;}; };
    secondary = mk_color_option { color={r=249; g=249; b=249;}; };
    tertiary = mk_color_option { color={r=91; g=192; b=222;}; };
    highlight = mk_color_option { color={r=92; g=184; b=92;}; };
    active = mk_color_option { color={r=167; g=234; b=236;}; };
    inactive = mk_color_option { color={r=104; g=146; b=148;}; };
    dimmed = mk_color_option { color={r=232; g=151; b=149;}; };
    dark = mk_color_option { color={r=83; g=79; b=217;}; };
    light = mk_color_option { color={r=251; g=238; b=191;}; };

    ok = mk_color_option { color={r=151; g=240; b=148;}; style=style.bold; };
    warn = mk_color_option { color={r=245; g=207; b=91;}; style=style.bold; };
    bad = mk_color_option { color={r=245; g=91; b=91;}; style=style.bold; };
  };

in
{
  config = {};
  options.colors = {
    palette = palette_options;

    # Colors for PS1 prompt
    ps1 = {
      username = colors.mk_color_option {
        description = "Color for PS1 username";
        color = cfg.palette.primary;
        style = colors.style.bold;
      };

      wdir = colors.mk_color_option {
        description = "Color for PS1 word directory";
        color = cfg.palette.secondary;
        style = colors.style.italic;
      };

      gitps1 = colors.mk_color_option {
        description = "Color for PS1 git information";
        color = colors.basic.gray 120;
      };

      dollarsign = colors.mk_color_option {
        description = "Color for PS1 dollar sign";
        color = cfg.palette.tertiary;
        style = colors.style.bold;
      };
    };
  };
}

{ config, lib, pkgs, ...}:
let
  cfg = config.colors;

  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  syntax = with colors; let
    cyan = mk_color_option { color={r=130; g=210; b=206;};};
    blue = mk_color_option { color={r=135; g=198; b=255;};};
    lime = mk_color_option { color={r=168; g=204; b=104;};};
    violet = mk_color_option { color={r=175; g=156; b=255;};};
    yellow = mk_color_option { color={r=235; g=200; b=141;};};
    pink = mk_color_option { color={r=255; g=176; b=228;};};
    coral = mk_color_option { color={r=204; g=124; b=138;};};
    gray = mk_color_option { color = {r=160; g=160; b=160;};};
  in {
    text = mk_color_option { color={r=220; g=220; b=220;};};
    types = blue;
    keywords = cyan;
    regexp = cyan;
    constants = {
      variable = violet;
      boolean = cyan;
      numeric = yellow;
      chars = yellow;
      builtin = coral;
      string = pink;
      special_string = yellow;
    };

    label = yellow;
    functions = {
      normal = yellow;
      macro = lime;
    };

    attribute = lime;
    special = lime;
    member = violet;

    comments = gray;

    punctuation = gray;
    module = lime;
    operator = coral;

    markup = {
      heading = cyan;
      list = {
        numbered = cyan;
        unnumbered = cyan;
      };
      link = {
        url = pink;
        text = cyan;
        label = violet;
      };
      quote = pink;
      raw = {
        inline = cyan;
        block = pink;
      };
    };
  };

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

    grays = {
      light = mk_color_option { color = {r=209; g=209; b=209;}; };
      mid = mk_color_option { color = {r=118; g=118; b=118;};};
      dark = mk_color_option { color = {r=70; g=70; b=70;};};
    };
    white = mk_color_option { color = {r=255; g=255; b=255;};};
    black = mk_color_option { color = {r=0; g=0; b=0;};};

    inherit syntax;
  };

in
{
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

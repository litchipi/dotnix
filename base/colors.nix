{ config, lib, pkgs, ...}:
let
  cfg = config.colors;

  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  defaultpalette = [
    {r=221; g=37; b=158;}    # #DD259E
    {r=1; g=205; b=254;}   # 0 #01cdfe
    {r=5; g=255; b=161;}   # 1 #05ffa1
    {r=185; g=103; b=255;} # 2 #b967ff
    {r=255; g=251; b=150;} # 3 #fffb96
    {r=74; g=29; b=72;}    # 4 #4A1D48
    {r=54; g=128; b=100;}  # 5 #368064
    {r=133; g=233; b=255;} # 6 #85E9FF
    {r=171; g=119; b=118;} # 7 #AB7776
  ];
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
      default = defaultpalette;
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

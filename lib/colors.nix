{ config, lib, pkgs, ...}:
let
  escape_code = ''\033['';

  cfg = config.colors;
  
  fg_rgb_color = {r, g, b, style}: style + escape_code + "38;2;${builtins.toString r};${builtins.toString g};${builtins.toString b}m";
  bg_rgb_color = {r, g, b, style}: style + escape_code + "38;2;${builtins.toString r};${builtins.toString g};${builtins.toString b}m";

  apply_to_all_colors = f: set:
    lib.attrsets.mapAttrs (name: value: 
      if (builtins.isAttrs value)
        then (
          if (builtins.hasAttr "r" value)
          then (f value)
          else apply_to_all_colors f value
        )
        else value
    ) set;
in
rec {
  colortype = lib.types.submodule {
    options = {
      r = lib.mkOption { type = lib.types.int; default = 0; };
      g = lib.mkOption { type = lib.types.int; default = 0; };
      b = lib.mkOption { type = lib.types.int; default = 0; };
      style = lib.mkOption { type = lib.types.str; default = ""; };
    };
  };

  tohex = {r, g, b, ...}: let
    f = x: lib.strings.toLower (lib.strings.fixedWidthString 2 "0" (lib.trivial.toHexString x));
  in
    "${f r}${f g}${f b}";

  lighten = amnt: {r, g, b, ...}: let
    addsat = a: b: lib.trivial.min 255 (a + b);
  in {r=addsat r amnt; g=addsat g amnt; b=addsat b amnt;};

  darken = amnt: {r, g, b, ...}: let
    subsat = a: b: lib.trivial.max 0 (builtins.sub a b);
  in {r=subsat r amnt; g=subsat g amnt; b=subsat b amnt;};

  reset = escape_code + "0m";

  style = {
    bold = reset + escape_code + "1m";
    italic = reset + escape_code + "3m";
    underline = reset + escape_code + "4m";
    reverse = reset + escape_code + "7m";
    striked = reset + escape_code + "9m";
    double_underline = reset + escape_code + "21m";
  };

  mk_color_option = {description, value ? {r=0; g=0; b=0;}, style ? reset }: lib.mkOption {
    inherit description;
    type = colortype;
    example = value // {inherit style;};
    default = value // {inherit style;};
  };

  get_palette = idx: if idx >= builtins.length config.colors.palette
    then basic.white
    else builtins.elemAt config.colors.palette idx;

  fg = apply_to_all_colors fg_rgb_color cfg;
  bg = apply_to_all_colors bg_rgb_color cfg;

  # Special colors
  great = style.reverse + (fg_rgb_color cfg.ok_color);
  critical = style.reverse + (fg_rgb_color cfg.bad_color);

  basic = {
    white = {r=255; g=255; b=255;};
    black = {r=0; g=0; b=0;};
    gray = amnt: {r=amnt; g=amnt; b=amnt;};
  };
}

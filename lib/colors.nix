{ config, lib, ... }:
let
  escape_code = ''\033['';

  ansi_fg = {r, g, b, style}: style + escape_code + "38;2;${builtins.toString r};${builtins.toString g};${builtins.toString b}m";
  ansi_bg = {r, g, b, style}: style + escape_code + "38;2;${builtins.toString r};${builtins.toString g};${builtins.toString b}m";

  apply_to_all_colors = f: set:
    lib.attrsets.mapAttrs (_: value:
      if (builtins.isAttrs value)
        then (
          if (builtins.hasAttr "r" value)
          then (f value)
          else apply_to_all_colors f value
        )
        else value
    ) set;

    pow =
    let
      pow' = base: exponent: value:
        if exponent == 0
        then 1
        else if exponent <= 1
        then value
        else (pow' base (exponent - 1) (value * base));
    in base: exponent: pow' base exponent base;


  # Taken from https://gist.github.com/corpix/f761c82c9d6fdbc1b3846b37e1020e11
  hexToDec = v:
  let
    hexToInt = {
      "0" = 0; "1" = 1;  "2" = 2;
      "3" = 3; "4" = 4;  "5" = 5;
      "6" = 6; "7" = 7;  "8" = 8;
      "9" = 9; "a" = 10; "b" = 11;
      "c" = 12;"d" = 13; "e" = 14;
      "f" = 15;
    };
    chars = lib.strings.stringToCharacters v;
    charsLen = builtins.length chars;
  in
    lib.lists.foldl
      (a: v: a + v)
      0
      (lib.lists.imap0
        (k: v: hexToInt."${v}" * (pow 16 (charsLen - k - 1)))
        chars);
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

  fromhex = hex_raw: let
    hex = lib.strings.toLower (lib.strings.removePrefix "#" hex_raw);
    col = idx: hexToDec (builtins.substring idx 2 hex);
  in
    { r = col 0; g = col 2; b = col 4; };

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

  mk_color_option = {
    description ? "Color definition",
    color ? {r=0; g=0; b=0;},
    style ? reset
  }: lib.mkOption {
    inherit description;
    type = colortype;
    example = color // {inherit style;};
    default = color // {inherit style;};
  };

  fg = apply_to_all_colors ansi_fg config.colors;
  bg = apply_to_all_colors ansi_bg config.colors;

  # Special colors
  great = style.reverse + (ansi_fg config.colors.palette.ok);
  critical = style.reverse + (ansi_fg config.colors.palette.bad);

  basic = {
    white = {r=255; g=255; b=255;};
    black = {r=0; g=0; b=0;};
    gray = amnt: {r=amnt; g=amnt; b=amnt;};
  };

  contrast_text = {r, g, b, ...}: { dark ? basic.black, light ? basic.white }: let
    redlum = builtins.div (r*1000) 1944;
    greenlum = builtins.div (g*1000) 1504;
    bluelum = builtins.div (b*1000) 11000;
    luminance = redlum + greenlum + bluelum;
  in if luminance > 115 then dark else light;
}

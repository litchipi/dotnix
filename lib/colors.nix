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
    type = lib.types.attrs;
    example = value // {inherit style;};
    default = value // {inherit style;};
  };

  fg = apply_to_all_colors fg_rgb_color cfg;
  bg = apply_to_all_colors bg_rgb_color cfg;

  # Special colors
  great = style.reverse + (fg_rgb_color cfg.ok_color);
  critical = style.reverse + (fg_rgb_color cfg.bad_color);
}

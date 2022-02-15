{ config, lib, pkgs, ...}:
let
  escape_code = "\033[";
in
rec {
  fg_rgb_color = {r, g, b}: escape_code + "38;2;${builtins.toString r};${builtins.toString g};${builtins.toString b}m";
  bg_rgb_color = {r, g, b}: escape_code + "38;2;${builtins.toString r};${builtins.toString g};${builtins.toString b}m";

  reset = escape_code + "0m";
  style_bold = escape_code + "1m";
  style_italic = escape_code + "3m";
  style_underline = escape_code + "4m";
  style_reverse = escape_code + "7m";
  style_striked = escape_code + "9m";
  style_double_underline = escape_code + "21m";

  mk_color_option = {description, default ? {r=0; g=0; b=0;}}: lib.mkOption {
    inherit description default;
    type = with lib.types; anything;
    example = default;
  };

  primary_color = fg_rgb_color config.colors.primary_color;
  secondary_color = fg_rgb_color config.colors.secondary_color;
  tertiary_color = fg_rgb_color config.colors.tertiary_color;

  ok = style_bold + (fg_rgb_color config.colors.ok_color);
  great = style_reverse + ok;
  
  bad = style_bold + (fg_rgb_color config.colors.bad_color);
  critical = style_reverse + bad;
}

{ config, lib, ... }:
let
  cfg = config.software.alacritty;
in
  {
    options.software.alacritty = {
      enable = lib.mkEnableOption {
        description = "Enable the alacritty terminal";
      };
      settings = lib.mkOption {
        type = lib.types.attrs;
        description = "Settings to override";
        default = {};
      };
    };
    config.home-manager.users.${config.base.user}.programs.alacritty = {
      enable = cfg.enable || (config.software.default_terminal_app.pname == "alacritty");
      settings = lib.attrsets.recursiveUpdate {
        env.TERM = "xterm-256color";
        window = {
          decorations = "none";
          opacity = 0.85;
          padding = {
            x = 15;
            y = 15;
          };
        };
        scrolling = {
          history = 10000;
          multiplier = 3;
        };
        mouse.hide_when_typing = false;
        font.normal = {
          family = "Fira Code";
          style = "Regular";
        };
        font.bold = {
          family = "Fira Code";
          style = "Bold";
        };
        font.italic = {
          family = "Fira Code";
          style = "Italic";
        };
        cursor.unfocused_hollow = true;
        colors = {
          primary = {
            background = "0x000000";
            foreground = "0xffffff";
          };
          dim.black  = "0x333333";
        };
      } cfg.settings;
    };
  }

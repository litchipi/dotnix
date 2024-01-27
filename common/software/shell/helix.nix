{ config, lib, pkgs, inputs, system, ... }:
let
  cfg = config.software.tui.helix;
  palette = config.colors.palette;
  libhelix = import ../../../lib/software/helix.nix { inherit config lib pkgs; };
  libdata = import ../../../lib/manage_data.nix { inherit config lib pkgs; };
  toTOML = import ../../../lib/toTOML.nix { inherit config lib pkgs; };
in {
  options.software.tui.helix = {
    configuration = lib.mkOption {
      type = lib.types.attrs;
      description = "Configuration for the Helix editor";
      default = {};
    };

    themeOverride = lib.mkOption {
      type = lib.types.attrs;
      description = "Theme to apply over the default one to the Helix editor";
      default = {};
    };

    languagesdef = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Lines to add to the `languages.toml` file";
      default = [];
    };
  };
  config = let
    syntax_theme = with palette.syntax; {
      "type" = types;
      "tag" = types;
      "namespace" = types;
      "type.return" = types;
      "type.parameter" = types;

      "constant.builtin.boolean" = constants.boolean;
      "constant.character.escape" = regexp;
      "string.regexp" = regexp;
      "keyword" = keywords;

      "constructor" = functions.normal;
      "constant.character" = constants.chars;
      "constant.numeric" = constants.numeric;
      "label" = label;
      "function" = functions.normal;

      "attribute" = attribute;
      "special" = special;
      "function.macro" = functions.macro;
      "function.builtin" = functions.macro;
      "function.special" = functions.macro;
      "string.special" = {
        fg = constants.special_string;
        modifiers = ["underlined"];
      };

      "constant" = constants.variable;
      "variable.other.member" = member;

      "variable.builtin".fg = constants.builtin;
      "string" = constants.string;

      "comment" = comments;
      "variable" = text;
      "function.declaration" = text;

      markup = {
        bold.modifiers = ["bold"];
        italic.modifiers = ["italic"];
        strikethrough.modifiers = ["crossed_out"];
        heading = { fg = markup.heading; modifiers = [ "bold" ]; };
        "list.numbered" = markup.list.numbered;
        "list.unnumbered" = markup.list.unnumbered;
        "link.url" = { fg = markup.link.url; modifiers = ["italic" "underlined"]; };
        "link.text" = markup.link.text;
        "link.label" = markup.link.label;
        "quote" = markup.quote;
        "raw.inline" = markup.raw.inline;
        "raw.block" = markup.raw.block;
      };
    };

    theme_base = with palette; lib.attrsets.recursiveUpdate {
      # UI
      ui = let 
        verydarkgray = { r = 30; g=30; b=30;};
      in {
        background = {};
        bufferline = {
          active = { fg = black; bg = primary; };
          background = { fg = grays.mid; bg = black; };
        };
        statusline = {
          fg = grays.light;
          bg = black;
          modifiers = ["bold"];
          insert = {
            fg = primary;
            bg = black;
          };
          select = {
            fg = secondary;
            bg = black;
          };
          inactive = {
            fg = grays.mid;
            bg = black;
            modifiers = ["italic"];
          };
        };

        text = {
          focus.fg = white;
          info = grays.light;
          fg = grays.light;
        };

        cursor = {
          fg = secondary; modifiers = ["reversed"];
          match = { fg = black; bg = dark; };
          insert.fg = primary;
          select.fg = highlight;
        };

        selection = { fg = grays.light; bg = grays.mid; };
        selection.primary = { fg=grays.mid; bg = dark; modifiers = ["italic"]; };
        cursorline.bg = verydarkgray;
        linenr.fg = grays.mid;
        linenr.selected = {
          fg = primary;
          modifiers = ["bold"];
        };

        window.fg = primary;
        popup = { fg = primary; bg = verydarkgray; };
        help = { fg = grays.light; bg = black; };
        menu = {
          fg = grays.light;
          bg = black;
          selected = { fg = secondary; modifiers = ["bold"]; };
          scroll = grays.mid;
        };

        virtual = {
          fg = primary;
          ruler.bg = grays.dark;
          indent-guide.fg = dark;
          inlay-hint.fg = secondary;
        };
      };

      # Diagnostic
      info = primary;
      hint = grays.mid;
      warning = warn;
      error = bad;
      diagnostic = {
        fg = grays.mid;
        bg = black;
        info = {
          underline = { color = primary; style = "line"; };
        };
        hint = {
          underline = { color = secondary; style = "line"; };
        };
        warning = {
          fg = warn;
          underline = { color = warn; style = "line"; };
        };
        error = {
          fg = bad;
          underline = { color = bad; style = "line"; };
        };
      };

      # Diff
      diff = {
        delta = warn;
        plus = ok;
        minus = bad;
      };
    } syntax_theme;

    theme = lib.attrsets.recursiveUpdate theme_base cfg.themeOverride; 
    theme_file = pkgs.writeText "helix_theme.toml" (libhelix.mkTheme theme);

    default_config = builtins.fromTOML (libdata.read_data ["config" "helix" "default_config.toml"]);
    config = lib.attrsets.recursiveUpdate default_config cfg.configuration;
    config_file = pkgs.writeText "helix_config.toml" (toTOML config);
  in {
    environment.systemPackages = [ inputs.helix.packages.${system}.default ];
    base.home_cfg.home.file.".config/helix/config.toml".source = config_file;
    base.home_cfg.home.file.".config/helix/themes/nixos.toml".source = theme_file;
    base.home_cfg.home.file.".config/helix/languages.toml".text =
      builtins.concatStringsSep "\n\n" cfg.languagesdef;
  };
}

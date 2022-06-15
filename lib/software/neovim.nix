{ config, lib, pkgs, ...}: let
  libcolors = import ../colors.nix {inherit config lib pkgs;};
in {
  generate_theme = theme: builtins.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (name: {fg ? null, bg ? null, style ? null}@col: let
      guibg = if builtins.isNull bg then ""
        else if bg == "none" then "guibg=none"
        else "guibg='#${libcolors.tohex bg}'";

      guifg = if builtins.isNull fg then ""
        else if fg == "none" then "guifg=none"
        else "guifg='#${libcolors.tohex fg}'";

      gui = if builtins.isNull style then ""
        else if style == "none" then "gui=none"
        else "gui=${style}";
    in
      "hi! ${name} ${guifg} ${guibg} ${gui}"
    )
  theme);

  default_theme = {
    Comment.fg = libcolors.get_palette 5;
    Comment.style = "italic";

    LineNr.fg = libcolors.get_palette 4;
    SignColumn.fg = libcolors.get_palette 2;
    SignColumn.bg = "none";

    CursorLineNr.fg = libcolors.get_palette 1;
    CursorLineNr.style = "bold";
    CursorLine.bg = libcolors.darken 30 (libcolors.get_palette 4);

    ColorColumn.bg = libcolors.get_palette 4;
    Cursor.style = "bold";
    TermCursor.bg = config.colors.primary;
    TermCursorNC.bg = libcolors.basic.gray 80;

    Search.fg = libcolors.basic.black;
    Search.bg = libcolors.get_palette 1;
    Substitute.fg = libcolors.basic.black;
    Substitute.bg = libcolors.get_palette 1;

    Normal.fg = libcolors.basic.white;
    NormalNC.fg = libcolors.basic.gray 180;

    Todo = {
      bg = libcolors.get_palette 4;
      fg = libcolors.get_palette 3;
      style = "bold,underline";
    };
    CocHintSign.fg = libcolors.get_palette 5;

    Pmenu.bg = libcolors.darken 10 (libcolors.get_palette 4);
    Pmenu.fg = libcolors.basic.white;
    PmenuSel = {
      fg = libcolors.get_palette 3;
      bg = libcolors.get_palette 4;
      style = "bold";
    };
    PmenuSbar.bg = libcolors.get_palette 3;


    SpellBad.fg = config.colors.bad;
    SpellBad.style = "bold";
    WarningMsg.fg = config.colors.warn;
    WarningMsg.style = "bold";
    Whitespace.bg = config.colors.bad;

    WinSeparator.fg = config.colors.primary;
    Error.fg = config.colors.bad;
    Error.bg = "none";
    Error.style = "bold";

    Identifier.fg = libcolors.get_palette 0;
    Statement.fg = libcolors.get_palette 1;
    Constant.fg = libcolors.get_palette 3;
    PreProc.fg = libcolors.get_palette 2;
    String.fg = libcolors.get_palette 6;
    Type.fg = config.colors.primary;
    Special.fg = libcolors.get_palette 7;

    DiffAdd = {
      fg = config.colors.ok;
      bg = "none";
      style = "bold";
    };
    DiffDelete = {
      fg = config.colors.bad;
      bg = "none";
      style = "bold";
    };
    DiffChange = {
      fg = config.colors.warn;
      bg = "none";
      style = "bold";
    };

    # TODO  Airline theme
  };
}

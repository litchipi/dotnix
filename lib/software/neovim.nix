{ config, lib, pkgs, ...}: let
  libcolors = import ../colors.nix {inherit config lib pkgs;};
  pal = config.colors.palette;
in {
  generate_theme = theme: builtins.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (name: {fg ? null, bg ? null, style ? null}: let
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
    LineNr.fg = libcolors.basic.gray 80;
    SignColumn.fg = libcolors.basic.gray 80;
    SignColumn.bg = "none";

    CursorLineNr.fg = pal.secondary;
    CursorLineNr.style = "bold";
    CursorLine.bg = libcolors.basic.gray 60;

    ColorColumn.bg = pal.dark;
    Cursor.style = "bold";
    TermCursor.bg = pal.primary;
    TermCursorNC.bg = libcolors.basic.gray 80;

    Search.fg = libcolors.contrast_text pal.primary {};
    Search.bg = pal.primary;
    Substitute.fg = libcolors.contrast_text pal.primary {};
    Substitute.bg = pal.primary;

    Normal.fg = libcolors.basic.white;
    NormalNC.fg = libcolors.basic.gray 170;

    Todo = {
      bg = pal.secondary;
      fg = libcolors.contrast_text pal.secondary {};
      style = "bold,underline";
    };
    CocHintSign.fg = pal.dark;

    Pmenu.bg = libcolors.darken 40 pal.dark;
    Pmenu.fg = libcolors.basic.white;
    PmenuSel = {
      fg = pal.primary;
      bg = pal.dark;
      style = "bold";
    };
    PmenuSbar.bg = pal.highlight;


    SpellBad.fg = pal.bad;
    SpellBad.style = "bold";
    WarningMsg.fg = pal.warn;
    WarningMsg.style = "bold";
    Whitespace.bg = pal.bad;

    WinSeparator.fg = pal.primary;
    Error.fg = pal.bad;
    Error.bg = "none";
    Error.style = "bold";

    # Code syntax highlight
    Keyword.fg = pal.primary;
    Macro.fg = pal.primary;
    Identifier.fg = pal.primary;

    Type.fg = pal.secondary;
    PreProc.fg = pal.secondary;

    Statement.fg = pal.tertiary;
    SpecialComment.fg = pal.tertiary;

    Structure.fg = pal.highlight;
    StorageClass.fg = pal.highlight;

    Function.fg = pal.active;

    Comment.fg = pal.inactive;
    Special.fg = pal.inactive;
    Comment.style = "italic";

    Constant.fg = pal.light;
    Strings.fg = pal.dimmed;
    Exception.fg = pal.bad;

    DiffAdd = {
      fg = pal.ok;
      bg = "none";
      style = "bold";
    };
    DiffDelete = {
      fg = pal.bad;
      bg = "none";
      style = "bold";
    };
    DiffChange = {
      fg = pal.warn;
      bg = "none";
      style = "bold";
    };
  };

  generate_airline_theme = theme: let
    name = "custom_airline_theme_${config.base.hostname}";
    get_color_def = {guifg, guibg, termfg, termbg}: "[ " + (builtins.concatStringsSep ", " [
      "'#${libcolors.tohex guifg}'"
      "'#${libcolors.tohex guibg}'"
      "'${builtins.toString termfg}'"
      "'${builtins.toString termbg}'"
    ]) + " ]";
    theme_dir = let
      head = ''
        let g:airline#themes#${name}#palette = {}
      '';
      tail = ''
        if get(g:, 'loaded_ctrlp', 0)
        let g:airline#themes#dark#palette.ctrlp = airline#extensions#ctrlp#generate_color_map(
          \ ${get_color_def theme.CP1},
          \ ${get_color_def theme.CP2},
          \ ${get_color_def theme.CP3})
        endif
      '';
    in pkgs.writeTextDir "autoload/airline/themes/${name}.vim" (
        head + (
          builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (type: prefix: ''
            let g:airline#themes#${name}#palette.${type} = airline#themes#generate_color_map(
              \ ${get_color_def theme."${prefix}1"},
              \ ${get_color_def theme."${prefix}2"},
              \ ${get_color_def theme."${prefix}3"})
          '') {
          normal = "N";
          insert = "I";
          replace = "R";
          visual = "V";
          inactive = "IA";
        })
      ) + tail
    );
  in ''
      let &runtimepath.=','.escape('${theme_dir}', '\,')
      let g:airline_theme='${name}'
    '';

  airline_default_theme = rec {
    N1 = {
      guibg = pal.primary;
      guifg = libcolors.contrast_text pal.primary {};
      termbg = 90; termfg = 15;
    };
    I1 = {
      guibg = pal.secondary;
      guifg = libcolors.contrast_text pal.secondary {};
      termbg = 105; termfg = 0;
    };
    R1 = {
      guibg = pal.tertiary;
      guifg = libcolors.contrast_text pal.tertiary {};
      termbg = 202; termfg = 0;
    };
    V1 = {
      guibg = pal.highlight;
      guifg = libcolors.contrast_text pal.highlight {};
      termbg = 220; termfg = 0;
    };
    IA1 = {
      guibg = pal.inactive;
      guifg = libcolors.contrast_text pal.inactive {};
      termbg = 241; termfg = 248;
    };
    N2 = {
      guibg = libcolors.basic.gray 60;
      guifg = libcolors.basic.gray 150;
      termbg = 244; termfg = 251;
    };
    N3 = {
      guibg = libcolors.basic.gray 40;
      guifg = libcolors.basic.gray 150;
      termbg = 239; termfg = 244;
    };
    I2 = N2;
    I3 = N3;
    R2 = N2;
    R3 = N3;
    V2 = N2;
    V3 = N3;
    IA2 = N2;
    IA3 = N3;
    CP1 = V1;
    CP2 = V2;
    CP3 = V3;
  };
}

{ config, lib, pkgs, ...}: let
  libcolors = import ../colors.nix {inherit config lib pkgs;};

  pal = config.colors.palette;
  col = c: if c == "default" then c else "#${libcolors.toHex c}";

  tmuxstyle = {fg ? null, bg ? null, add ? null, ...}: builtins.concatStringsSep ","
      ((if (builtins.isNull fg) then [] else [ "fg=${col fg}" ]) ++
      (if (builtins.isNull bg) then [] else [ "bg=${col bg}" ]) ++
      (if (builtins.isNull add) then [] else [ add ]));

  tmuxfmts = cnt: builtins.concatStringsSep "" (builtins.map tmuxfmt cnt);

  tmuxfmt = { txt, ...}@fmt: let
    all_styles = tmuxstyle fmt;
    style = if all_styles == "" then "" else "#[${all_styles}]";
  in
    style + txt;

  sidebar = {char, left}: content_list: let
    sepchar = col0: col1: if !left
      then "#[fg=${col col0},bg=${col col1}]${char}"
      else "#[fg=${col col1},bg=${col col0}]${char}";
    first = builtins.elemAt content_list 0;
    last = lib.lists.last content_list;
    res = builtins.foldl' (state: cnt: {
        inherit (cnt) bg;
        sep = true;
        acc = state.acc +
          (if state.sep
          then sepchar cnt.bg state.bg else "")
          + tmuxfmt (cnt // { txt = " " + cnt.txt + " "; });
      }) {
        bg = null;
        acc = if !left then sepchar first.bg "default" else "";
        sep = false;
      } content_list;
    in
      res.acc + (if left then sepchar "default" last.bg else "");

      disk_usage = " #(df -l|grep -e \"/$\"|awk -F ' ' '{print $5}')";
      connected = "#(if ping -c 1 1.1.1.1 2>/dev/null 1>/dev/null; then echo '󰖟'; else echo ''; fi)";
in {
  generate_theme = theme: builtins.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (name: cnt:
    "set -g ${name} \"${cnt}\""
    )
  theme) + "\n";

  default_vars = {
    status = {
      interval = "10";
      justify = "centre";
    };
    status.left = {
      length = "40";
      left = "#H";
      mid = "#(whoami)";
      right = "#S";
    };
    status.right = {
      length = "150";
      right = "%D";
      mid = "%H:%M";
      left = "${connected} ${disk_usage}";
    };
  };

  default_theme = vars: {
    "pane-border-style" = tmuxstyle { fg = pal.secondary; bg = "default"; };
    "pane-active-border-style" = tmuxstyle { fg = pal.primary; bg = "default"; add = "bold";};
    "message-style" = tmuxstyle { fg = pal.primary; };

    "mode-style" = tmuxstyle { bg = pal.dark; fg = libcolors.basic.white; };

    "status-style" = tmuxstyle { bg = "default"; };
    "status-left" = sidebar { char = ""; left = true;} [
      {
        bg = pal.primary;
        fg = libcolors.contrast_text pal.primary {};
        txt = vars.status.left.left;
        add="bold";
      }
      {
        bg = pal.secondary;
        fg = libcolors.contrast_text pal.secondary {};
        txt = vars.status.left.mid;
      }
      {
        bg = libcolors.basic.gray 40;
        fg = pal.tertiary;
        txt = vars.status.left.right;
        add="nobold";
      }
    ];
    "status-right" = sidebar {char = ""; left=false;} [
      {
        bg = libcolors.basic.gray 40;
        fg = pal.tertiary;
        txt = vars.status.right.left;
        add="nobold";
      }
      {
        bg = pal.secondary;
        fg = libcolors.contrast_text pal.secondary {};
        txt = vars.status.right.mid;
        add="bold";
      }
      {
        bg = pal.primary;
        fg = libcolors.contrast_text pal.primary {};
        txt = vars.status.right.right;
      }
    ];

    "status-interval" = vars.status.interval;
    "status-justify" = vars.status.justify;
    "status-left-length" = vars.status.left.length;
    "status-right-length" = vars.status.right.length;

    "window-status-current-format" = tmuxfmts [
      { txt = " "; bg="default"; fg = pal.primary; add="nobold,noitalics"; }
      { txt = "#W"; add = "bold"; }
      { txt = " "; add="nobold"; }
    ];

    "window-status-format" = tmuxfmt {
      txt = "  #W  ";
    };

    "window-status-style" = tmuxstyle {
      bg="default";
      fg = pal.primary;
      add="nobold,italics";
    };
    "window-status-activity-style" = tmuxstyle {
      fg = pal.active; add = "bold,noitalics"; };
    "window-status-bell-style" = tmuxstyle {
      fg = pal.active; add = "reverse,bold,noitalics"; };
  };
}

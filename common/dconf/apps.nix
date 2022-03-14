{config, lib, pkgs, inputs, ...}:

with inputs.home-manager.lib.hm.gvariant;

let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "apps";
    parents = ["dconf"];
    home_cfg.dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";
        search-filter-time-type = "first_modified";
        search-view = "list-view";
      };

      "org/gnome/nautilus/compression" = {
        default-compression-format = "zip";
      };

      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "larger";
      };

      "org/gnome/gedit/preferences/editor" = {
        scheme = "Yaru-dark";
        tabs-size = mkUint32 2;
        use-default-font = true;
        wrap-last-split-mode = "word";
      };

      "org/gnome/gedit/preferences/print" = {
        print-font-body-pango = "Monospace 9";
        print-font-header-pango = "Sans 11";
        print-font-numbers-pango = "Sans 8";
        print-header = false;
        print-line-numbers = mkUint32 0;
        print-syntax-highlighting = true;
        print-wrap-mode = "word";
      };

      "org/gnome/gedit/preferences/ui" = {
        show-tabs-mode = "auto";
      };

      "org/gnome/gedit/state/file-chooser" = {
        open-recent = true;
      };

      "org/gnome/gedit/state/window" = {
        bottom-panel-size = 140;
        side-panel-active-page = "GeditWindowDocumentsPanel";
        side-panel-size = 200;
        size = mkTuple [ 1440 746 ];
        state = 43908;
      };

      "org/gnome/gedit/plugins" = {
        active-plugins = [ "spell" "sort" "docinfo" "filebrowser" "modelines" ];
      };

      "org/gnome/gedit/plugins/filebrowser" = {
        root = "file:///";
        tree-view = true;
      };

      "org/gnome/evince/default" = {
        continuous = true;
        dual-page = false;
        dual-page-odd-left = false;
        enable-spellchecking = true;
        fullscreen = false;
        inverted-colors = false;
        show-sidebar = true;
        sidebar-page = "links";
        sidebar-size = 199;
        sizing-mode = "free";
        window-ratio = mkTuple [ 1.0081699346405228 0.7121212121212122 ];
        zoom = 0.75;
      };
    };
  }
]

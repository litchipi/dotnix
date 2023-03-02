{ config, lib, pkgs, pkgs_unstable, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libnvim = import ../../lib/software/neovim.nix {inherit config lib pkgs;};

  cfg = config.cmn.software.tui;
in
libconf.create_common_confs [
  {
    name = "neovim";
    minimal.cli = true;
    parents = [ "software" "tui" ];
    add_pkgs = with pkgs; [
      neovim

      # Coc-nvim
      nodejs
      yarn
    ];
    add_opts = {
      add_plugins = lib.mkOption {
        type = with lib.types; listOf package;
        default = [];
        description = "List of plugins to add to the configuration";
      };

      vimcfg = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "List of vim configuration lines to add to the config";
      };

      themeOverride = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Theme to apply over the default one";
      };

      airlineThemeOverride = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Theme to override on the Airline plugin";
      };
    };
    cfg.environment.variables.EDITOR = "nvim";
    home_cfg = {
      home.file.".local/share/nvim/site/autoload/plug.vim".source = let
        src = pkgs.fetchFromGitHub {
          owner = "junegunn";
          repo = "vim-plug";
          rev = "8fdabfba0b5a1b0616977a32d9e04b4b98a6016a";
          sha256 = "sha256-jAr/xyQAYM9a1Heh1nw1Rsf2dKGRhlXs0Z4ETTAT0hA=";
        };
      in "${src}/plug.vim";

      programs.neovim = {
        enable = true;
        vimAlias = true;
        vimdiffAlias = true;

        withPython3 = true;
        withNodeJs = true;
        withRuby = true;

        coc = {
          enable = true;
          package = pkgs_unstable.vimPlugins.coc-nvim;
          # vimUtils.buildVimPluginFrom2Nix {
          #   pname = "coc.nvim";
          #   version = "2022-05-21";
          #   src = pkgs.fetchFromGitHub {
          #     owner = "neoclide";
          #     repo = "coc.nvim";
          #     rev = "791c9f673b882768486450e73d8bda10e391401d";
          #     sha256 = "sha256-MobgwhFQ1Ld7pFknsurSFAsN5v+vGbEFojTAYD/kI9c=";
          #   };
          #   meta.homepage = "https://github.com/neoclide/coc.nvim/";
          # };

          settings = {
            diagnostic = {
              enableSign = true;
              enableHighlightLineNumber = true;
              errorSign = "✘";
              warningSign = "!";
              infoSign = ">";
              enableMessage = "jump";
              virtualText = true;
              refreshOnInsertMode = true;
              autoRefresh = true;
              level = "warning";
              virtualTextCurrentLineOnly = false;
            };
          };
        };

        extraPython3Packages = (ps: with ps; [
          pynvim
        ]);

        plugins = with pkgs.vimPlugins; [
          tagbar

          vim-airline
          vim-airline-themes
          nerdcommenter
          nerdtree
          neoformat
          fzf-vim
          zoomwintab-vim
          vim-bbye
          indentLine
          vim-plug
          nvim-colorizer-lua
          vim-better-whitespace

          # TODO  Telescope nvim setup
          # Telescope
          telescope-nvim

          # TODO  Langage setup to migrate to specialized sections
          vimtex
          vim-toml
          haskell-vim
          vim-latex-live-preview

          # Coc
          coc-fzf
          coc-json
          coc-lists
          coc-vimtex
          coc-markdownlint
        ] ++ cfg.neovim.add_plugins;

        extraConfig = builtins.concatStringsSep "\n" ([
          "call plug#begin()"
          (builtins.concatStringsSep "\n\n" (builtins.map (plug: "  Plug '${plug}'")
            (cfg.neovim.add_plugins ++ [
              "markstory/vim-zoomwin"
              # "reedes/vim-colors-pencil"
              # "miyakogi/conoline.vim"
            ])
          ))
          "call plug#end()"
          (libdata.read_data ["config" "nvim" "plugins.vim"])
          (libdata.read_data ["config" "nvim" "base.vim"])
          (libdata.read_data ["config" "nvim" "autocmds.vim"])
          (libdata.read_data ["config" "nvim" "keybindings.vim"])

          # Setting the base colors for the theme
          (libnvim.generate_theme (libnvim.default_theme // cfg.neovim.themeOverride))
          (libnvim.generate_airline_theme (libnvim.airline_default_theme // cfg.neovim.airlineThemeOverride))
        ] ++ cfg.neovim.vimcfg);
      };

      /** install the few vim-plug plugins in a non-reproducable way
       automatically upon 'home-manager switch' by running neovim
       in headless mode to run :PlugInstall
      */
      home.activation = {
        neovimPlugInstall = ''
          # plugin update rev 1
          # update the number above to force plugin updates, and if it works do it on all
          # machines to have a chance at getting the same setup. Or better yet create a nix derivation for them :)
          $DRY_RUN_CMD nvim -c ':PlugInstall!' -c ':PlugDiff' -c ':PlugClean!' -c ':UpdateRemotePlugins' -c ':q!' -c 'q!' --headless
        '';
      };
    };
  }
]

{ config, lib, pkgs, ... }:
let
  libconf = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../lib/utils.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};
in
libconf.create_common_confs [
  {
    name = "tui";
    parents = [ "software" ];
    add_pkgs = with pkgs; [
      du-dust
      fzf
      ripgrep
      autojump
      irssi
      wkhtmltopdf
      youtube-dl

      # TODO Configure / replace with other software
      htop

      # TODO Replace with other ?
      neofetch

      # Custom TUI tools
      litchipi.pomodoro
      litchipi.memory
    ];
    cfg = {
      cmn.software.tui.neovim.enable = true;
      cmn.software.tui.tmux.enable = true;
      cmn.software.tui.jrnl.enable = true;
      cmn.shell.aliases = {
        filesystem.enable = true;
        music.enable = true;
        network.enable = true;
        nix.enable = true;
        memory.enable = true;
      };
    };
  }

  {
    name = "neovim";
    parents = [ "software" "tui" ];
    add_pkgs = with pkgs; [
      neovim
    ];
    add_opts = {
      add_plugins = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "List of plugins to add to the configuration";
      };

      coc-settings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Special Coc settings to set";
      };

      vimcfg = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "List of vim configuration lines to add to the config";
      };
    };
    home_cfg = {
      home.file.".local/share/nvim/site/autoload/plug.vim".source = libdata.get_data_path ["config" "nvim" "plug.vim"];

      programs.bash.sessionVariables = {
        EDITOR = "nvim";
      };

      programs.neovim = {
        enable = true;
        vimAlias = true;
        vimdiffAlias = true;

        withPython3 = true;
        withNodeJs = false;
        withRuby = false;

        extraPython3Packages = (ps: with ps; [
          pynvim
        ]);

        plugins = with pkgs.vimPlugins; [
          tagbar

          nerdtree
          nerdcommenter
          neoformat
          fzf-vim
          zoomwintab-vim
          vim-bbye
          indentLine
          haskell-vim
          vim-toml
          vimtex
          vim-latex-live-preview
          vim-plug

          # Theme
          tokyonight-nvim
          vim-airline

          # Coc
          coc-vimtex
          coc-fzf
          coc-nvim
          # coc-toml
          coc-json
          coc-lists
          coc-markdownlint
        ];

        extraConfig = builtins.concatStringsSep "\n" ([
          "call plug#begin()"
          (builtins.concatStringsSep "\n\n" (builtins.map (plug: "  Plug '${plug}'")
            (config.cmn.software.tui.neovim.add_plugins ++ [
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
          ''

          ''
          (libdata.read_data ["config" "nvim" "theme.vim"])
        ] ++ config.cmn.software.tui.neovim.vimcfg);
      };

      xdg.configFile."nvim/coc-settings.json".text = let
        default_coc_settings = {
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
        in builtins.toJSON (lib.attrsets.recursiveUpdate default_coc_settings config.cmn.software.tui.neovim.coc-settings);

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

  {
    name = "git";
    parents = [ "software" "tui" ];
    add_pkgs = with pkgs; [
      git
    ];
    add_opts = {
      ps1 = lib.mkOption {
        type = lib.types.str;
        default = "${colors.fg.ps1.gitps1}\\`__git_ps1 \\<%s\\>\\` ";
        description = "Indication of git repo in prompt info of bash";
      };
    };
    cfg = {
      cmn.shell.aliases.git.enable = true;
    };
    home_cfg.programs = {
      git = {
        enable = true;
        userName = libutils.email_to_name config.base.email;
        userEmail = config.base.email;
      };

      neovim.plugins = with pkgs.vimPlugins; [
        vim-fugitive
        vim-gitgutter
        coc-git
      ];
    };
  }

  {
    name = "tmux";
    parents = [ "software" "tui" ];
    add_pkgs = with pkgs; [
      tmux
      tmuxp

      # TODO Add tmuxp_session_creator
      # litchipi.tmuxp_session_creator
    ];

    home_cfg = {
      programs.neovim.plugins = with pkgs.vimPlugins; [
        tmux-complete-vim
      ];
    };
  }

  {
    name = "jrnl";
    parents = ["software" "tui" ];

    add_opts = {
      opts_override = lib.mkOption {
        type = lib.types.attrs;
        description = "Options for Jrnl to manually set";
        default = {};
      };

      encrypt = lib.mkOption {
        type = lib.types.bool;
        description = "Wether to encrypt the journal or not";
        default = true;
      };

      add_journals = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Additional journals to add for usage";
        default = ["default"];
      };

      jrnl_paths = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/.local/share/jrnl";
        description = "Where to store the journal files";
      };

      editor = lib.mkOption {
        type = lib.types.str;
        default = "nvim";
        description = "Command to use for journal edition";
      };
    };

    add_pkgs = with pkgs; [
      jrnl
    ];

    home_cfg.xdg.configFile."jrnl/jrnl.yaml".text = let
      cfg = config.cmn.software.tui.jrnl;
    in ''
      colors:
        body: none
        date: none
        tags: none
        title: none
      default_hour: 9
      default_minute: 0
      editor: '${cfg.editor}'
      encrypt: ${builtins.toString cfg.encrypt}
      highlight: true
      indent_character: '|'
      journals:
    '' + (builtins.foldl' (acc: name:
        acc + "  ${name}: ${cfg.jrnl_paths}/${name}.txt\n"
        ) "" cfg.add_journals) +
    ''
      linewrap: 100
      tagsymbols: '@'
      template: false
      timeformat: '%Y-%m-%d %H:%M'
      version: v2.8.3
    '';

    cfg = {
      cmn.shell.aliases.jrnl.enable = true;
    };
  }
]

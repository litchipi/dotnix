{ config, lib, pkgs, ... }:
let
  libconf = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../lib/utils.nix {inherit config lib pkgs;};

  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
  libnvim = import ../lib/software/neovim.nix {inherit config lib pkgs;};
  libtmux = import ../lib/software/tmux.nix {inherit config lib pkgs;};

  cfg = config.cmn.software.tui;
in
libconf.create_common_confs [
  {
    name = "tui";
    minimal.cli = true;
    parents = [ "software" ];
    add_pkgs = with pkgs; [
      fzf
      ripgrep
      autojump
      glances
      python310

      unzip unrar
    ];
    cfg = {
      cmn.software.tui = {
        full.enable = lib.mkDefault true;
        git.enable = lib.mkDefault true;
        neovim.enable = lib.mkDefault true;
        tmux.enable = lib.mkDefault true;
        jrnl.enable = lib.mkDefault true;
        irssi.enable = lib.mkDefault true;
      };

      cmn.shell.aliases = {
        filesystem.enable = lib.mkDefault true;
        network.enable = lib.mkDefault true;
        nix.enable = lib.mkDefault true;
      };
    };
  }

  {
    name = "full";
    parents = ["software" "tui"];
    add_pkgs = with pkgs; [
      du-dust
      irssi
      wkhtmltopdf
      youtube-dl
      ffmpeg
      neofetch
      bat

      # Custom TUI tools
      litchipi.pomodoro
      litchipi.memory
    ];
    cfg = {
      cmn.shell.aliases = {
        music.enable = lib.mkDefault true;
        memory.enable = lib.mkDefault true;
      };
    };
  }

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
        type = with lib.types; listOf str;
        default = [];
        description = "List of plugins to add to the configuration";
      };

      coc-plugins = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "Plugins to install for coc-nvim";
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
        withNodeJs = true;
        withRuby = true;

        coc = {
          enable = true;
          package = pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "coc.nvim";
            version = "2022-05-21";
            src = pkgs.fetchFromGitHub {
              owner = "neoclide";
              repo = "coc.nvim";
              rev = "791c9f673b882768486450e73d8bda10e391401d";
              sha256 = "sha256-MobgwhFQ1Ld7pFknsurSFAsN5v+vGbEFojTAYD/kI9c=";
            };
            meta.homepage = "https://github.com/neoclide/coc.nvim/";
          };

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
          nvim-colorizer-lua

          # Theme
          vim-airline
          vim-airline-themes

          # Coc
          coc-fzf
          coc-json
          coc-lists
          coc-vimtex
          coc-markdownlint
        ];

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

  {
    name = "git";
    minimal.cli = true;
    parents = [ "software" "tui" ];
    add_pkgs = [
      (if config.cmn.wm.enable then pkgs.gitFull else pkgs.git)
    ];
    add_opts = {
      ps1 = lib.mkOption {
        type = lib.types.str;
        default = "\\[${libcolors.fg.ps1.gitps1}\\]\\`__git_ps1 \\\"<%s> \\\"\\`";
        description = "Indication of git repo in prompt info of bash";
      };
    };
    cfg = {
      cmn.shell.aliases.git.enable = true;
    };
    home_cfg.programs = {
      git = {
        enable = true;
        userName = lib.mkDefault (libutils.email_to_name config.base.email);
        userEmail = lib.mkDefault config.base.email;
        extraConfig = {
          init.defaultBranch = "main";
          safe.directory = "/etc/nixos";
          credential.helper = "${
              pkgs.git.override { withLibsecret = true; }
            }/bin/git-credential-libsecret";
        };
      };

      neovim.plugins = with pkgs.vimPlugins; [
        vim-fugitive
        vim-gitgutter
        coc-git
      ];
      neovim.extraConfig = ''

        " GitGutter
        let g:gitgutter_git_executable="${pkgs.git}/bin/git"
        let g:gitgutter_set_sign_backgrounds = 0
        let g:gitgutter_map_keys = 0
      '';
    };
  }

  {
    name = "tmux";
    minimal.cli = true;
    parents = [ "software" "tui" ];

    add_pkgs = with pkgs; [
      tmux
      tmuxp
    ];

    add_opts = {
      extraConfig = lib.mkOption {
        type = lib.types.str;
        description = "Extra tmux configuration to add";
        default = "";
      };

      themeOverride = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Theme to apply over the default one";
      };

      varsOverride = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Override theme variables over default ones";
      };
    };

    cfg.fonts.fonts = [
      pkgs.nerdfonts
      pkgs.powerline-fonts
    ];

    home_cfg.programs = {
      bash.shellAliases = {
        quitses = "tmux kill-session -t $(tmux display-message -p \"#S\")";
      };

      neovim.plugins = with pkgs.vimPlugins; [
        tmux-complete-vim
      ];

      tmux = {
        enable = true;
        clock24 = true;

        prefix = "M-p";
        terminal = "xterm-256color";
        historyLimit = 10000;
        escapeTime = 0;
        keyMode = "vi";
        sensibleOnTop = false;
        secureSocket = true;
        plugins = with pkgs.tmuxPlugins; [
          better-mouse-mode
        ];
        tmuxp.enable = true;
        extraConfig = ''
          set -ga terminal-overrides ",*256col*:Tc"

          unbind d
          unbind z
          unbind q
          unbind s
          bind-key f split-window -h
          bind-key r split-window -v

          bind-key q previous-window
          bind-key Q resize-pane -L 3
          bind-key d next-window
          bind-key D resize-pane -R 3
          bind-key Z resize-pane -U 3
          bind-key S resize-pane -D 3

          bind-key a select-pane -t :.-
          bind-key A swap-pane -D
          bind-key e select-pane -t :.+
          bind-key E swap-pane -U
          bind-key z new-window
          bind-key s confirm-before -p "kill-window #W? (y/n)" kill-pane
          bind-key M-s confirm-before -p "kill-window #W? (y/n)" kill-window
          bind-key m resize-pane -Z

          bind-key M-q swap-window -t -1
          bind-key M-d swap-window -t +1

          bind-key p paste-buffer
          bind-key o copy-mode
          #bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

          bind-key n command-prompt -I "#W" "rename-window -- '%%'"

          bind-key & select-window -t 0
          bind-key é select-window -t 1
          bind-key '"' select-window -t 2
          bind-key "'" select-window -t 3
          bind-key - select-window -t 4
          bind-key è select-window -t 5
          bind-key _ select-window -t 6
          bind-key ç select-window -t 7
          bind-key à select-window -t 8
          bind-key ) select-window -t 9
          
          set -g @urlview-key 'u'
          set -g monitor-activity on
          set -g default-terminal "tmux"

          set -g mouse on
          unbind -T copy-mode-vi MouseDragEnd1Pane
          bind -T copy-mode-vi MouseDown3Pane send -X clear-selection \; send-keys -X cancel

          # Generated theme
        ''
        + (libtmux.generate_theme
            ((libtmux.default_theme (libtmux.default_vars // cfg.tmux.varsOverride))
            // cfg.tmux.themeOverride)
          )
        + cfg.tmux.extraConfig;
      };
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

    home_cfg.xdg.configFile."jrnl/jrnl.yaml".text = ''
      colors:
        body: none
        date: none
        tags: none
        title: none
      default_hour: 9
      default_minute: 0
      editor: '${cfg.jrnl.editor}'
      encrypt: ${builtins.toString cfg.jrnl.encrypt}
      highlight: true
      indent_character: '|'
      journals:
    '' + (builtins.foldl' (acc: name:
        acc + "  ${name}: ${cfg.jrnl.jrnl_paths}/${name}.txt\n"
        ) "" cfg.jrnl.add_journals) +
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

  {
    # TODO  Add custom keybindings to Irssi
    name = "irssi";
    parents = [ "software" "tui" ];
    add_opts = {
      extraConfig = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Configuration to add at the bottom of the default one";
      };
      default_nick = lib.mkOption {
        type = lib.types.str;
        default = "nonickset";
        description = "The nickname to set by default";
      };
      theme = lib.mkOption {
        type = with lib.types; nullOr package;
        default = null;
        description = "Theme to apply";
      };
    };
    home_cfg.programs.irssi = {
      enable = true;
      extraConfig = cfg.irssi.extraConfig;
      networks = {
        libera = {
          nick = cfg.irssi.default_nick;
          server = {
            address = "irc.libera.chat";
            port = 6697;
          };
        };
      };
    };
    home_cfg.home.file = lib.mkIf (!builtins.isNull cfg.irssi.theme) {
      ".irssi/startup".source = "${cfg.irssi.theme}/startup";
      ".irssi/scripts".source = "${cfg.irssi.theme}/scripts";
      ".irssi/nixos.theme".source = "${cfg.irssi.theme}/nixos.theme";
    };
  }
]

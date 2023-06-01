{ config, lib, pkgs, ... }@args:
let
  libtmux = import ../../../lib/software/tmux.nix {inherit config lib pkgs;};

  cfg = config.software.tui.tmux;
in
  {
    options.software.tui.tmux = {
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
    config = {
      environment.systemPackages = [ pkgs.tmux pkgs.tmuxp ];

      software.tui = if builtins.hasAttr "neovim" config.software.tui then {
        neovim.add_plugins = with pkgs.vimPlugins; [
          tmux-complete-vim
        ];
      } else {};


      base.home_cfg.programs = {
        bash.shellAliases = {
          quitses = "tmux kill-session -t $(tmux display-message -p \"#S\")";
        };

        tmux = {
          enable = true;
          clock24 = true;

          prefix = "M-p";
          terminal = "screen-256color";
          historyLimit = 10000;
          escapeTime = 0;
          keyMode = "vi";
          sensibleOnTop = false;
          secureSocket = true;
          plugins = with pkgs.tmuxPlugins; [
            better-mouse-mode
          ];
          tmuxp.enable = true;
          # TODO    Nixify this
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

            set -sg escape-time 0

            # Generated theme
          ''
          + (libtmux.generate_theme
              ((libtmux.default_theme (libtmux.default_vars // cfg.varsOverride))
              // cfg.themeOverride)
            )
          + cfg.extraConfig;
        };
      };
    };
  }

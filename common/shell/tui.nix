{ config, lib, pkgs, pkgs_unstable, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../../lib/utils.nix {inherit config lib pkgs;};
  libcolors = import ../../lib/colors.nix {inherit config lib pkgs;};

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

      # Custom pomodoro tool from the overlay
      pomodoro
    ];
    cfg = {
      cmn.software.tui = {
        full.enable = lib.mkDefault true;
        git.enable = lib.mkDefault true;
        helix.enable = lib.mkDefault true;
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
      youtube-dl
      yt-dlp
      termusic
      ffmpeg
      neofetch
      bat
    ];
    cfg = {
      cmn.shell.aliases = {
        music.enable = lib.mkDefault true;
      };
    };
  }

  {
    name = "helix";
    minimal.cli = true;
    parents = ["software" "tui"];
    add_pkgs = [
      pkgs_unstable.helix
    ];
    add_opts = {
      configuration = lib.mkOption {
        type = lib.types.path;
        default = libdata.get_data_path ["config" "helix" "config.toml"];
        description = "Configuration for the Helix editor";
      };

      theme = lib.mkOption {
        type = lib.types.path;
        default = libdata.get_data_path ["config" "helix" "theme.toml"];
        description = "Theme to apply to the Helix editor";
      };

      languagesdef = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Lines to add to the `languages.toml` file";
      };
    };
    # TODO    Uncomment once the config file doesn't change too much
    # home_cfg.home.file.".config/helix/config.toml".source = cfg.helix.configuration;
    # home_cfg.home.file.".config/helix/themes/nixos.toml".source = cfg.helix.theme;
    home_cfg.home.file.".config/helix/languages.toml".text = builtins.concatStringsSep "\n\n" cfg.helix.languagesdef;
  }

  {
    name = "git";
    minimal.cli = true;
    parents = [ "software" "tui" ];
    add_pkgs = [
      # TODO  IMPORTANT   Fixup
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
    add_pkgs = with pkgs; [
      irssi
    ];
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
      extraConfig = cfg.irssi.extraConfig + ''
        settings = {
          core = {
            real_name = "${cfg.irssi.default_nick}";
            nick = "${cfg.irssi.default_nick}";
          };
          "fe-common/core" = { theme = "nixos"; };
        };
        keyboard = (
          { key = "meta-e"; id = "next_window"; data = ""; },
          { key = "meta-a"; id = "previous_window"; data=""; }
        );
      '';
      networks = {
        libera = {
          nick = cfg.irssi.default_nick;
          server = {
            address = "irc.libera.chat";
            port = 6697;
          };
          autoCommands = if builtins.hasAttr "libera_${cfg.irssi.default_nick}" libdata.plain_secrets.irssi
          then [
            "/msg NickServ identify ${cfg.irssi.default_nick} ${
              libdata.plain_secrets.irssi."libera_${cfg.irssi.default_nick}"
            }"
          ] else [];
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

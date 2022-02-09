{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "server";
    add_opts = {
      headless = lib.mkOption {
        default = true;
        type = with lib.types; bool;
        description = "Wether to activate desktop environment or not";
      };
    };
    cfg = {
      commonconf.software.tui_tools.enable = true;
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
        permitRootLogin = "no";
        kbdInteractiveAuthentication = false;
      };
    } // lib.mkIf config.commonconf.server.headless { commonconf.wm.enable = false; };
  }
  {
    name = "tui_tools";
    add_pkgs = with pkgs; [
      neovim
      tmux
      tmuxp
      fzf
      ripgrep
      autojump
      htop
      irssi
      jrnl
      wkhtmltopdf
      youtube-dl
      git

      # Custom TUI tools
      litchipi.pomodoro
    ];
    cfg = {
      environment.interactiveShellInit = data_lib.load_aliases [
        "filesystem"
        "git"
        "music"
        "network"
        "nix"
        "software_wrap"
      ];
    };
    parents = [ "software" ];
  }
]

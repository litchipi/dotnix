{ config, lib, pkgs, ... }:
let 
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
  import_if = cond: pkgs: if cond then pkgs else [];
in
  build_lib.create_common_confs "software" [

  # Basic
  {
    name = "basic";
    cfg = {
      environment.systemPackages = with pkgs; [
        evince                      # PDF viewer
        gnome.nautilus              # File manager
        vlc                         # Video player
        gnome.eog                   # Image viewer
        gnome.gnome-disk-utility    # Manage disks
        gnome-usage                 # Ressources monitor
        baobab                      # Disk space monitor
        gnome.gedit                 # Notepad
        alacritty                   # Terminal
        firefox                     # Internet browser
        deluge                      # Torrent client
      ];
    };
  }

  # Infosec
  {
    name = "infosec";
    cfg = {};
  }

  # Music production
  {
    name = "music_production";
    enable_flags = [ "electro" "guitar" "score" ];
    cfg = {
      # Base
      environment.systemPackages = with pkgs; [
      ] ++

      # Electro
      import_if config.commonconf.software.music_production.electro.enable [
        lmms
        mixxx
      ] ++

      # Guitar
      import_if config.commonconf.software.music_production.guitar.enable [
        guitarix
        gxplugins-lv2
      ] ++

      # Score
      import_if config.commonconf.software.music_production.score.enable [
        musescore
      ];
    };
  }

  # TUI tools
  {
    name = "tui_tools";
    cfg = {
      environment.systemPackages = with pkgs; [
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

        # Custom TUI tools
        litchipi.pomodoro
      ];
    };
  }
]

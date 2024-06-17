{ config, lib, pkgs, pkgs_unstable, ... }: let
  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
in {
  imports = [
    ../common/wm/gnome.nix
    ../common/system/backup.nix
    ../common/system/server.nix
    ../common/system/nixcfg.nix
    ../common/system/maintenance.nix
    ../common/software/basic.nix
    ../common/software/music.nix
    ../common/software/games.nix
    ../common/software/protonvpn.nix
    ../common/software/shell/helix.nix
    ../common/software/shell/dev.nix
    ../common/software/shell/tui.nix
    ../common/software/shell/ai.nix
  ];
  config = {
    base.user = "john";
    base.email = "litchi.pi@proton.me";

    base.networking.ssh_auth_keys = [ "op@suzie" ];
    base.create_user_dirs = [ "work" "learn" ];

    environment = {
      variables.EDITOR = "hx";
      # TODO  Setup autojump
      systemPackages = with pkgs; [
        newsflash # RSS reader
        gimp-with-plugins # Image editor
        apostrophe  # Markdown editor
        shortwave # Listen Internet radio
        gnome-podcasts # Listen to podcasts
        audacity
        python310Packages.deemix
        geogebra # Math graph tool
        authenticator # 2FA TOTP app
        zenith-nvidia
        libreoffice
        deluge
        imagemagick
        mold
        jq
        gamemode
        foliate # Ebook reader
        protonmail-bridge
        evolution

        config.boot.kernelPackages.perf
        dolphin-emu
        handbrake
        vlc
        kicad-small
        protonmail-bridge
        gnome.pomodoro
      ];
    };

    services.udev.packages = with pkgs; [
      utsushi
      dolphin-emu
    ];

    users.users.${config.base.user} = {
      icon = ../data/assets/user_icons/litchipi.png;
      extraGroups = [
        "lxd"
        "vboxusers"
        "scanner"
        "lp"
      ];
    };

    base.add_fonts = let
      libdafont = import ../lib/fetchers/dafont.nix { inherit config lib pkgs; };
    in [
      pkgs.aileron
      pkgs.league-of-moveable-type
      (libdafont.package_font "vogue" "sha256-1J05Xc9l4E+ULIyojHvz+Tiadw23JyxauTjs3tgMIyA=")
      (libdafont.package_font "cinzel" "sha256-Nse+mygWb8XC7m6tRvxpiXItKL26CI/xPeCyjxyTaKk=")
      (libdafont.package_font "avenue" "sha256-17vQU7/jZHOrVDsbExTOnjGwGpyRQ5O3/xcBStjYG6o=")
      (libdafont.package_font "butler" "sha256-rOnmVSII9qhEIMIpYOAv0giwKW5lJrj+Qjdg1cs3frY=")
    ];

    networking.firewall.allowedTCPPorts = [
      # Open a bunch of ports for fun things
      4444 4445 4446 4447 4448
    ];

    # TODO  Get this in hex directly in options, then convert to rgb after
    colors.palette = {
      primary = libcolors.fromHex "#e34967";
      secondary = libcolors.fromHex "#77de81";
      tertiary = libcolors.fromHex "#a2b2f0";

      highlight = libcolors.fromHex "#DD25E9";
      dark = libcolors.fromHex "#712433";
      light = libcolors.fromHex "#F3B6C2";
      active = libcolors.fromHex "#BBEEDA";
      inactive = libcolors.fromHex "#5B5B5B";
      dimmed = libcolors.fromHex "#DFBBC2";
    };

    boot.plymouth.enable = false; #true;
    wm = {
      boot.style.plymouth.theme = "glowing"; #hexagon_2";   # TODO  Test splash screen
      autologin = true;
      cursorTheme = {
        name = "Qogir-dark";
        package = pkgs.qogir-icon-theme;
      };
      iconTheme = {
        name = "Tela-manjaro-dark";
        package = pkgs.tela-icon-theme;
      };
      gtkTheme = {
        name = "Flat-Remix-GTK-Cyan-Dark-Solid";
        package = pkgs.flat-remix-gtk;
      };
      font = {
        name = "Cantarell 11";
        package = pkgs.cantarell-fonts;
      };

      gnome.add_extensions = with pkgs.gnomeExtensions; [
        cronomix
        window-is-ready-remover
      ];
      # gnome.user_icon = libdata.get_data_path ["assets" "desktop" "user_icons" "litchi.png"];
    };

    software.tui = {
      irssi = {
        theme = pkgs.litchipi.irssitheme;
        default_nick = "stixp";
      };
      package_sets.complete = true;
    };

    base.home_cfg.programs.irssi.networks.libera.channels = {
      rust.autoJoin = true;
      nixos.autoJoin = true;
      esperanto.autoJoin = true;
    };

    software = {
      protonvpn.username = "litchipi";
      music = {
        electro = true;
        score = true;
      };
      dev.profiles = {
        rust = true;
        nix = true;
        python = true;
        c = true;
        svelte = true;
      };
    };

    networking.stevenBlackHosts.enable = true;
    
    services.blueman.enable = true;
    services.flatpak.enable = true;

    backup.base_dir = "/data/Backups/system";
    backup.services.global = {
      user = config.base.user;
      secrets = config.secrets.store.backup.sparta;
      pruneOpts = [ "-y 50" "-m 15" "-w 4" "-d 6" "-l 10" ];
      timerConfig.OnCalendar = "2/5:00:00";
      pathsFromFile = "/home/${config.base.user}/.backuplist";
      rcloneConf = config.secrets.store.backup.rclone.owncloud;
    };
    sound.enable = true;

    software.protonvpn.secrets = config.secrets.store.credentials.protonvpn;
    # TODO    Use SDDM instead of gdm ?

    services.printing = {
      enable = true;
      drivers = [ pkgs.epson-escpr ];
    };

    virtualisation = {
      # TODO  IMPORTANT  Re-enable
      # virtualbox.host.enable = true;
      lxd.enable = true;
      lxd.recommendedSysctlSettings = true;
      lxc.lxcfs.enable = true;
    };

    shix = {
      # remoteRepoUrl = "gitlab@git.orionstar.cyou:litchi.pi/shix-shells.git";
      pullBeforeEditing = false;
      pushAfterEditing = false;
    };

    hardware.bluetooth.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      package = pkgs_unstable.pipewire;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Scanners
    services.ipp-usb.enable = true;
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan pkgs.utsushi pkgs.epkowa ];
    };

    software.tui.helix.configuration.editor = {
      true-color = true;
      bufferline = "always";
      file-picker.hidden = false;
      indent-guides.character = "│";
    };
    software.tui.helix.configuration.keys = {
      select."Y" = ":clipboard-yank";
      normal=  {
        "Y" = ":clipboard-yank";
        "$" = {
          s = ":buffer-close";
          S = ":buffer-close!";
        };
      };
    };

    environment.shellAliases = {
    };
    environment.interactiveShellInit = ''
      addbackup() {
        for arg in "$@"; do
          realpath "$arg" >> /home/${config.base.user}/.backuplist
        done
      }
    '';

    # Allow to write to /etc/hosts (with admin rights)
    environment.etc.hosts.mode = "0644";

    # cleaner.enable = true;
    maintenance = {
      enable = true;
      nixStoreOptimize.enable = true;
      flatpakUpdate.enable = true;
    };
  };
}

{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
  libcachix = import ../lib/services/cachix.nix {inherit config lib pkgs;};
in {
  imports = [
    ../base/shell.nix
    ../common/wm/gnome.nix
    ../common/software/basic.nix
    ../common/software/music.nix
    ../common/software/games.nix
    ../common/software/protonvpn.nix
    ../common/software/shell/helix.nix
    ../common/software/shell/dev.nix
    ../common/software/shell/tui.nix
    ../common/software/shell/ai.nix
    ../common/services/restic.nix
    ../common/services/cachix/client.nix
    ../common/system/server.nix
    ../common/system/nixcfg.nix
  ];
  config = {
    secrets.provision_key.key = ../data/secrets/privkeys/sparta;
    base.user = "john";
    base.email = "litchi.pi@proton.me";

    base.networking.ssh_auth_keys = [ "tim@diamond" ];
    base.create_user_dirs = [ "work" "learn" ];
    base.networking.connect_wifi = [
      "SFR-a0e0"
    ];

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

    # Open a bunch of ports for fun things
    networking.firewall.allowedTCPPorts = [ 4444 4445 4446 4447 4448 ];

    colors.palette = {
      primary = libcolors.fromhex "#b967ff";
      secondary = libcolors.fromhex "#01cdfe";
      tertiary = libcolors.fromhex "#05ffa1";
      highlight = libcolors.fromhex "#DD25E9";
      dark = libcolors.fromhex "#6A3D68";
      light = libcolors.fromhex "#FBEEBF";
      active = libcolors.fromhex "#85E9FF";
      inactive = libcolors.fromhex "#85B2BC";
      dimmed = libcolors.fromhex "#AB7776";
    };

    wm = {
      boot.style.plymouth.theme = "glowing"; #hexagon_2";   # TODO  Test splash screen
      autologin = true;
      bck-img = pkgs.fetchurl {
        url = "https://wallpapershome.com/images/wallpapers/river-1920x1080-forest-sky-evening-hd-15669.jpg";
        sha256 = "sha256-/THwmWhPqf1g8l0mMd8Uh2Lt+2GWJ/TZUROAWim48kc";
      };
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

      gnome.user_icon = libdata.get_data_path ["assets" "desktop" "user_icons" "litchi.jpg"];
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

    environment = {
      variables.EDITOR = "hx";
      systemPackages = with pkgs; [
        newsflash # RSS reader
        gimp-with-plugins # Image editor
        apostrophe  # Markdown editor
        gummi
        gnome-latex
        blanket # Play relaxing sound
        shortwave # Listen Internet radio
        gnome-podcasts # Listen to podcasts
        audacity
        python310Packages.deemix
        geogebra # Math graph tool
        authenticator # 2FA TOTP app
        zenith-nvidia
      ];
    };
    
    services.blueman.enable = true;
    services.flatpak.enable = true;

    services.backup.restic.global = {
      gdrive = true;
      pruneOpts = [ "-y 50" "-m 15" "-w 4" "-d 6" "-l 10" ];
      timerConfig.OnCalendar = "2/5:00:00";
    };

    services.cachix.client = {
      servers = libcachix.set_servers [
        { fqdn = "cachix.orionstar.cyou"; }
      ];
    };

    nix.builders.remote.machines.orionstar = {
      enable = true;
      system = "x86_64-linux";
      sshUser = "nixremotebuilder";
      maxJobs = 4;
      protocol = "ssh";
      hostName = "orionstar.cyou";
      speedFactor = 10;
      supportedFeatures = [
        "kvm"
        "big-parallel"
      ];
      sshKey = config.secrets.store.services.cachix.orionstar.file;
    };

    sound.enable = true;

    software.shell.ai.token_secret = config.secrets.store.tokens.openai.file;
    # TODO    Use SDDM instead of gdm ?
  };
}

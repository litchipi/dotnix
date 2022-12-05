{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
  libcachix = import ../lib/services/cachix.nix {inherit config lib pkgs;};
in {
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

  console.font = "Monaco";

  cmn.wm = {
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
      name = "Tela-orange-dark";
      package = pkgs.tela-icon-theme;
    };
    gtkTheme = {
      name = "Flat-Remix-GTK-Orange-Dark";
      package = pkgs.flat-remix-gtk;
    };
    font = {
      name = "Cantarell 11";
      package = pkgs.cantarell-fonts;
    };
  };

  cmn.wm.gnome = {
    enable = true;
    theme = {
      name = "Zuki-shell";
      package = pkgs.zuki-themes;
      dark = true;
    };
    user_icon = libdata.get_data_path ["assets" "desktop" "user_icons" "litchi.jpg"];
  };

  cmn.software.tui.irssi = {
    theme = pkgs.litchipi.irssitheme;
    default_nick = "stixp";
  };
  base.home_cfg.programs.irssi.networks.libera.channels = {
    rust.autoJoin = true;
    nixos.autoJoin = true;
    esperanto.autoJoin = true;
  };

  cmn.software.protonvpn = {
    enable = true;
    username = "litchipi";
  };

  cmn.basic.enable = true;
  cmn.server.enable = true;
  networking.stevenBlackHosts.enable = true;

  cmn.software.musicprod.all = true;
  cmn.software.dev.basic = true;
  cmn.software.dev.system = true;

  base.full_pkgs = with pkgs; [
    # Communication
    cawbird # Twitter reader
    newsflash # RSS reader

    # Creation
    gimp-with-plugins # Image editor
    inkscape-with-extensions # Vector image editor
    shotcut   # Video editor

    # Writing
    apostrophe  # Markdown editor
    # marp # Markdown to PDF  # Insecure

    # Music
    blanket # Play relaxing sound
    shortwave # Listen Internet radio
    gnome-podcasts # Listen to podcasts

    # Other
    wike # Wikipedia reader
    gnome-recipes # Browser / create cooking recipes
    gaphor # UML modelling tool
    geogebra # Math graph tool

    # System
    authenticator # 2FA TOTP app

    # Games
    teeworlds
    mari0
    superTuxKart
  ];

  services.blueman.enable = true;
  services.flatpak.enable = true;

  cmn.services.restic.global = {
    enable = true;
    gdrive = true;
    forget_opts = [ "-y 50" "-m 15" "-w 4" "-d 6" "-l 10" ];
    timerConfig.OnCalendar = "2/5:00:00";
  };

  # TODO  Add builder nix settings
  cmn.services.cachix.client = {
    enable = true;
    servers = libcachix.set_servers [
      { fqdn = "cachix.orionstar.cyou"; }
    ];
  };
}

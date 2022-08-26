{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
in {
  base.user = "john";
  base.email = "litchi.pi@proton.me";

  base.networking.ssh_auth_keys = [ "tim" "restic_backup_ssh" ];
  base.create_user_dirs = [ "work" "learn" ];
  base.networking.connect_wifi = [
    "SFR-a0e0"
  ];

  # Open a bunch of ports for fun things
  networking.firewall.allowedTCPPorts = [ 4444 4445 4446 4447 4448 ];

  colors.palette = {
    primary = libcolors.fromhex "b967ff";
    secondary = libcolors.fromhex "01cdfe";
    tertiary = libcolors.fromhex "05ffa1";
    highlight = libcolors.fromhex "DD25E9";
    dark = libcolors.fromhex "4A1D48";
    light = libcolors.fromhex "FBEEBF";
    active = libcolors.fromhex "85E9FF";
    inactive = libcolors.fromhex "85B2BC";
    dimmed = libcolors.fromhex "AB7776";
  };

  console.font = "Monaco";

  cmn.wm = {
    boot.theme = "hexagon_2";   # TODO  Test splash screen
    autologin = true;
    bck-img = "galaxy_amongus.png";
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
    # TODO  Custom font
    # font = {
    #   name = "Cantarell 11";
    #   package = pkgs.cantarell;
    # };
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

  cmn.software.tui.irssi.theme = pkgs.litchipi.irssitheme;
  cmn.software.protonvpn = {
    enable = true;
    username = "litchipi";
  };

  cmn.basic.enable = true;
  cmn.server.enable = true;
  networking.stevenBlackHosts.enable = true;

  cmn.software.musicprod.all = true;
  cmn.software.dev.basic = true;

  cmn.remote.gogs.enable = true;
  cmn.remote.gogs.ipaddr = "185.167.99.178";

  base.full_pkgs = with pkgs; [
    # Communication
    signal-desktop
    cawbird # Twitter reader
    newsflash # RSS reader

    # Creation
    gimp-with-plugins # Image editor
    inkscape-with-extensions # Vector image editor
    shotcut   # Video editor

    # Writing
    apostrophe  # Markdown editor
    marp # Markdown to PDF

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
    blueman     # Bluetooth manager

    # Games
    teeworlds

    # Dev libraries
    openssl
    openssl.dev
  ];

  services.flatpak.enable = true;

  cmn.services.restic.to_remote = {
    gdrive.enable = true;
    resticConfig = {
      pruneOpts = [
        "--keep-weekly 4"
        "--keep-monthly 15"
        "--keep-yearly 50"
      ];
      timerConfig = {
        OnCalendar="00/4:00";
      };
    };
  };

  # TODO    Set up firefox configuration
  # TODO    Add elements in fstab to auto-mount stuff
}

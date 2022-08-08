{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in {
  base.user = "john";
  base.hostname = "sparta";
  base.email = "litchi.pi@proton.me";

  base.networking.ssh_auth_keys = [ "tim" "restic_backup_ssh" ];
  base.create_user_dirs = [ "work" "learn" ];
  base.networking.connect_wifi = [
    "SFR-a0e0"
  ];

  # Open a bunch of ports for fun things
  networking.firewall.allowedTCPPorts = [ 4444 4445 4446 4447 4448 ];

  colors.primary = {r=221; g=37; b=158;}; # #DD259E
  colors.palette = [
    {r=1; g=205; b=254;}   # 0 #01cdfe
    {r=5; g=255; b=161;}   # 1 #05ffa1
    {r=185; g=103; b=255;} # 2 #b967ff
    {r=255; g=251; b=150;} # 3 #fffb96
    {r=74; g=29; b=72;}    # 4 #4A1D48
    {r=54; g=128; b=100;}  # 5 #368064
    {r=133; g=233; b=255;} # 6 #85E9FF
    {r=171; g=119; b=118;} # 7 #AB7776
  ];

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

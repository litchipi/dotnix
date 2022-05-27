{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in {
  # TODO    Set up real password
  base.user = "john";
  base.hostname = "sparta";
  base.networking.ssh_auth_keys = [ "tim" "restic_backup_ssh" ];
  base.networking.connect_wifi = [ "nixostest" ];

  base.disks.swapsize = 16;
  installscript.nixos_config_branch = "sparta";

  cmn.wm = {
    autologin = true;
    bck-img = "galaxy_amongus.png";
    # TODO    Change cursor theme
    # cursorTheme = {
    #   name = "Elementary";
    #   package = pkgs.elementary;
    # };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtkTheme = {
      name = "Flat-Remix-GTK-Orange-Dark";
      package = pkgs.flat-remix-gtk;
    };
  };

  cmn.wm.gnome = {
    enable = true;
    # TODO    Find nice Gnome-shell theme
    theme = {
      name = "Flat-Remix-Orange-Dark-fullPanel";
      package = pkgs.flat-remix-gnome;
      dark = true;
    };
    favorite-apps = [
      "firefox.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.gedit.desktop"
      # TODO FIXME    LibreOffice writer doesn't show up (use core anyway ?)
      "libreoffice-writer.desktop"
      # TODO Add more usefull applications in shortcuts
      "signal-desktop.desktop"
    ];
    user_icon = libdata.get_data_path ["assets" "desktop" "user_icons" "litchi.jpg"];
  };

  cmn.basic.enable = true;
  cmn.server.enable = true;

  cmn.software.musicprod = {
    enable = true;
    all = true;
  };

  cmn.remote.gogs.enable = true;
  cmn.remote.gogs.ipaddr = "185.167.99.178";

  cmn.software.dev.enable = true;
  cmn.software.dev.all = true;

  base.add_pkgs = with pkgs; [
    franz
    signal-desktop

    # TODO  Add in "full" experience package
    cawbird # Twitter reader
    newsflash # RSS reader
    gimp-with-plugins # Image editor
    inkscape-with-extensions # Vector image editor
    shotcut   # Video editor
    marp # Markdown to PDF
    blanket # Play relaxing sound
    shortwave # Listen Internet radio
    gnome-podcasts # Listen to podcasts
    tangram # Web apps for desktop
    wike # Wikipedia reader
    gnome-recipes # Browser / create cooking recipes
    gaphor # UML modelling tool
    # geogebra6 # Math graph tool
    authenticator # 2FA TOTP app

    # TODO  Put games in separated common configuration
    # Games
    teeworlds
  ];

  # TODO  Install plymouth and set up custom theme

  boot.kernelPackages = pkgs.linuxPackages_zen;

  # boot.zfs.enabled = true;

  programs.seahorse.enable = true;

  # TODO  Pimp Grub theme
  #boot.loader.grub.splashImage
  #boot.loader.grub.theme
  base.secrets.encrypted_master_key = true;

  # TODO    Set up XDG directories like so:
  #   - docs
  #   - work
  #   - learn
  #   - downloads
  #   - images
  #   - videos

  # TODO    Set up automatic restic backup, with remote sync
  # TODO    Set up firefox configuration
  # TODO    Add elements in fstab to auto-mount stuff
  # TODO    Add an option to create a swap file at boot time
}

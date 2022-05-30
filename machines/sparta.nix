{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in {
  base.user = "john";
  base.hostname = "sparta";
  base.networking.ssh_auth_keys = [ "tim" "restic_backup_ssh" ];
  base.networking.connect_wifi = [
    "SFR-a0e0"
  ];

  base.disks.swapsize = 16;
  installscript.nixos_config_branch = "sparta";

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
    favorite-apps = [
      "firefox.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.gedit.desktop"
      "startcenter.desktop"  # Libreoffice
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
    geogebra # Math graph tool
    authenticator # 2FA TOTP app

    # Games
    teeworlds
  ];

  # boot.zfs.enabled = true;

  programs.seahorse.enable = true;

  # TODO  Pimp Grub theme
  #boot.loader.grub.splashImage
  #boot.loader.grub.theme
  base.secrets.encrypted_master_key = true;

  environment.etc."xdg/user-dirs.defaults".text = ''
    DESKTOP=.system/desktop
    TEMPLATES=.system/templates
    PUBLICSHARE=.system/public
    DOWNLOAD=downloads
    DOCUMENTS=docs
    MUSIC=music
    PICTURES=pics
    VIDEOS=videos
  '';

  powerManagement.cpuFreqGovernor = "performance";

  base.create_user_dirs = [ "work" "learn" ];

  console.font = "Monaco";

  # TODO    Set up automatic restic backup, with remote sync
  # TODO    Set up firefox configuration
  # TODO    Add elements in fstab to auto-mount stuff
  # TODO    Add an option to create a swap file at boot time

  cmn.hardware.efi.enable = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod"];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [ "quiet" ];
}

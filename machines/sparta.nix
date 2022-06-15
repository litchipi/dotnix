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

  colors.primary = {r=255; g=113; b=206;}; # #ff71ce
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
  networking.stevenBlackHosts.enable = true;

  cmn.software.musicprod.all = true;
  cmn.software.dev.basic = true;

  cmn.remote.gogs.enable = true;
  cmn.remote.gogs.ipaddr = "185.167.99.178";

  base.add_pkgs = with pkgs; [
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

  # TODO    Set up automatic restic backup, with remote sync
  # TODO    Set up firefox configuration
  # TODO    Add elements in fstab to auto-mount stuff
  # TODO    Add an option to create a swap file at boot time

  powerManagement.cpuFreqGovernor = "performance";

  # TODO  Move as much as possible to common configurations
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];

      # Setup keyfiles
      secrets = {
        "/crypto_keyfile.bin" = null;
      };

      # Enable swap on luks
      luks.devices."luks-d8d528de-520b-4821-b3eb-4acf42a897dd" = {
        device = "/dev/disk/by-uuid/d8d528de-520b-4821-b3eb-4acf42a897dd";
        keyFile = "/crypto_keyfile.bin";
      };

      luks.devices."luks-c1736d11-aad9-4fef-9a7c-162d038394bd".device = "/dev/disk/by-uuid/c1736d11-aad9-4fef-9a7c-162d038394bd";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/814c7052-a17e-41c1-9c49-429662e6ce9d";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/0112-A359";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/dfab04e5-1930-471b-ade2-56f9f484d197"; } ];

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  hardware.nvidia.prime = lib.mkForce {
    amdgpuBusId = "PCI:5:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}

{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in {
  base.user = "john";
  base.hostname = "sparta";

  base.secrets.encrypted_master_key = true;
  base.networking.ssh_auth_keys = [ "tim" "restic_backup_ssh" ];
  base.create_user_dirs = [ "work" "learn" ];
  base.networking.connect_wifi = [
    "SFR-a0e0"
  ];

  console.font = "Monaco";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

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

  # Enable swap on luks
  boot.initrd.luks.devices."luks-d8d528de-520b-4821-b3eb-4acf42a897dd" = {
    device = "/dev/disk/by-uuid/d8d528de-520b-4821-b3eb-4acf42a897dd";
    keyFile = "/crypto_keyfile.bin";
  };

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
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/814c7052-a17e-41c1-9c49-429662e6ce9d";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-c1736d11-aad9-4fef-9a7c-162d038394bd".device = "/dev/disk/by-uuid/c1736d11-aad9-4fef-9a7c-162d038394bd";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/0112-A359";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/dfab04e5-1930-471b-ade2-56f9f484d197"; } ];

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;


  # TODO   Remove any useless configuration from here
  services.xserver.videoDrivers = ["amdgpu" "nvidia"];
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelModules = ["amdgpu"];
  boot.kernelPackages = pkgs.linuxPackages_zen;

  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
    amdvlk
  ];

  hardware.opengl.extraPackages32 = with pkgs; [
    driversi686Linux.amdvlk
  ];

  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
  };

  environment.variables.AMD_VULKAN_ICD = "RADV";

  hardware.nvidia.prime = lib.mkForce {
    amdgpuBusId = "PCI:5:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}

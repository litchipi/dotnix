{ lib, pkgs, config, ... }: {
  base.hostname = "bertha";
  powerManagement.cpuFreqGovernor = "performance";

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl.extraPackages = with pkgs; [
    amdvlk
    vaapiVdpau
    libvdpau-va-gl
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  boot = if config.setup.is_vm then {} else {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/5c3631a8-1000-4550-8800-67ebffd08022";
      fsType = "btrfs";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/0797375e-2aca-4ab0-b643-0b3bb22cfb18";
      fsType = "xfs";
    };

  fileSystems."/storage" =
    { device = "/dev/disk/by-uuid/183f9548-f7e7-4067-9989-4bc77435d191";
      fsType = "btrfs";
    };

  fileSystems."/brain" =
    { device = "/dev/disk/by-uuid/004b8683-faa6-4d7c-bbfc-2a5a9f33d712";
      fsType = "btrfs";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/9A55-B7FB";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/def0767d-529f-4001-a316-875517f4bbd1"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

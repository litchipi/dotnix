{ lib, pkgs, config, ... }: {
  base.hostname = "sparta";

  powerManagement.cpuFreqGovernor = "performance";

  environment.shellAliases = {
    setbrightness = "${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl1 set";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl.extraPackages = with pkgs; [
    amdvlk

    vaapiVdpau
    libvdpau-va-gl
    # TODO  Place in global config ?
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = lib.mkForce {
        amdgpuBusId = "PCI:5:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      powerManagement.enable = true;
    };
  };

  base.kernel.package = pkgs.linuxPackages_zen;
  boot = if config.setup.is_vm then {} else {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
    kernelModules = [ "kvm-amd" ];
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];

      secrets = {
        "/crypto_keyfile.bin" = null;
      };

      luks.devices."luks-58202ff0-2f04-4a36-84cb-6adfa446e4cb".device = "/dev/disk/by-uuid/58202ff0-2f04-4a36-84cb-6adfa446e4cb";

      luks.devices."luks-8763aedb-7bb6-405b-b815-d585442b592c" = {
        device = "/dev/disk/by-uuid/8763aedb-7bb6-405b-b815-d585442b592c";
        keyFile = "/crypto_keyfile.bin";
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/974b3c13-3011-42b3-94be-8577a228ec84";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-uuid/3372-84AC";
      fsType = "vfat";
    };

    "/data" = {
      device = "/dev/disk/by-uuid/2d932fe0-fad7-4495-a853-e9fe0c6ec67d";
      fsType = "btrfs";
    };

    "/nix/store" = {
      device = "/dev/disk/by-uuid/4d6b8350-4f6e-4a3c-9732-5061011ffc06";
      fsType = "btrfs";
    };
  };

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
}

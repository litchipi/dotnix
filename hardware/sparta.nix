{ config, lib, pkgs, ... }: {
  # 5Gib swapfile
  base.disks.add_swapfile = 5000;

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

{ config, lib, pkgs, ...}: let
  libdata = import ../lib/manage_data.nix { inherit config pkgs lib; };
in {
  base.hostname = "suzie";
  base.kernel.package = pkgs.linuxPackages;

  # Hardware configuration auto-detected
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3a7abaa7-7754-43e5-aceb-4e16cca1677a";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/1958-1F6F";
    fsType = "vfat";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/99ac1e2d-7ed7-4aeb-9ab1-752273452da4";
    fsType = "btrfs";
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/575ed9ce-c3f8-457a-a08e-8002c03d45fb";
    fsType = "btrfs";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/dd3c0f8b-18cc-4b45-ad6f-f5283abdce56"; }
  ];

  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.enp2s0.ipv4.addresses = [
    { address = "192.168.1.163"; prefixLength = 24; }
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

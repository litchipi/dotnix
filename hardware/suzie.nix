{ config, lib, pkgs, ...}: let
  libdata = import ../lib/manage_data.nix { inherit config pkgs lib; };
in {
  base.hostname = "suzie";
  base.disks.add_swapfile = 12000;
  boot.kernel.sysctl = { "vm.swappiness" = 30;};
  base.secrets.store."suzie_storage_keyfile" = libdata.set_secret config.base.user [ "keys" "suzie" "storage" ] { group = "users"; };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/dc53b99d-2462-4c02-ad17-125306576d24";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/1107-5D03";
      fsType = "vfat";
    };

  # TODO Setup encrypted storage for suzie      -> In software config ?
  # fileSystems."/storage" = {
  #     encrypted = {
  #       enable = true;
  #       blkDev = "/dev/disk/by-uuid/ad3410d0-318b-4873-bc8d-383338303fdb";
  #       keyFile = config.base.secrets.store."suzie_storage_keyfile".dest;
  #     };
  #     fsType = "ext4";
  #     options = ["auto" "noexec" "nosuid" "rw" "nouser" "sync" ];
  #   };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/b1b95521-ba1f-4b55-8fbd-4ae25f2bf288"; }
    ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s20u6.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

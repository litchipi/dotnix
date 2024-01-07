{ config, lib, pkgs, ...}: {
  # Custom config
  base.hostname = "suzie";
  hardware.cpu.intel.updateMicrocode = true; # Disabled by default
  boot.kernelPackages = pkgs.linuxPackages_5_15; # May be useful, maybe not

  # From configuration.nix

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
  };

  # Setup keyfile
  boot.initrd.secrets = if config.setup.is_vm then {} else { "/crypto_keyfile.bin" = null; };
  boot.initrd.luks.devices."luks-e3c17769-beca-44b6-a985-2849b80f33c8".keyFile = "/crypto_keyfile.bin";

  # From hardware-configuration.nix
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.initrd.luks.devices."luks-e3c17769-beca-44b6-a985-2849b80f33c8".device = "/dev/disk/by-uuid/e3c17769-beca-44b6-a985-2849b80f33c8";


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/e3c9c581-20c4-46f1-9944-4acae130c61a";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/65B4-19E8";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/b2ef29fb-dc9a-491f-85cd-13e76f07fc83";
      fsType = "btrfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/1341450c-6017-4412-a2a0-80e8e3afc3e1"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

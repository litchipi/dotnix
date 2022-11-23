{ config, lib, pkgs, pkgs_unstable, ... }: let
  libdata = import ../lib/manage_data.nix { inherit config lib pkgs; };
in {
  base.hostname = "diamond";
  base.kernel.package = pkgs_unstable.linuxPackages_zen;

  base.add_pkgs = with pkgs; [
    intel-media-driver
  ];

  boot.kernelParams = [
    "snd_hda_intel.dmic_detect=0"
  ];

  powerManagement.cpuFreqGovernor = "performance";

  cmn.hardware.keyboard.enable = true;
  cmn.hardware.keyboard.layout = {
    name = "azerty_on_qwerty";
    languages = ["fr"];
    description = "AZERTY layout on a QWERTY keyboard";
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "ahci" "nvme" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices."luks-6b031bce-32b0-4f7d-8009-77a42900992a".device = "/dev/disk/by-uuid/6b031bce-32b0-4f7d-8009-77a42900992a";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/6c923975-2b3a-414a-868c-b63616879e0e";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/ECA8-69B3";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/75699d28-11b5-45b1-9198-f950a3469a0e"; }
    ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-a624ad88-4e0d-41de-9a49-3c0d247388c6".device = "/dev/disk/by-uuid/a624ad88-4e0d-41de-9a49-3c0d247388c6";
  boot.initrd.luks.devices."luks-a624ad88-4e0d-41de-9a49-3c0d247388c6".keyFile = "/crypto_keyfile.bin";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.video.hidpi.enable = lib.mkDefault true;
}

{ config, lib, pkgs, ... }:
let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "efi";
    parents = ["hardware"];
    assertions = [
      {
        assertion = config.cmn.hardware.efi.enable or config.cmn.hardware.legacy.enable;
        message = "Define wether EFI or Legacy boot should be used (cmn.hardware.HERE.enable = true)";
      }
    ];
    cfg = {
      boot.tmpOnTmpfs = true;
      boot.loader.efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      boot.loader.grub = {
        enable = lib.mkDefault true;
        device = "nodev";
        version = 2;
        efiSupport = true;
        enableCryptodisk = true;
      };

      fileSystems."/" =
        { device = "/dev/disk/by-label/${config.base.disks.root_part_label}";
          fsType = "ext4";
        };

      fileSystems."/boot/efi" =
        { device = "/dev/disk/by-label/boot";
          fsType = "vfat";
        };

      fileSystems."/nix/.rw-store" =
        { device = "tmpfs";
          fsType = "tmpfs";
        };

      fileSystems."/bin" =
        { device = "/usr/bin";
          fsType = "none";
          options = [ "bind" ];
        };

        swapDevices = [
          { device = "/dev/disk/by-label/swap"; }
        ];

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  }
]

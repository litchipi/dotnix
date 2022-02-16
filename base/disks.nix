{ config, lib, pkgs, ... }:
{
  options.base.disks = {
    root_part_label = lib.mkOption {
      type = lib.types.str;
      description = "Label for the root partition where the system is installed";
      default = "nixos";
    };

    disk_encryption = lib.mkOption {
      type = lib.types.bool;
      description = "Wether to encrypt the disk or not (passwd will be derived from data/secrets)";
      default = true;
    };

    add_partition = lib.mkOption {
      type = with lib.types; listOf anything;
      default = [];
      description = "Additionnal partitions to set up";
    };

    swapsize = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Size of swap partition to create (in Gib)";
    };

    use_uefi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Wether to enable UEFI or keep the Legacy boot";
    };
  };
}

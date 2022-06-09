{ config, lib, pkgs, ... }:
let
  cfg = config.base.disks;
in
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

    add_swapfile = lib.mkOption {
      type = with lib.types; nullOr int;
      default = null;
      description = "Size of the swap file to create for the system";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf config.setup.is_nixos {
      swapDevices = if builtins.isNull cfg.add_swapfile then [] else [
        { device = "/swapfile"; size = cfg.add_swapfile; }
      ];
    })
  ];
}

{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in
{
  options.base.disks = {
    disk_uuid = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the disk where to install the system";
      default = "";
    };

    root_encryption = lib.mkOption {
      type = lib.types.bool;
      description = "Wether to encrypt the root disk or not (passwd will be derived from data/secrets)";
      default = true;
    };

    swap_encryption = lib.mkOption {
      type = lib.types.bool;
      description = "Wether to encrypt the swap as well (passwd will be derived from data/secrets)";
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
  };

  config = let
    luks_pwd = libdata.try_get_disk_pwd config.base.hostname;
  in
  {
    # TODO    Generate a script from the options to set up disks
    #   Add the script in PATH to be executed inside the install ISO

    environment.systemPackages = with pkgs; [
      cryptsetup
      parted
    ];

    swapDevices = [{
      device = "/swapfile";
      size = cfg.swapsize * 1024;
    }];
  };
}

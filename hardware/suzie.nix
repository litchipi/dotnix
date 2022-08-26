{ config, lib, pkgs, ...}: let
  libdata = import ../lib/manage_data.nix { inherit config pkgs lib; };
in {
  base.hostname = "suzie";
  base.disks.add_swapfile = 8000;
  base.secrets.store."suzie_storage_keyfile" = libdata.set_secret config.base.user [ "keys" "suzie" "storage" ] { group = "users"; };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };

    "/storage" = {
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-uuid/ad3410d0-318b-4873-bc8d-383338303fdb";
        keyFile = config.base.secrets.store."suzie_storage_keyfile".dest;
      };
      fsType = "ext4";
      options = ["auto" "noexec" "nosuid" "rw" "nouser" "sync" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
  };
}

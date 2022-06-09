{ config, lib, pkgs, ... }:
let
  cfg = config.base.disks;
in
{
  options.base.disks = {
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

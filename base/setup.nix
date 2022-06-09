{config, pkgs, lib, ...}:
{
  options.setup = {
    is_nixos = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether the configuration is one of a real NixOS system or a VM / LiveUSB";
    };

    is_vm = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether to enable virtualisation config or not";
    };
  };
}

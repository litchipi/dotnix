{ config, lib, pkgs, ...}:
{
  config = {
  };

  options = {
    installscript = {
      nixos_config_repo = lib.mkOption {
        type = lib.types.str;
        default = "https://github.com/litchipi/dotnix";
        description = "Remote repository where to fetch the system config";
      };

      nixos_config_branch = lib.mkOption {
        type = lib.types.str;
        default = "main";
        description = "Branch to fetch from the remote repository";
      };

      flake_target_name = lib.mkOption {
        type = lib.types.str;
        default = config.base.hostname;
        description = "Name of the flake target to reach for NixOS install";
      };
    };
  };
}


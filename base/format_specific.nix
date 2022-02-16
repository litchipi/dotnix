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
    };
  };
}


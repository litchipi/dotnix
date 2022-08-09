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

    config_repo_path = lib.mkOption {
      type = lib.types.str;
      description = "Path of the git repository where the dotnix files are";
      default = "$HOME/dotnix";
    };
  };

  config = {
    base.home_cfg.programs.bash.shellAliases = lib.mkIf config.setup.is_nixos {
      upgrade = "sudo nixos-rebuild switch --flake ${config.setup.config_repo_path} $@ && echo 'Success'";
    };
  };
}

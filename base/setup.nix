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

    directories = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
            options = {
                path = lib.mkOption {
                    type = lib.types.str;
                    description = "Path of the directory";
                };
                owner = lib.mkOption {
                    type = lib.types.str;
                    description = "Owner of the directory";
                    default = config.base.user;
                };
                group = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    description = "Group of the directory";
                    default = null;
                };
            };
        });
        default = [];
        description = "List of directories to create, and their associated permissions";
    };
  };

  config = {
    boot.postBootCommands = lib.strings.concatStringsSep "\n" (builtins.map (dir: ''
        mkdir -p ${dir.path}
        chown -R ${dir.owner}:${if builtins.isNull dir.group then dir.owner else dir.group} ${dir.path}
    '') config.setup.directories);
    base.home_cfg.programs.bash.shellAliases = lib.mkIf config.setup.is_nixos {
      upgrade = "sudo nixos-rebuild switch --flake ${config.setup.config_repo_path} $@ && echo 'Success'";
    };
  };
}

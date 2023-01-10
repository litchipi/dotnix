{config, lib, ...}:
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

    is_ci_run = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether this build is made for CI or not";
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
                perms = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "Permissions of this directory";
                  default = null;
                };
            };
        });
        default = [];
        description = "List of directories to create, and their associated permissions";
    };
  };

  config = {
    system.activationScripts.create_setup_dirs = lib.strings.concatStringsSep "\n" (builtins.map (dir: ''
        mkdir -p ${dir.path}
        chown -R ${dir.owner}:${if builtins.isNull dir.group then dir.owner else dir.group} ${dir.path}
        ${lib.strings.optionalString (!builtins.isNull dir.perms) "chmod -R ${dir.perms} ${dir.path}"}
    '') config.setup.directories);
    environment.shellAliases = {
      upgrade = "sudo nixos-rebuild switch --flake ${config.setup.config_repo_path} $@ && echo 'Success'";
    };
  };
}

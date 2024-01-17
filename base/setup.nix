{ config, lib, ... }:
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
                user_perms = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "Permissions of this directory";
                  default = "+rwX";
                };
                group_perms = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "Permissions of this directory";
                  default = "+rwX";
                };
                other_perms = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "Permissions of this directory";
                  default = "-rwX";
                };
            };
        });
        default = [];
        description = "List of directories to create, and their associated permissions";
    };
  };

  config = {
    systemd.services.create_setup_dirs = {
      wantedBy = [ "local-fs.target" ];
      after = [ "local-fs.target" ];
      serviceConfig.Type = "oneshot";
      script = lib.strings.concatStringsSep "\n" (builtins.map (dir: ''
          mkdir -p ${dir.path}
          chown -R ${dir.owner}:${if builtins.isNull dir.group then dir.owner else dir.group} ${dir.path}
          chmod -R u${dir.user_perms},g${dir.group_perms},o${dir.other_perms} ${dir.path}
      '') config.setup.directories);
    };

    environment.shellAliases = {
      upgrade = "sudo nixos-rebuild switch --flake ${config.setup.config_repo_path}";
      build-nixos-config = "nixos-rebuild build --flake ${config.setup.config_repo_path}";
    };
  };
}

{ config, lib, pkgs, ... }: let
  cfg = config.backup;

  # TODO Have a specific type for backup service secret
  backup_service_secret = lib.types.attrs;

  backup_service = lib.types.submodule {
    options = {
      user = lib.mkOption {
        description = "User under which the backup service is run";
        type = lib.types.str;
      };
      paths = lib.mkOption {
        description = "Paths to include inside the backup";
        type = lib.types.listOf lib.types.str;
      };
      secrets = lib.mkOption {
        description = "Secrets to use for this backup service";
        type = backup_service_secret;
      };
      timerConfig = lib.mkOption {
        type = lib.types.anything;
        description = "Timer config for the systemd service";
        default = { OnCalendar = "daily"; };
      };
      pruneOpts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Options of snapshots forget";
        default = ["-y 10" "-m 12" "-w 4" "-d 30" "-l 5"];
      };
      pathsFromFile = lib.mkOption {
        type = with lib.types; nullOr path;
        description = "Get the paths to backup from a specified path";
        default = null;
      };
    };
  };

  mkBackupConfig = {
    name,
    restic_repo_path,
    user,
    paths,
    secrets,
    timerConfig,
    pruneOpts,
    pathsFromFile,
  }: {
    secrets.setup."restic_${name}" = {
      inherit user;
      secret = secrets;
    };

    setup.directories = [
      { path = restic_repo_path; perms = "750"; owner = user; }
    ];

    services.restic.backups.${name} = {
      inherit user paths pruneOpts;
      initialize = true;
      passwordFile = secrets.restic_repo_pwd.file;
      repository = restic_repo_path;
      dynamicFilesFrom = "cat ${pathsFromFile}";
      timerConfig = {
        Persistent = true;
      } // timerConfig;
    };
  };

in {
  options.backup = {
    base_dir = lib.mkOption {
      description = "Base directory where to store all backups";
      type = lib.types.str;
      default = "/var/lib/backup";
    };

    services = lib.mkOption {
      description = "Backup services to enable";
      type = lib.types.attrsOf backup_service;
      default = [];
    };
  };
  config = {
    users.groups.restic.members = lib.attrsets.mapAttrsToList (_: srv: srv.user) cfg.services;
    setup.directories = [
      {
        path = cfg.base_dir;
        perms = "770";
        owner = "root";
        group = "restic";
      }
    ];
  } // (lib.attrsets.mergeAttrsList (
    lib.attrsets.mapAttrsToList (name: cfg: mkBackupConfig {
      inherit name;
      restic_repo_path = "${config.backup.base_dir}/${name}";
      inherit (cfg) user paths secrets timerConfig pruneOpts;
    }) config.backup.services
  ));
}

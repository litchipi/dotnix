{ config, lib, pkgs, ... }: let
  libextbck = import ../../lib/external_backup.nix {inherit config lib pkgs;};
in {
  mkBackupOptions = {
    name,
    basedir,
    copy_external ? true,
  }: {
    repo_path = lib.mkOption {
      type = lib.types.str;
      description = "Path to the restic repository";
      default = "${basedir}/${name}/restic";
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
    gdrive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable saving the backup to Google Drive";
    };
  } // (if copy_external then {
    external_copy = libextbck.mkOption;
  } else {});

  mkBackupConfig = {
    name,
    cfg,
    user,
    paths,
    secrets,
    copy_external ? true,
    external_copy_add_paths ? {},
  }: {
    secrets.setup."restic_${name}" = {
      inherit user;
      secret = secrets;
    };

    setup.directories = [
      { path = cfg.repo_path; perms = "u+rwX,g+rwX,o-rwx"; owner = user; }
    ];

    services.restic.backups.${name} = {
      initialize = true;
      passwordFile = secrets.restic_repo_pwd.file;
      repository = cfg.repo_path;
      timerConfig = {
        Persistent = true;
      } // cfg.timerConfig;
      pruneOpts = cfg.pruneOpts;
      inherit user paths;
    };
  } // (if copy_external then {
    fileSystems = libextbck.mkFileSystems cfg.external_copy;

    systemd.services = libextbck.mkSystemdService cfg.external_copy {
      basename = "restic_${name}_backup";
      bind = "restic-backups-${name}.service";
      paths = {
        ${cfg.repo_path} = "${config.base.hostname}/${name}";
      } // external_copy_add_paths;
    } // (libextbck.mkGdriveBckService {
      enabled = cfg.gdrive;
      basename = "restic_${name}_backup";
      bind = "restic-backups-${name}.service";
      rclone_conf = secrets.rclone_gdrive.file;
      paths.${cfg.repo_path} = "${config.base.hostname}_${name}_backup";
    });
  } else {});
}

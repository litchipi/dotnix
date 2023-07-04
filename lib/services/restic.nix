{ config, lib, pkgs, ... }: let
  libextbk = import ../../lib/external_backup.nix {inherit config lib pkgs;};
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
    external_copy = libextbk.mkOption;
  } else {});

  mkBackupConfig = {
    name,
    cfg,
    user,
    paths,
    secrets,
    copy_external ? true,
    external_copy_add_paths ? {},
  }: let
    rsecrets = pkgs.secrets.set_common_config {
      enable = true;
      inherit user;
    } secrets;
  in {
    setup.directories = [
      { path = cfg.repo_path; perms = "750"; owner = user; }
    ];

    services.restic.backups.${name} = {
      initialize = true;
      passwordFile = rsecrets.restic_repo_pwd.file;
      repository = cfg.repo_path;
      timerConfig = {
        Persistent = true;
      } // cfg.timerConfig;
      pruneOpts = cfg.pruneOpts;
      inherit user paths;
    };
  } // (if copy_external then {
    fileSystems = libextbk.mkFileSystems cfg.external_copy;

    systemd.services = libextbk.mkSystemdService cfg.external_copy {
      basename = "restic_${name}_backup";
      bind = "restic-backups-${name}.service";
      paths = {
        ${cfg.repo_path} = "${config.base.hostname}/${name}";
      } // external_copy_add_paths;
    } // (libextbk.mkGdriveBckService {
      enabled = cfg.gdrive;
      basename = "restic_${name}_backup";
      bind = "restic-backups-${name}.service";
      rclone_conf = rsecrets.rclone_gdrive.file;
      paths.${cfg.repo_path} = "${config.base.hostname}_${name}_backup";
    });
  } else {});
}

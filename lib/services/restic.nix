{ config, lib, pkgs, ... }: let
  libextbk = import ../../lib/external_backup.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
in {
  mkBackupOptions = {
    name,
    copy_external ? true,
  }: {
    repo_path = lib.mkOption {
      type = lib.types.str;
      description = "Path to the restic repository";
      default = "/var/backup/${name}";
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
    base_secrets_path ? [ "services" name config.base.hostname ],
    copy_external ? true,
    external_copy_add_paths ? {},
  }: {
    setup.directories = [
      { path = cfg.repo_path; perms = "700"; owner = user; }
    ];

    base.secrets.store = let
      mkSecret = sec: libdata.set_secret {
        inherit user;
        path = base_secrets_path ++ [ sec ];
      };
    in {
      "${name}_restic_repo_pwd" = mkSecret "restic_repo_pwd";
    } // (if !cfg.gdrive then {} else {
      "${name}_rclone_conf" = mkSecret "gdrive.conf";
    });

    services.restic.backups.${name} = {
      initialize = true;
      passwordFile = config.base.secrets.store."${name}_restic_repo_pwd".dest;
      repository = cfg.repo_path;
      timerConfig = {
        Persistent = true;
      } // cfg.timerConfig;
      pruneOpts = cfg.pruneOpts;
      inherit user;
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
      rclone_conf = config.base.secrets.store."${name}_rclone_conf".dest;
      paths.${cfg.repo_path} = "${config.base.hostname}_${name}_backup";
    });
  } else {});
}

{ config, lib, pkgs, ... }: let
  cfg = config.backup;

  # TODO Have a specific type for backup service secret
  backup_service_secret = lib.types.attrs;

  backup_service = lib.types.submodule {
    options = {
      gdrive = lib.mkEnableOption { description = "Upload the backup to Google drive"; };
      user = lib.mkOption {
        description = "User under which the backup service is run";
        type = lib.types.str;
      };
      paths = lib.mkOption {
        description = "Paths to include inside the backup";
        type = lib.types.listOf lib.types.str;
        default = [];
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

  mkGdriveBckService = {bind, paths, rclone_conf }: {
    after = [ bind ];
    wantedBy = [ bind ];
    serviceConfig.PrivateTmp = true;
    script = let
      rclone = "${pkgs.rclone}/bin/rclone -q --config /tmp/gdrive.conf";
      srm = "${pkgs.srm}/bin/srm";
    in ''
      cp ${rclone_conf} /tmp/gdrive.conf
      chmod 700 /tmp/gdrive.conf
    '' + (builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (from: to: ''
      ${rclone} sync ${from} dotnix:${to}
    '') paths)) + ''
      ${srm} /tmp/gdrive.conf
    '';
  };

  mkBackupConfig = {
    name,
    restic_repo_path,
    bck_cfg,
  }: {
    secrets.setup."restic_${name}" = {
      inherit (bck_cfg) user;
      secret = bck_cfg.secrets;
    };

    setup.directories = [
      { path = restic_repo_path; owner = bck_cfg.user; }
    ];

    services.restic.backups.${name} = {
      inherit (bck_cfg) user paths pruneOpts;
      initialize = true;
      passwordFile = bck_cfg.secrets.restic_repo_pwd.file;
      repository = restic_repo_path;
      dynamicFilesFrom = lib.strings.optionalString (!builtins.isNull bck_cfg.pathsFromFile) "cat ${bck_cfg.pathsFromFile}";
      timerConfig = {
        Persistent = true;
      } // bck_cfg.timerConfig;
    };

    systemd.services."rclone-${name}-backup" = if bck_cfg.gdrive then (mkGdriveBckService {
      bind = "restic-backups-${name}.service";
      rclone_conf = bck_cfg.secrets.rclone_conf.file;
      paths.${restic_repo_path} = "${config.base.hostname}_${name}_backup";
    }) else {};
  };

  mergeRecursAttrs = builtins.foldl' (acc: x: lib.attrsets.recursiveUpdate acc x) {}; 
  
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
      default = {};
    };
  };

  config = let 
    all_services_lst = lib.attrsets.mapAttrsToList (name: bck_cfg: mkBackupConfig {
      inherit name bck_cfg;
      restic_repo_path = "${config.backup.base_dir}/${name}";
    }) cfg.services;
    all_services =  mergeRecursAttrs all_services_lst;
  in {
    users.groups.restic.members = lib.attrsets.mapAttrsToList (_: srv: srv.user) cfg.services;
    setup.directories = [
      {
        path = cfg.base_dir;
        owner = "root";
        group = "restic";
      }
    ] ++ (all_services.setup.directories or []);
    services.restic = all_services.services.restic or {};
    secrets.setup = all_services.secrets.setup or {};
    systemd.services = all_services.systemd.services or {};
  };
}

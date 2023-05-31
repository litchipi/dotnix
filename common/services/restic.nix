{ config, lib, pkgs, ... }:
let
  libextbk= import ../../lib/external_backup.nix {inherit config lib pkgs;};
  libbck = import ../../lib/services/restic.nix {inherit config lib pkgs;};

  cfg = config.services.backup.restic.global;
in
  {
    options.services.backup.restic.global = with lib.types; (libbck.mkBackupOptions {
      name = "global";
      basedir = cfg.basedir;
    }) // {
      groups = lib.mkOption {
        type = listOf str;
        default = [];
        description = "Groups to add the backup user to";
      };
      prepare_script = lib.mkOption {
        type = listOf str;
        default = [];
        description = "Scripts to execute before the backup process";
      };
      cleanup_script = lib.mkOption {
        type = listOf str;
        default = [];
        description = "Scripts to execute after the backup process";
      };
      basedir = lib.mkOption {
        type = str;
        description = "Path where everything related to backup is contained";
        default = "/var/backup";
      };
      lists_basedir = lib.mkOption {
        type = str;
        description = "Path where to store the backup lists";
        default = "${cfg.basedir}/global/lists";
      };
      backup_paths = lib.mkOption {
        type = listOf str;
        description = "Paths to backup on the repository";
        default = [];
      };
      external_copy = libextbk.mkOption;
    };

    config = let
      dynamicFilesListPath = "${cfg.lists_basedir}/${config.base.user}_list";
    in lib.attrsets.recursiveUpdate (libbck.mkBackupConfig {
      name = "global";
      cfg = config.services.backup.restic.global;
      paths = cfg.global.backup_paths;
      user = config.base.user;
      external_copy_add_paths = {
        ${cfg.lists_basedir} = "${config.base.hostname}/global/lists";
      };
      secrets = config.secrets.store.services.restic.sparta;
    }) {
      setup.directories = [
        {
          path = cfg.basedir;
          perms = "750";
          owner = config.base.user;
          group = config.base.user;
        }
      ];

      services.restic.backups.global = {
        extraBackupArgs = "--files-from ${dynamicFilesListPath}";
        backupPrepareCommand = builtins.concatStringsSep "\n" cfg.prepare_script;
        backupCleanupCommand = builtins.concatStringsSep "\n" cfg.cleanup_script;
      };

      environment.shellAliases = let
        service_name = "restic-backups-global.service";
      in {
        forcebackup = "sudo systemctl start ${service_name}";
        lastbackup = "systemctl status ${service_name}|grep 'since'|awk -F \"since \" '{print $2}'";
      };

      environment.interactiveShellInit= ''
        addbackup() {
          for file in $@; do
            touch ${dynamicFilesListPath}
            fname=$(realpath $file)
            if ! grep "$fname" ${dynamicFilesListPath} > /dev/null; then
              echo "$fname" >> ${dynamicFilesListPath}
            fi
          done
        }
      '';
    };
  }

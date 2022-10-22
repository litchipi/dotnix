{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.restic;
  service_name = "restic_backup_from_remote";
  restic_secret = name: libdata.set_secret {
    user = "restic"; 
    path = ["services" "restic" config.base.hostname name];
  };

  # TODO Add option to copy the backup made to different locations
  target_type = lib.types.submodule {
    options = {
      user = lib.mkOption {
        type = lib.types.str;
        description = "User onto SSHFS connects for backup";
        default = null;
      };
      host = lib.mkOption {
        type = lib.types.str;
        description = "How onto SSHFS connects for backup";
        default = null;
      };
      ssh_host_key = lib.mkOption {
        type = lib.types.str;
        description = "SSH key found in /etc/ssh/ssh_host*.key, used to establish SSH connection";
        default = null;
      };
      remote_dirs_backup = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Path to backup from the remote server";
        default = [];
      };
      # https://www.freedesktop.org/software/systemd/man/systemd.time.html
      backup_timer = lib.mkOption {
        type = lib.types.str;
        description = "Timer configuration to launch the backup process";
        default = "*:0/1";
      };
    };
  };

  create_systemd_service = name: target: let
    fname_host = builtins.replaceStrings ["." "-"] ["_" "_"] target.host;
    tmpdir = "/tmp/${fname_host}";
    sshfs_options = "-oIdentityFile=$(realpath ${config.base.secrets.store.restic_ssh_privk.dest}) -oStrictHostKeyChecking=yes";
  in { 
    "${service_name}_${fname_host}" = {
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        startAt = target.backup_timer;
        path = with pkgs; [
          restic
          sshfs
          umount
        ];
        script = let
        in ''
          mkdir -p ${tmpdir}
          cd ${tmpdir}
        '' + (builtins.concatStringsSep "\n" (builtins.map (remote_dir: ''
          mkdir -p ./${remote_dir}
          sshfs ${target.user}@${target.host}:${remote_dir} ./${remote_dir} ${sshfs_options}
          restic backup -q -p ${config.base.secrets.restic_repo_pwd.dest} -r ${cfg.restic_repo_dir} ./${remote_dir}
          umount ./${remote_dir}
        '') target.remote_dirs_backup)) + ''
          cd /
          rm -rf ${tmpdir}
          chown -R ${config.base.user}:${service_name} ${cfg.restic_repo_dir}
        '';
      };
    };

in
libconf.create_common_confs [
  {
    name = "from_remote";
    parents = [ "services" "restic" ];

    add_opts = {
      restic_repo_dir = lib.mkOption {
        type = lib.types.str;
        description = "Path of the restic repository for backup";
        default = "/var/resticbck";
      };
      targets = lib.mkOption {
        type = with lib.types; attrsOf target_type;
        description = "Targets from which the data will be saved";
        default = [];
      };
    };

    add_pkgs = with pkgs; [
      restic
    ];
    cfg = {
      base.secrets.store = {
        restic_ssh_privk = restic_secret "ssh_privk";
        restic_repo_pwd = restic_secret "repo_pwd";
      };

      environment.shellAliases = {
        rbck = "${pkgs.restic}/bin/restic -p ${config.base.secrets.restic_repo_pwd.dest} -r ${cfg.restic_repo_dir}";
      };

      base.extraGroups = [ service_name ];

      programs.ssh.knownHosts = builtins.mapAttrs (_: target:
        {
          extraHostNames = [ target.host ];
          publicKey = target.ssh_host_key;
        }
      ) cfg.targets;

      boot.postBootCommands = ''
        if [ ! -f ${cfg.restic_repo_dir}/config ]; then
          ${pkgs.restic}/bin/restic init -q -p ${config.base.secrets.store.restic_repo_pwd.dest} -r ${cfg.restic_repo_dir}
        fi
        chown -R ${config.base.user}:${service_name} ${cfg.restic_repo_dir}
      '';

      systemd.services = lib.mkMerge (lib.attrsets.mapAttrsToList create_systemd_service cfg.targets);
    };
  }

  {
    name = "global";
    parents = ["services" "restic"];
    add_opts = with lib.types; {
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
      timerConfig = lib.mkOption {
        type = attrsOf anything;
        description = "Timer configuration to set for the backup";
        default = { OnCalendar = "daily"; };
      };
      gdrive = lib.mkOption {
        type = bool;
        description = "Wether to enable google drive remote backup";
        default = false;
      };
      repo_path = lib.mkOption {
        type = str;
        description = "Path to the restic repository";
        default = "/var/backup/global/restic";
      };
      lists_basedir = lib.mkOption {
        type = str;
        description = "Path where to store the backup lists";
        default = "/var/backup/global/lists";
      };
      backup_paths = lib.mkOption {
        type = listOf str;
        description = "Paths to backup on the repository";
        default = [];
      };
      forget_opts = lib.mkOption {
        type = listOf str;
        description = "Options of snapshots forget";
        default = ["-y 10" "-m 12" "-w 4" "-d 30" "-l 5"];
      };
    };
    cfg = let
      dynamicFilesListPath = "${cfg.global.lists_basedir}/${config.base.user}_list";
    in {
      users.extraUsers.restic = {
        isSystemUser = true;
        extraGroups = cfg.global.groups;
        group = "restic";
      };
    users.extraGroups = { restic = {}; };
      base.secrets.store.restic_global_backup_repo_pwd = restic_secret "password";
      base.secrets.store.restic_global_backup_gdrive_conf = lib.mkIf cfg.global.gdrive (restic_secret "gdrive.conf");

      setup.directories = [
        { path = cfg.global.repo_path; perms = "700"; owner = "root"; }
        { path = cfg.global.lists_basedir; perms = "700"; owner = config.base.user; }
      ];
      services.restic.backups.global = {
        initialize = true;
        dynamicFilesFrom = ''
          cat ${dynamicFilesListPath}
        '';
        passwordFile = config.base.secrets.store.restic_global_backup_repo_pwd.dest;
        repository = cfg.global.repo_path;
        timerConfig = {
          Persistent = true;
        } // cfg.global.timerConfig;
        pruneOpts = cfg.global.forget_opts;
        paths = cfg.global.backup_paths;
        backupPrepareCommand = builtins.concatStringsSep "\n" cfg.global.prepare_script;
        backupCleanupCommand = (builtins.concatStringsSep "\n" cfg.global.cleanup_script) + (
          if cfg.global.gdrive then let
            rclone = "${pkgs.rclone}/bin/rclone -q --config /tmp/rclone_global/gdrive.conf";
          in ''
            mkdir -p /tmp/rclone_global
            cp ${config.base.secrets.store.restic_global_backup_gdrive_conf.dest} /tmp/rclone_global/gdrive.conf
            chmod 700 -R /tmp/rclone_global
            ${rclone} sync ${cfg.global.repo_path} gdrive:${config.base.hostname}_global_backup
            rm -r /tmp/rclone_global
          ''
          else ""
        );
      };
      environment.shellAliases = let
        service_name = "restic-backups-${config.base.hostname}.service";
      in {
        forcebackup = "sudo systemctl start ${service_name}";
        lastbackup = "systemctl status ${service_name}|grep 'since'|awk -F \"since \" '{print $2}'";
      };
      environment.interactiveShellInit= ''
        addbackup() {
          for file in $@; do
            fname=$(realpath $file)
            touch ${dynamicFilesListPath}
            if ! grep "$fname" ${dynamicFilesListPath} > /dev/null; then
              echo "$fname" >> ${dynamicFilesListPath}
            fi
          done
        }
      '';
    };
  }
]

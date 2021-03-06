{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.restic;
  service_name = "restic_backup_from_remote";
  restic_secret = name: libdata.set_secret "root"
    ["services" "restic" config.base.hostname name] {};

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

    home_cfg.programs.bash = {
      enable = true;
      shellAliases = {
        rbck = "${pkgs.restic}/bin/restic -p ${config.base.secrets.restic_repo_pwd.dest} -r ${cfg.restic_repo_dir}";
      };
    };

    cfg = {
      base.secrets.store = {
        restic_ssh_privk = restic_secret "ssh_privk";
        restic_repo_pwd = restic_secret "repo_pwd";
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
    name = "to_remote";
    parents = [ "services" "restic" ];
    add_opts = {
      resticConfig = lib.mkOption {
        type = lib.types.attrs;
        description = "Attrset of options to pass to the restic service";
        default = {};
      };

      pathsFromFile = lib.mkOption {
        type = lib.types.str;
        description = "File to read to get the paths to save";
        default = "/home/${config.base.user}/.backup_paths";
      };
    };
    home_cfg.programs.bash.shellAliases = let
      service_name = "restic-backups-${config.base.hostname}.service";
    in {
      forcebackup = "sudo systemctl start ${service_name}";
      lastbackup = "systemctl status ${service_name}|grep 'since'|awk -F \"since \" '{print $2}'";
    };
    home_cfg.programs.bash.initExtra = ''
      function addbackup() {
        fname=$(realpath $1)
        echo "$fname" >> /home/${config.base.user}/.backup_paths
      }
    '';
    cfg = {
      base.secrets.store.restic_password = restic_secret "password";
      services.restic.backups.${config.base.hostname} = {
        initialize = true;
        dynamicFilesFrom = "cat ${cfg.to_remote.pathsFromFile}";
        passwordFile = config.base.secrets.store.restic_password.dest;
        timerConfig.OnCalendar = "daily";
      } // cfg.to_remote.resticConfig;
    };
  }

  # TODO  Create shell alias "gdrive_mnt_lastsnp" to mount the last snapshot
  {
    name = "gdrive";
    parents = ["services" "restic" "to_remote"];
    cfg = {
      cmn.services.restic.to_remote.enable = true;
      base.secrets.store.restic_rclone_conf = restic_secret "gdrive.conf";
      services.restic.backups.${config.base.hostname} = {
        rcloneOptions = {
          drive-use-trash = "false";
        };
        rcloneConfigFile = config.base.secrets.store.restic_rclone_conf.dest;
        repository = "rclone:gdrive:restic/";
      };
    };
  }
]

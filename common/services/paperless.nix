{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libextbk = import ../../lib/external_backup.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.paperless;
  fqdn = "paper.${config.base.networking.domain}";
in
libconf.create_common_confs [
  {
    name = "paperless";
    parents = [ "services" ];
    add_opts.backup = {
      repo_path = lib.mkOption {
        type = lib.types.str;
        description = "Path to the restic repository";
        default = "/var/backup/paperless";
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
      external_copy = libextbk.mkOption;
    };
    cfg = {
      setup.directories = [
        { path = cfg.backup.repo_path; perms = "700"; owner = config.services.paperless.user; }
      ];

      base.secrets.store = let
        paperless_secret = name: libdata.set_secret {
          user = config.services.paperless.user;
          path = [ "services" "paperless" config.base.hostname name ];
        };
      in {
        paperless_admin_pwd = paperless_secret "admin_pwd";
        paperless_restic_repo_pwd = paperless_secret "restic_repo_pwd";
      } // (if !cfg.backup.gdrive then {} else {
        paperless_rclone_conf = paperless_secret "gdrive.conf";
      });

      services.paperless = {
        enable = true;
        dataDir = "/var/paperless";
        passwordFile = config.base.secrets.store.paperless_admin_pwd.dest;
      };

      services.nginx = {
        enable = true;
        virtualHosts.${fqdn}.locations."/".proxyPass =
          "http://${config.services.paperless.address}:${builtins.toString config.services.paperless.port}";
      };

      services.restic.backups.paperless = {
        initialize = true;
        passwordFile = config.base.secrets.store.paperless_restic_repo_pwd.dest;
        repository = cfg.backup.repo_path;
        timerConfig = {
          Persistent = true;
        } // cfg.backup.timerConfig;
        pruneOpts = cfg.backup.pruneOpts;
        user = config.services.paperless.user;
        paths = [ config.services.paperless.dataDir ];
      };

      fileSystems = libextbk.mkFileSystems cfg.backup.external_copy;
      systemd.services = libextbk.mkSystemdService cfg.backup.external_copy {
        basename = "restic_paperless_backup";
        bind = "restic-backups-paperless.service";
        paths.${cfg.backup.repo_path} = "${config.base.hostname}/paperless";
      } // (libextbk.mkGdriveBckService {
        enabled = cfg.backup.gdrive;
        basename = "restic_paperless_backup";
        bind = "restic-backups-paperless.service";
        rclone_conf = config.base.secrets.store.paperless_rclone_conf.dest;
        paths.${cfg.backup.repo_path} = "${config.base.hostname}_paperless_backup";
      });
    };
  }
]

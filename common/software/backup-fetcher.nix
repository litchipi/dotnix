{ config, lib, pkgs, ... }: let
  cfg = config.services.backup-fetcher;

  backup_service = lib.types.submodule {
    options = {
      runtimeDeps = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "List of packages required for the scripts to run";
        default = [];
      };

      outputFile = lib.mkOption {
        type = lib.types.path;
        description = "Directory where to store the resulting ZIP file";
      };

      sshTarget = lib.mkOption {
        type = lib.types.str;
        description = "Domain or IP to fetch the backup from using SCP";
      };

      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of files to fetch from remote target, wildcard allowed";
        default = [];
      };

      timerConfig = lib.mkOption {
        type = lib.types.anything;
        description = "Timer config for the systemd service";
        default = { OnCalendar = "daily"; };
      };

      exitTargetScript = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Script to execute on target after everything has been fetched";
        default = null;
      };

      beforeCompressScript = lib.mkOption {
        type = lib.types.str;
        description = "Script to execute before compressing the resulting files";
        default = "";
      };

      identityFile = lib.mkOption {
        type = lib.types.path;
        description = "Path of the SSH identity file to use for connection";
        default = "/home/${config.base.user}/.ssh/id_rsa";
      };

      outfileOwner = lib.mkOption {
        type = lib.types.str;
        description = "User owning the output file";
        default = config.base.user;
      };

      outfilePerms = lib.mkOption {
        type = lib.types.str;
        description = "Permissions to apply to the file";
        default = "660";
      };
    };
  };

  mkScript = opts: let
    all_files = builtins.concatStringsSep " " opts.paths;
    ssh_opts = "-i ${opts.identityFile} -o StrictHostKeyChecking=no";
  in ''
    set -ex
    OUTDIR=$(mktemp -d)
    scp ${ssh_opts} -OT -r ${opts.sshTarget}:"${all_files}" "$OUTDIR/"
    cd "$OUTDIR"
    set +x

    ${opts.beforeCompressScript}

    set -x
    zip "${opts.outputFile}" -9 -v -T -r .
    chown ${opts.outfileOwner} ${opts.outputFile}
    chmod ${opts.outfilePerms} ${opts.outputFile}
  '' + (lib.strings.optionalString (!builtins.isNull opts.exitTargetScript) ''
    ssh -i ${opts.identityFile} ${opts.sshTarget} << 'ENDSSH'
    ${opts.exitTargetScript}
    ENDSSH
  '');

in {
  options.services.backup-fetcher = {
    enable = lib.mkEnableOption { description = "Enable backup fetchers service"; };
    fetchers = lib.mkOption {
      type = lib.types.attrsOf backup_service;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    # assertions = mapAttrsToList (name: opts: {
    #  assertion = TODO;
    #  message = TODO;
    # }) cfg.fetchers;

    systemd.timers = builtins.mapAttrs (_: opts: {
      wantedBy = [ "timers.target" ];
      inherit (opts) timerConfig;
    }) cfg.fetchers;

    systemd.services = lib.attrsets.mapAttrs' (name: opts: {
      name = "fetch-backup-${name}";
      value = {
        description = "Backup fetcher ${name}";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ pkgs.openssh_hpn pkgs.zip pkgs.unzip ] ++ opts.runtimeDeps;

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "fetch-backup-${name}" (mkScript opts);
          PrivateTmp = true;
        };
      };
    }) cfg.fetchers;
  };
}


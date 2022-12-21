{ lib, pkgs, ... }: let

  mkMntPt = dev: opt: if builtins.isNull opt.mount_point
    then "/backup/${dev}"
    else opt.mount_point;

  extDeviceType = lib.types.submodule {
    options = {
      mount_point = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Where to mount this device";
        default = null;
      };
      device = lib.mkOption {
        type = lib.types.str;
        description = "Which device to use";
      };
      fsType = lib.mkOption {
        type = lib.types.str;
        description = "Which filesystem this device uses";
      };
      mnt_flags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["noexec"];
        description = "Mount flags on the device";
      };
    };
  };
in
  {
    mkOption = lib.mkOption {
      type = with lib.types; attrsOf extDeviceType;
      default = {};
      description = "External devices to backup into";
    };

    mkFileSystems = ext: lib.attrsets.mapAttrs' (dev: opt: let
      mnt = mkMntPt dev opt;
    in {
      name = mnt;
      value = lib.mkDefault {
        inherit (opt) device fsType;
        options = opt.mnt_flags ++ ["nofail"];
      };
    }) ext;

    mkSystemdService = ext: { basename, bind, paths }: lib.attrsets.mapAttrs' (dev: opt: {
      name = "${basename}_${dev}";
      value = {
        after = [ bind ];
        wantedBy = [ bind ];
        script = let
          mnt = mkMntPt dev opt;
        in ''
          if [ ! -b ${opt.device} ]; then
            echo "Device ${opt.device} not connected"
            exit 1;
          fi
          if [ ! -d ${mnt} ]; then
            echo "Device ${opt.device} not mounted"
            exit 1;
          fi

        '' + (builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (from: to: ''
            mkdir -p $(dirname ${mnt}/${to})
            ${pkgs.rsync}/bin/rsync -a -r ${from}/ ${mnt}/${to}
        '') paths));
      };
    }) ext;

    mkGdriveBckService = {basename, enabled, bind, paths, rclone_conf }: {
      "${basename}_rclone_gdrive" = lib.mkIf enabled {
        after = [ bind ];
        wantedBy = [ bind ];
        script = let
          rclone = "${pkgs.rclone}/bin/rclone -q --config /tmp/rclone_global/gdrive.conf";
          srm = "${pkgs.srm}/bin/srm";
        in ''
          mkdir -p /tmp/rclone_global
          cp ${rclone_conf} /tmp/rclone_global/gdrive.conf
          chmod 700 -R /tmp/rclone_global
        '' + (builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (from: to: ''
          ${rclone} sync ${from} gdrive:${to}
        '') paths)) + ''
          ${srm} -r /tmp/rclone_global
        '';
      };
    };
  }

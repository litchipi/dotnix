{ config, lib, pkgs, ...}:

# TODO Replace with nixpkgs version once PR is merged

let
  cfg = config.services.ifm;

  version = "4.0.2";
  src = pkgs.fetchurl {
    url = "https://github.com/misterunknown/ifm/releases/download/v${version}/cdn.ifm.php";
    sha256 = "sha256-37WbRM6D7JGmd//06zMhxMGIh8ioY8vRUmxX4OHgqBE=";
  };

  php = pkgs.php83;
in {
  imports = [ ../system/backup.nix ];

  options.services.ifm = {
    enable = lib.mkEnableOption "Improved file manager, a single-file web-based filemanager";

    backup = lib.mkEnableOption {
      description = "Enable the backup service for IFM";
    };
    secrets = pkgs.secrets.mkSecretOption "Secrets for IFM";

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory to serve throught the file managing service";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address on which the service is listening";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Port on which to serve the IFM service";
    };

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
      description = ''
        Configuration of the IFM service.

        See [the documentation](https://github.com/misterunknown/ifm/wiki/Configuration)
        for available options and default values.
      '';
      example = {
        IFM_GUI_SHOWPATH = 0;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    users.users.ifm = {
      isNormalUser = true;
    };
    users.groups.ifm = {};

    secrets.setup.ifm = {
      user = "ifm";
      secret = cfg.secrets;
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      ifm = {
        user = "ifm";
        inherit (cfg) secrets;
        paths = [ cfg.dataDir ];
      };
    };

    systemd.services.ifm = {
      description = "Improved file manager, a single-file web based filemanager";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        IFM_ROOT_DIR = "/data";
      } // (builtins.mapAttrs (_: val: toString val) cfg.settings);

      serviceConfig = {
        DynamicUser = true;
        User = "ifm";
        ExecStartPre = pkgs.writeShellScript "init-ifm" ''
          mkdir -p /tmp/ifm
          ln -s ${src} /tmp/ifm/index.php
        '';
        ExecStart = "${lib.getExe php} -S ${cfg.listenAddress}:${builtins.toString cfg.port} -t /tmp/ifm";
        StandardOutput = "journal";
        BindPaths = "${cfg.dataDir}:/data";
      };
    };
  };
}

{ config, lib, pkgs, ... }:
let
  libssh = import ../../lib/ssh.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.nix;

  remote_builder_type = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption { description = "Enable the builder"; };
      system = lib.mkOption {
        description = "System of the remote builder";
        type = lib.types.str;
      };
      sshUser = lib.mkOption {
        description = "User to connect to when performing SSH connection";
        type = lib.types.str;
      };
      maxJobs = lib.mkOption {
        description = "Max jobs that the remote builder is able to take over";
        type = lib.types.int;
      };
      protocol = lib.mkOption {
        description = "Protocol to use for the connection to the remote builder";
        type = lib.types.str;
      };
      hostName = lib.mkOption {
        description = "Hostname of the remote machine to connect to";
        type = lib.types.str;
      };
      speedFactor = lib.mkOption {
        description = "Number indicating how fast is the remote builder";
        type = lib.types.int;
        default = 1;
      };
      supportedFeatures = lib.mkOption {
        description = "Features supported by the remote builder";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      mandatoryFeatures = lib.mkOption {
        description = "Features that has to be enabled in order to use the remote builder";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      sshKey = lib.mkOption {
        description = "Path to the SSH key to use to connect to the remote builder";
        type = lib.types.str;
      };
    };
  };
in
  {
    options.nix = {
      ecospace = {
        gc-enable = lib.mkEnableOption { description = "Enable the auto garbage collection"; };
        # minfree = lib.mkOption {
        #   type = lib.types.int;
        #   description = "Triggers cleaning when there's less than X MiB space left";
        #   default = 256;
        # };
        # maxfree = lib.mkOption {
        #   type = lib.types.int;
        #   description = "To which limit we clean when minfree is triggered (in MiB)";
        #   default = 1024;
        # };
        olderthan = lib.mkOption {
          type = lib.types.str;
          description = "Auto delete nix store elements older than X";
          default = "7d";
        };
        freq = lib.mkOption {
          type = lib.types.str;
          description = "Frequency to collect garbages in nix store";
          default = "daily";
        };
      };

      builders = {
        remote.machines = lib.mkOption {
          type = lib.types.attrsOf remote_builder_type;
          description = "Attrsets of machine definition";
        };
        local = {
          enable = lib.mkEnableOption {
            description = "Wether to enable locally a builder for others to connect into";
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the builder";
          };
          configuration = lib.mkOption {
            type = remote_builder_type;
            description = "Configuration to set on the builder";
          };
        };
      };
    };
    config = {
      nix = {
        settings = {
          auto-optimise-store = true;
          # gc-keep-output = true;
          # gc-keep-derivations = true;
          trusted-users = if cfg.builders.local.enable
            then [ cfg.builders.local.configuration.sshUser ]
            else [];
        };
        gc = lib.mkIf cfg.ecospace.gc-enable {
          automatic = true;
          dates = cfg.ecospace.freq;
          options = "--delete-older-than ${cfg.ecospace.olderthan}";
        };
        # extraOptions = ''
        #   min-free = ${toString (cfg.ecospace.minfree * 1024 * 1024)}
        #   max-free = ${toString (cfg.ecospace.maxfree * 1024 * 1024)}
        # '';
        buildMachines = lib.attrsets.mapAttrsToList (name: opts: {
          inherit (opts) system sshUser maxJobs protocol;
          inherit (opts) hostName speedFactor supportedFeatures;
          inherit (opts) mandatoryFeatures;
          inherit (opts) sshKey;
        }) (lib.attrsets.filterAttrs (_: opts: opts.enable) cfg.builders.remote.machines);
      };
      users = lib.mkIf cfg.builders.local.enable {
        users.${cfg.builders.local.sshUser} = {
          isSystemUser = true;
          openssh.authorizedKeys.keyFiles=[
            (libssh.get_remote_builder_pubk cfg.builders.setup.name)
          ];
          group = cfg.builders.local.sshUser;
        };
        groups.${cfg.builders.local.sshUser} = {};
      };
    };
  }

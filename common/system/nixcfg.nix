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
    };
    config = {
      nix = {
        settings = {
          auto-optimise-store = true;
          # gc-keep-output = true;
          # gc-keep-derivations = true;
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
      };
    };
  }

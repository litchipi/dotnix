{ config, lib, ... }:
let
  cfg = config.nix;
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

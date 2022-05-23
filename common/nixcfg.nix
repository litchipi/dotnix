{ config, lib, pkgs, extra, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  cfg = config.cmn.nix;
in
conf_lib.create_common_confs [
  {
    name = "ecospace";
    parents = ["nix" "profile"];
    add_opts = {
      minfree = lib.mkOption {
        type = lib.types.int;
        description = "Triggers cleaning when there's less than X MiB space left";
        default = 256;
      };
      maxfree = lib.mkOption {
        type = lib.types.int;
        description = "To which limit we clean when minfree is triggered (in MiB)";
        default = 1024;
      };
      gc_auto_olderthan = lib.mkOption {
        type = lib.types.str;
        description = "Auto delete nix store elements older than X";
        default = "7d";
      };
      gc_freq = lib.mkOption {
        type = lib.types.str;
        description = "Frequency to collect garbages in nix store";
        default = "daily";
      };
    };
    cfg = {
      nix = {
        settings = {
          auto-optimise-store = true;
          gc-keep-output = true;
          gc-keep-derivations = true;
        };
        gc = {
          automatic = true;
          dates = cfg.profile.ecospace.gc_freq;
          options = "--delete-older-than ${cfg.profile.ecospace.gc_auto_olderthan}";
        };
        extraOptions = ''
          min-free = ${toString (cfg.profile.ecospace.minfree * 1024 * 1024)}
          max-free = ${toString (cfg.profile.ecospace.maxfree * 1024 * 1024)}
        '';
      };
    };
  }
]

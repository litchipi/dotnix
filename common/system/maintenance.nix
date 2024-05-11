{ config, lib, pkgs, ... }: let
  cfg = config.maintenance;

  cmd = c: err: "${c} 2>&1 || echo 'ERR: ${err}'";

  scripts = {
    flatpakUpdate = cmd "flatpak update --noninteractive" "Flatpak update failed";

    flakeUpdateAll = ''
      cd ${config.setup.config_repo_path}
      ${cmd "nix flake update" "Nix flake update failed"}
    '';

    flakeUpdateInputs = inps: ''
      cd ${config.setup.config_repo_path}

    '' + (builtins.concatStringsSep "\n" (builtins.map (inp:
      cmd "nix flake lock --update-input ${inp}" "Update input ${inp} of flake failed"
    ) inps)) + "\n";

    nixosUpgrade = dry: let
      action = if dry then "dry-activate" else "switch";
    in cmd
      # TODO  Add a profile name maintenance-%D-%M-%Y
      "nixos-rebuild ${action} --flake ${config.setup.config_repo_path}"
      "Nixos system upgrade failed";

    nixGc = t: cmd "nix-collect-garbage --delete-older-than ${t}" "Nix collect garbage failed";

    nixStoreOptimize = cmd "nix store optimise" "Nix store optimize failed";
  };

  mkScript = cfg: with lib.strings; builtins.concatStringsSep "\n" [
    "echo 'Starting maintenance'"
    (optionalString cfg.flakeUpdateInputs.enable
      (scripts.flakeUpdateInputs cfg.flakeUpdateInputs.inputs)
    )
    (optionalString cfg.flakeUpdateAll.enable scripts.flakeUpdateAll)
    (optionalString cfg.nixosUpgrade.enable 
      (scripts.nixosUpgrade cfg.nixosUpgrade.dry)
    )
    (optionalString cfg.flatpakUpdate.enable scripts.flatpakUpdate)
    (optionalString cfg.nixGc.enable (scripts.nixGc cfg.nixGc.olderThan))
    (optionalString cfg.nixStoreOptimize.enable scripts.nixStoreOptimize)
    "echo 'Maintenance done'"
  ];

in {
  options.maintenance = {
    enable = lib.mkEnableOption {
      description = "Enable the maintenance system";
    };

    timerConfig = lib.mkOption {
      type = lib.types.attrs;
      description = "Timer config of the systemd timer";
      default = { OnCalendar = "daily"; };
    };

    flatpakUpdate.enable = lib.mkEnableOption {
      description = "Update automatically the flatpak installed packages";
    };

    flakeUpdateAll.enable = lib.mkEnableOption {
      description = "Update automatically the whole nix flake";
    };

    flakeUpdateInputs = {
      enable = lib.mkEnableOption {
        description = "Update automatically some inputs of the flake";
      };

      inputs = lib.mkOption {
        description = "Inputs to update from the flake";
        type = lib.types.listOf lib.types.str;
      };
    };

    nixosUpgrade = {
      enable = lib.mkEnableOption {
        description = "Upgrade automatically the NixOS system";
      };

      dry = lib.mkEnableOption {
        description = "Perform a dry activation instead of real upgrade";
      };
    };
    
    nixGc = {
      enable = lib.mkEnableOption {
        description = "Clean nix store every day";
      };

      olderThan = lib.mkOption {
        description = "Delete older than X days";
        type = lib.types.int;
        default = 30;
      };
    };

    nixStoreOptimize.enable = lib.mkEnableOption {
      description = "Perform nix store optimization";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.timers.maintenance = {
      wantedBy = [ "timers.target" ];
      inherit (cfg) timerConfig;
    };

    systemd.services.maintenance = {
      description = "Do some maintenance on the system";
      wants = [ "local-fs.target" ];
      wantedBy = lib.mkForce [];
      after = [ "local-fs.target" ];
      path = with pkgs; [
        nixos-rebuild 
        nix
        git
      ];

      script = mkScript cfg;

      serviceConfig.Type = "oneshot";
    };
  };
}

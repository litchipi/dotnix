{config, lib, pkgs, ...}: let
  cfg = config.services.nas;

in {
  options.services.nas = {
    enable = lib.mkEnableOption { description = "Enable the NAS service"; };

    rootPath = lib.mkOption {
      type = lib.types.path;
      description = "Path where to store all the data of the NAS";
    };

    usernameMap = lib.mkOption {
      type = lib.types.attrs;
      description = "Map system usernames to samba usernames";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.nas = {};
    users.users.${config.base.user}.extraGroups = [ "nas" ];
    setup.directories = [
      {
        path = cfg.rootPath;
        owner = "root";
        group = "nas";
      }
    ];

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    services.samba = {
      enable = true;
      openFirewall = lib.mkDefault true;
      shares.default = {
        path = cfg.rootPath;
        "read only" = lib.mkDefault false;
        browseable = lib.mkDefault true;
        "guest ok" = lib.mkDefault false;
        comment = lib.mkDefault "NAS of ${config.base.hostname}";
        "create mask" = lib.mkDefault "0664";      # Read only for other users
        "directory mask" = lib.mkDefault "0777";   # Complete access to the directories
      };

      extraConfig = let
        username_map_list = lib.attrsets.mapAttrsToList (name: val: "${name}=${val}") cfg.usernameMap;
        username_map = pkgs.writeText "samba_username_map" (builtins.concatStringsSep "\n" username_map_list);
      in ''
      username map = ${username_map}
      '';
    };
  };
}

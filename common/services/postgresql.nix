{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.postgresql;

  dbuser = lib.types.submodule {
    options.databases = lib.mkOption {
      type = with lib.types; listOf str;
      description = "Name of the databases to ensure creation";
      default = [];
    };

    options.permissions = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = "Permissions to set for the user";
      default = {};
    };

    options.auth_method = lib.mkOption {
      type = lib.types.str;
      description = "Authentication method to use for this user on the databases";
      default = "ident";
    };
  };
in
libconf.create_common_confs [
  {
    name = "postgresql";
    parents = [ "services" ];
    add_opts = {
      port = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Postgresql server";
        default = 5432;
      };
      dir = lib.mkOption {
        type = lib.types.str;
        description = "Directory where the database is located";
        default = "/var/psql";
      };
      users = lib.mkOption {
        type = lib.types.attrsOf dbuser;
        description = "Database user to initialize";
        default = {};
      };
      psqlcfg = lib.mkOption {
        type = lib.types.attrs;
        description = "Config to set for postgresql";
        default = {};
      };
    };
    cfg = {
      boot.postBootCommands = ''
        mkdir -p ${cfg.dir}
        chown -R postgres:postgres ${cfg.dir}
      '';

      services.postgresql = {
        enable = true;
        port = cfg.port;
        dataDir = cfg.dir;
        ensureDatabases = lib.lists.flatten (lib.attrsets.mapAttrsToList (user: val:
          val.databases
        ) cfg.users);

        ensureUsers = lib.lists.flatten (lib.attrsets.mapAttrsToList (user: val: {
          name = user;
          ensurePermissions = builtins.listToAttrs (
            lib.attrsets.mapAttrsToList (db: perm: {
              name = "DATABASE ${db}";
              value = perm;
            }) val.permissions
          );
        }) cfg.users);

        authentication = (''
          '' + (builtins.concatStringsSep "\n" (
              lib.lists.flatten (
                lib.attrsets.mapAttrsToList (user: val:
                  builtins.map (db: ''
                    local ${db} ${user} ${val.auth_method}
                    host ${db} ${user} localhost ${val.auth_method}
                  '') val.databases
                ) cfg.users
              )
            )
          )
        );
      } // cfg.psqlcfg;

      users.extraUsers = lib.attrsets.mapAttrs' (user: val: {
        name = user;
        value = {
          isSystemUser = true;
          group = user;
          extraGroups = [ "postgresql" ]; # TODO  See if necessary
        };
      }) cfg.users;

      users.extraGroups = lib.attrsets.mapAttrs' (user: val: {
        name = user;
        value.members = [ user ];
      }) cfg.users;
    };
  }
]

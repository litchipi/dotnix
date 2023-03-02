{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix { inherit config lib pkgs; };
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.massa;
in
libconf.create_common_confs [
  {
    name = "massa";
    parents = ["services"];
    add_opts.dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Where the configuration and data are stored";
        default = "/var/massa";
    };
    cfg = {
      base.secrets.store.massa_wallet_pwd = libdata.set_secret {
        user = "massa";
        path = [ "services" "massa" config.base.hostname "wallet_pwd" ];
      };

      system.activationScripts.chmod_massa_datadir = ''
        chown -R massa:massa ${cfg.dataDir}
        chmod -R 660 ${cfg.dataDir}/client
        chmod 770 ${cfg.dataDir}/client/massa-client
        chmod -R 600 ${cfg.dataDir}/node
        chmod 700 ${cfg.dataDir}/node/massa-node
      '';

      users.users.massa = {
        isSystemUser = true;
        group = "massa";
      };
      users.groups.massa = {
        members = [
            "massa"
            config.base.user
        ];
      };

      systemd.services.massa-node = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
            User = "massa";
            WorkingDirectory = "${cfg.dataDir}/node";
        };
        script = ''
            ./massa-node -p "$(cat ${config.base.secrets.store.massa_wallet_pwd.dest})"
        '';
      };
    };
  }
]

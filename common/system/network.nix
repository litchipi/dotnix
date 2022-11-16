{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  vpncfg = config.cmn.software.protonvpn;
in
libconf.create_common_confs [
  {
    name = "protonvpn";
    parents = [ "software" ];

    add_opts = {
      username = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Username to use for ProtonVPN connection";
      };
    };
    assertions = [
      { assertion = vpncfg.username != ""; message = "You have to set the username";}
    ];

    add_pkgs = with pkgs; [
      protonvpn-cli
    ];

    cfg.base.secrets.store.protonvpn_creds = libdata.set_secret {
      user = config.base.user;
      path = ["keys" config.base.hostname "protonvpn_creds" ];
    };
    cfg.environment.shellAliases = let
      protonvpn_login = pkgs.writeText "protonvpn_login.tcl" ''
        set user [lindex $argv 0]
        set p [lindex $argv 1]
        spawn -noecho protonvpn-cli login $user
        expect {
          "already logged" { exit 0 };
          "password" {
              send_user "Entering password";
              send "$p\n";
              interact;
              exit 0;
          };
          timeout { send_user "Timeout"; exit 254 };
          eof { exit 253 };
        };
      '';
    in {
      vpn_logout = "protonvpn-cli logout";
      vpn_login = "${pkgs.expect}/bin/expect ${protonvpn_login} ${vpncfg.username} $(cat ${config.base.secrets.store.protonvpn_creds.dest})";
      vpn = "protonvpn-cli c --sc";
      vpn_p2p = "protonvpn-cli c --p2p";
      vpn_tor = "protonvpn-cli c --tor";
      vpn_cc = "protonvpn-cli c --cc";
      vpn_random = "protonvpn-cli c -r";
      vpn_fast = "protonvpn-cli c -f";
      novpn = "protonvpn-cli d";
    };
  }
]

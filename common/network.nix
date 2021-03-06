{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};

  vpncfg = config.cmn.software.protonvpn;
  vpncreds = libdata.plain_secrets.creds.proton_vpn;
in
conf_lib.create_common_confs [
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
      expect
    ];

  home_cfg.home.file.".protonvpn_login.tcl".text = ''
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
    home_cfg.programs.bash = {
      enable = true;
      shellAliases = {
        vpn_logout = "protonvpn-cli logout";
        vpn_login = "expect $HOME/.protonvpn_login.tcl ${vpncfg.username} $(cat ${vpncreds})";
        vpn = "protonvpn-cli c --sc";
        vpn_p2p = "protonvpn-cli c --p2p";
        vpn_tor = "protonvpn-cli c --tor";
        vpn_cc = "protonvpn-cli c --cc";
        vpn_random = "protonvpn-cli c -r";
        vpn_fast = "protonvpn-cli c -f";
        novpn = "protonvpn-cli d";
      };
    };
  }
]

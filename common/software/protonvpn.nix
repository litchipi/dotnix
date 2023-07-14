{ config, lib, pkgs, pkgs_unstable, ... }:
let
  cfg = config.software.protonvpn;
in
  {
    options.software.protonvpn = {
      secrets = lib.mkOption {
        type = lib.types.attrs;
        description = "Secrets for the usage of ProtonVPN";
      };
      username = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Username to use for ProtonVPN connection";
      };
    };
    config = {
      assertions = [
        { assertion = cfg.username != ""; message = "You have to set the username";}
      ];
      environment.systemPackages = [ pkgs_unstable.protonvpn-cli ];

      secrets.setup.protonvpn = {
        user = config.base.user;
        secret = cfg.secrets;
      };

      environment.shellAliases = let
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
        vpn_login = "${pkgs.expect}/bin/expect ${protonvpn_login} ${cfg.username} $(cat ${cfg.secrets.file})";
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

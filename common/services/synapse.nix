# TODO  Copy config from
# https://github.com/adisbladis/nixconfig/blob/master/hosts/bladis/synapse.nix
{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../../lib/utils.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.synapse;

  fqdn = "chat.${config.base.networking.domain}";
  synapse_secret = name: libdata.set_secret "synapse" ["services" "synapse" config.base.hostname name] {};
  synapse_db_password = "synapse"; # TODO  Use secrets to handle this

  help_message = ''
    Please connect a Matrix chat client using "${fqdn}/_matrix" as a server URL.
  '';
in
libconf.create_common_confs [
  {
    name = "synapse";
    parents = [ "services" ];

    add_opts = {
      port = lib.mkOption {
        description = "Port of the service on the local server";
        type = lib.types.int;
        default = 8008;
      };
    };

    cfg = {
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40000 + cfg.port; guest.port = cfg.port; };
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      users.users."${config.base.user}".extraGroups = [ "synapse" "postgres" ];

      cmn.services.nextcloud.riotchat.enable = true;

      services.postgresql.enable = true;
      # TODO  Use postgresql nixified configuration for this
      services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
        CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD '${synapse_db_password}';
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
      '';

      services.nginx = {
        enable = true;

        virtualHosts = {
          # "chat.${config.base.networking.domain}" = {
          #   # enableACME = true;
          #   # forceSSL = true;
          # };

          # Reverse proxy for Matrix client-server and server-server communication
          ${fqdn} = {
            # enableACME = true;
            # forceSSL = true;

            # Or do a redirect instead of the 404, or whatever is appropriate for you.
            # But do not put a Matrix Web client here! See the Element web section below.
            locations."/".extraConfig = ''
              add_header Content-Type text/html;
              return 200 '<html><body>${help_message}</body></html>';
            '';

            # forward all Matrix API calls to the synapse Matrix homeserver
            locations."/_matrix" = {
              proxyPass = "http://[::1]:${builtins.toString cfg.port}"; # without a trailing /
            };

            locations."= /.well-known/matrix/server".extraConfig =
              let
                # use 443 instead of the default 8448 port to unite
                # the client-server and server-server port for simplicity
                server = { "m.server" = "${fqdn}:443"; };
              in ''
                add_header Content-Type application/json;
                return 200 '${builtins.toJSON server}';
              '';

            locations."= /.well-known/matrix/client".extraConfig =
              let
                client = {
                  "m.homeserver" =  { "base_url" = "https://${fqdn}"; };
                  "m.identity_server" =  { "base_url" = "https://vector.im"; };
                };
              # ACAO required to allow element-web on any URL to request this json file
              in ''
                add_header Content-Type application/json;
                add_header Access-Control-Allow-Origin *;
                return 200 '${builtins.toJSON client}';
              '';
          };
        };
      };

      services.matrix-synapse = {
        enable = true;
        server_name = config.base.networking.domain;
        listeners = [
          {
            port = cfg.port;
            bind_address = "::1";
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [ "client" "federation" ];
                compress = true; #false;
              }
            ];
          }
        ];
      };
    };
  }
]

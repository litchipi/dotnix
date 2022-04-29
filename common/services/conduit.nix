
{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.conduit;
  fqdn = "chat.${config.base.networking.domain}";
in
libconf.create_common_confs [
  {
    name = "conduit";
    parents = [ "services" ];
    add_opts = {
      port = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Conduit server";
        default = 6167;
      };
    };
    cfg = {
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40080; guest.port = 80; };
        https= { from = "host"; host.port = 40443; guest.port = 443; };
        matrix-federation = { from = "host"; host.port = 48448; guest.port = 8448; };
      };

      networking.firewall.allowedTCPPorts = [ 80 443 8448 ];
      users.users."${config.base.user}".extraGroups = [ "conduit" ];
      
      cmn.services.nextcloud.riotchat.enable = true;

      services.matrix-conduit = {
        enable = true;
        settings.global = {
          address = "0.0.0.0";
          server_name = "${fqdn}";
          port = cfg.port;
        };
      };
      
      services.nginx = let
        proxy = "http://0.0.0.0:${builtins.toString cfg.port}";
      in {
        enable = true;

        virtualHosts = {
          ${fqdn} = {
            locations."/".proxyPass = proxy;
            locations."/_matrix".proxyPass = proxy;

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
    };
  }
]

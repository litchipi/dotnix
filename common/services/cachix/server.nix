{ config, lib, ... }:
let
  sub = "cachix";
  fqdn = "${sub}.${config.base.networking.domain}";
  cfg = config.services.cachix.server;
in
  {
    options.services.cachix.server = {
      secrets = lib.mkOption {
        type = lib.types.attrsets;
        description = "Secrets for the Cachix service";
      };
    };
    config = {
      base.networking.subdomains = [ sub ];
      services.nix-serve = {
        enable = true;
        secretKeyFile = cfg.secrets.${config.base.networking.domain};
      };
      services.nginx = {
        enable = true;
        virtualHosts.${fqdn} = {
          # TODO    Add HTTPS
          serverAliases = [ "binarycache" ];
          locations."/".extraConfig = ''
            proxy_pass http://localhost:${toString config.services.nix-serve.port};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };
  }

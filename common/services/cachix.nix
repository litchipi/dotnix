{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libcachix = import ../../lib/services/cachix.nix { inherit config lib pkgs;};

  fqdn = "cachix.${config.base.networking.domain}";
  cfg = config.cmn.services.cachix;

  default_servers = {
    server = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    pubkey = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
in
libconf.create_common_confs [
  {
    name = "client";
    parents = ["services" "cachix" ];
    add_opts = {
      servers = lib.mkOption {
        type = lib.types.attrs;
        description = "Servers to connect to and their public key";
      };
      add_default_servers = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Add default servers to list as well";
      };
    };
    cfg.nix.settings = {
      substituters = (if cfg.client.add_default_servers then default_servers.server else [])
        ++ (lib.attrsets.mapAttrsToList (server: _: server) cfg.client.servers);
      trusted-public-keys =
        (if cfg.client.add_default_servers then default_servers.pubkey else [])
        ++ (lib.attrsets.mapAttrsToList (_: pubkey:
          if builtins.isString pubkey then pubkey
          else if builtins.isPath pubkey then builtins.readFile pubkey
          else builtins.throw
            ("Can't read the value '${builtins.toString pubkey}', expected string or path, " +
            "got type ${builtins.typeOf pubkey}")
          ) cfg.client.servers);
    };
  }
  {
    name = "server";
    parents = ["services" "cachix"];
    cfg = {
      base.secrets.store."${fqdn}_secretKeyFile" = libcachix.get_secretKeyFile fqdn;
      services.nix-serve = {
        enable = true;
        secretKeyFile = config.base.secrets.store."${fqdn}_secretKeyFile".dest;
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
]

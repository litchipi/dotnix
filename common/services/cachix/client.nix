{ config, lib, pkgs, ... }:
let
  cfg = config.services.cachix.client;
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
  {
    options.services.cachix.client = {
      servers = lib.mkOption {
        type = lib.types.attrs;
        description = "Servers to connect to and their public key";
        default = {};
      };
      add_default_servers = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Add default servers to list as well";
      };
    };
    config = {
      nix = {
        extraOptions = ''
          fallback = true
        '';
        settings = {
          extra-substituters = (if cfg.add_default_servers
            then default_servers.server
            else [])
            ++ (lib.attrsets.mapAttrsToList (server: _: server) cfg.servers);

          trusted-public-keys =
            (if cfg.add_default_servers then default_servers.pubkey else [])
            ++ (lib.attrsets.mapAttrsToList (_: pubkey:
              if builtins.isString pubkey then pubkey
              else if builtins.isPath pubkey then builtins.readFile pubkey
              else builtins.throw
                ("Can't read the value '${builtins.toString pubkey}', expected string or path, " +
                "got type ${builtins.typeOf pubkey}")
                ) cfg.servers);
        };
      };
    };
  }

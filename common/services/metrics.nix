{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.metrics;
  prometheus_sub = "metrics";
in
libconf.create_common_confs [
    {
      name = "prometheus";
      parents = ["services" "metrics"];
      add_opts = {
        port = {
          type = lib.types.int;
          default = 43921;
          description = "Port on which serve Prometheus";
        };
      };
      cfg = {
        base.networking.subdomains = [ prometheus_sub ];
      };
      cfg.services.prometheus = {
        enable = true;
        webExternalUrl = "${prometheus_sub}.${config.base.networking.domain}";
        port = cfg.prometheus.port;
        checkConfig = "syntax-only";
        retentionTime = "30d";
        extraFlags = [];
        enableReload = true;
        globalConfig = {

        };
        scrapeConfigs = {

        };
        alertmanagers = [

        ];
        rules = [

        ];
      };
      # TODO    Setup ngnix
    }
]

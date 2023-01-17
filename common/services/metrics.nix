{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.metrics;
  prometheus_sub = "metrics";
  grafana_sub = "graph";

  metrics_port_min = 44100;

  setup_exporter = name: offport: collectors: {
    inherit name;
    parents = ["services" "metrics" "prometheus"];
    cfg.services.prometheus.exporters.${name} = {
      enable = true;
      enabledCollectors = collectors;
      port = metrics_port_min + offport;
    };
    cfg.cmn.services.metrics.prometheus.localhost_scrape_targets = [(metrics_port_min + offport)];
  };

in
  libconf.create_common_confs [
    {
      name = "grafana";
      parents = ["services" "metrics"];
      add_opts = {
        port = {
          type = lib.types.int;
          default = 43922;
          description = "Port on which serve Prometheus";
        };
      };
      cfg.services.grafana = {
        enable = true;
        port = cfg.grafana.port;
        domain = "${grafana_sub}.${config.base.networking.domain}";
        addr = "127.0.0.1";
      };
      cfg = {
        base.networking.subdomains = [ grafana_sub ];
        services.nginx.virtualhosts."${grafana_sub}.${config.base.networking.domain}" = {
          locations."/" = {
            proxypass = "http://127.0.0.1:${builtins.tostring cfg.grafana.port}";
            proxywebsockets = true;
          };
        };
      };
    }
    {
      name = "prometheus";
      parents = ["services" "metrics"];
      add_opts = {
        port = {
          type = lib.types.int;
          default = 43921;
          description = "Port on which serve Prometheus";
        };
        localhost_scrape_targets = {
          type = lib.types.listOf lib.types.int;
          default = [];
          description = "List of ports on localhost that can be scraped";
        };
      };
      cfg = {
        base.networking.subdomains = [ prometheus_sub ];
        services.nginx.virtualhosts."${prometheus_sub}.${config.base.networking.domain}" = {
          locations."/".proxypass = "http://127.0.0.1:${builtins.tostring cfg.prometheus.port}";
        };
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
        scrapeConfigs = [{
          job_name = "localscrape";
          static_configs = [{
            targets = builtins.map
              (port: "127.0.0.1:${builtins.toString port}")
              cfg.prometheus.localhost_scrape_targets;
          }];
        }];
        alertmanagers = [

        ];
        rules = [

        ];
      };
    }
    (setup_exporter "node" 1 ["systemd"])
]

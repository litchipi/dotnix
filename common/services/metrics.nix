{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.metrics;
  prometheus_sub = "metrics";
  grafana_sub = "graph";

  metrics_port_min = 44100;

  setup_exporter = name: offport: collectors: {
    inherit name;
    parents = ["services" "metrics" "exporter"];
    cfg = {
      services.prometheus.exporters.${name} = {
        enable = true;
        enabledCollectors = collectors;
        port = metrics_port_min + offport;
      };
      cmn.services.metrics.prometheus.localhost_scrape_targets = [(metrics_port_min + offport)];
    };
  };

  grafana_secret = name: libdata.set_secret {
    user = "grafana";
    path = ["services" "grafana" config.base.hostname name ];
  };
  grafana_secret_dest = name: "$__file{${config.base.secrets.store.${name}.dest}}";
in
  libconf.create_common_confs [
    {
      name = "grafana";
      parents = ["services" "metrics"];
      add_opts = {
        port = lib.mkOption {
          type = lib.types.int;
          default = 43922;
          description = "Port on which serve Prometheus";
        };
      };
      cfg = {
        base.secrets.store = {
          grafana_admin_pwd = grafana_secret "admin_pwd";
          grafana_db_pwd = grafana_secret "db_pwd";
        };

        base.networking.subdomains = [ grafana_sub ];
        services.nginx.virtualHosts."${grafana_sub}.${config.base.networking.domain}" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString cfg.grafana.port}";
            proxyWebsockets = true;
          };
        };

        services.grafana = {
          enable = true;
          settings.server = {
            domain = "${grafana_sub}.${config.base.networking.domain}";
            http_port = cfg.grafana.port;
            http_addr = "0.0.0.0";
            enable_gzip = true;
          };
          settings.database = {
            host = "127.0.0.1:${builtins.toString config.services.postgresql.port}";
            password = grafana_secret_dest "grafana_db_pwd";
            type = "postgres";
            user = "grafana";
            name = "grafana";
          };
          settings.analytics.reporting_enabled = false;
          settings.security.admin_password = grafana_secret_dest "grafana_admin_pwd";
        };

        cmn.services.postgresql = {
          enable = true;
          users.grafana = {
            databases = ["grafana"];
            permissions.grafana = "ALL PRIVILEGES";
          };
        };
      };
    }
    {
      name = "prometheus";
      parents = ["services" "metrics"];
      add_opts = {
        port = lib.mkOption {
          type = lib.types.int;
          default = 43921;
          description = "Port on which serve Prometheus";
        };
        localhost_scrape_targets = lib.mkOption {
          type = lib.types.listOf lib.types.int;
          default = [];
          description = "List of ports on localhost that can be scraped";
        };
      };
      cfg = {
        base.networking.subdomains = [ prometheus_sub ];
        services.nginx.virtualHosts."${prometheus_sub}.${config.base.networking.domain}" = {
          locations."/".proxyPass = "http://127.0.0.1:${builtins.toString cfg.prometheus.port}";
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

{ config, lib, pkgs, ... }:
let
  cfg = config.services.prometheus;
  prometheus_sub = "metrics";

  # TODO  Add metrics
  # prometheus-nginx-exporter
  # prometheus-nginxlog-exporter
  # prometheus-nats-exporter
  # prometheus-systemd-exporter
  # prometheus-nextcloud-exporter
  # prometheus-postgres-exporter
  # prometheus-gitlab-ci-pipelines-exporter
  all_exporters = {
    node = {
      enabledCollectors = ["systemd"];
    };
  };
in
  {
    options.services.prometheus = {
      metrics_port_min = lib.mkOption {
        type = lib.types.int;
        default = 44100;
        description = "Port at which exporters will begin to increment";
      };
      localhost_scrape_targets = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "List of ports on localhost that can be scraped";
      };
    };
    config = {
      base.networking.subdomains = [ prometheus_sub ];
      services.nginx.virtualHosts."${prometheus_sub}.${config.base.networking.domain}" = {
        locations."/".proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
      };
      localhost_scrape_targets = builtins.foldl' (
        acc: _: acc ++ [ (cfg.metrics_port_min + (builtins.length acc)) ]
      ) [] all_exporters;
      services.prometheus = {
        enable = true;
        webExternalUrl = "${prometheus_sub}.${config.base.networking.domain}";
        port = lib.mkDefault 43921;
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
              cfg.localhost_scrape_targets;
          }];
        }];
        alertmanagers = [

        ];
        rules = [

        ];
        exporters = builtins.foldl' (acc: exporter: acc ++ [ (exporter // {
          enable = true;
          port = cfg.metrics_port_min + (builtins.length acc);
        })]) [] all_exporters;
      };
    };
  }

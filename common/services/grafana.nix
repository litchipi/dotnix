{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  cfg = config.services.graphana;
  grafana_sub = "graph";
in
  {
    options.services.graphana = {
      secrets = lib.mkOption {
        type = lib.types.attrsets;
        description = "Secrets for the Grafana service";
      };
    };
    config = {
      secrets.store.services.grafana = libdata.set_common_secret_config {
        enable = true;
        user = config.services.grafana.user;
      } config.secrets.store.services.grafana;

      base.networking.subdomains = [ grafana_sub ];
      networking.firewall.allowedTCPPorts = [ 80 443 ];

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
          http_port = lib.mkDefault 43922;
          http_addr = "0.0.0.0";
          enable_gzip = true;
        };
        # TODO  FIXME
        # settings.database = {
        #   host = "127.0.0.1:${builtins.toString config.services.postgresql.port}";
        #   type = "postgres";
        #   user = "grafana";
        #   name = "grafana";
        # };
        settings.analytics.reporting_enabled = false;
        settings.security.admin_password = cfg.secrets.admin_pwd.file;
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

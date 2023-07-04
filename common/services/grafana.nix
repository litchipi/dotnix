{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  cfg = config.services.grafana;
  secrets = pkgs.secrets.set_common_config {
    enable = true;
    user = config.services.grafana.user;
  } cfg.secrets;

  grafana_sub = "graph";
in
  {
    options.services.grafana = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Grafana";
    };

    config = {
      base.networking.subdomains = [ grafana_sub ];
      networking.firewall.allowedTCPPorts = [ 80 443 ];

      services.nginx.virtualHosts."${grafana_sub}.${config.base.networking.domain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.settings.server.http_port}";
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
        settings.database = {
          host = "0.0.0.0:${builtins.toString config.services.postgresql.port}";
          type = "postgres";
          user = "grafana";
          name = "grafana";
        };
        settings.analytics.reporting_enabled = false;
        settings.security.admin_password = "$__file{${secrets.admin_pwd.file}}";
      };

      services.postgresql = {
        enable = true;
        ensureUsers = [
          {
            name = "grafana";
            ensurePermissions = {
              "DATABASE grafana" = "ALL PRIVILEGES";
            };
          }
        ];
      };
    };
  }

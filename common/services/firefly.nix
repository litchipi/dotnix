{ config, lib, pkgs, ... }:
let
  cfg = config.services.firefly-iii;
in {
  imports = [ ../system/backup.nix ];

  options.services.firefly-iii = {
    secrets = pkgs.secrets.mkSecretOption "Secrets for Firefly-iii";
    backup = lib.mkEnableOption {
      description = "Enable the backup service for Firefly-iii";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port on which to serve the service";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "On which address to serve the service";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ config.services.firefly-iii.port ];

    secrets.setup.firefly-iii = {
      user = cfg.user;
      secret = cfg.secrets;
    };

    systemd.services.firefly-iii-serve = {
      description = "Firefly iii accounting tool, web server";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.User = cfg.user;
      serviceConfig.LogsDirectory = "firefly-iii";

      script = let
        nginx_config = pkgs.writeText "firefly-nginx-config" ''
          pid /var/log/firefly-iii/ff3.pid;
          daemon off;
          events {}
          http {
            include ${pkgs.mailcap}/etc/nginx/mime.types;
            types_hash_max_size 4096;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            include ${pkgs.nginx}/conf/uwsgi_params;
            default_type application/octet-stream;
            sendfile on;
            tcp_nopush on;
            tcp_nodelay on;
            gzip on;
            server_tokens off;

            access_log /var/log/firefly-iii/access.log;
            server {
              listen ${builtins.toString cfg.port};
              root ${cfg.package}/public;
              location / {
                index index.php;
                try_files $uri $uri/ /index.php?$query_string;
                sendfile off;
              }
              location ~ .php$ {
                include ${pkgs.nginx}/conf/fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $request_filename;
                fastcgi_param modHeadersAvailable true;
                fastcgi_pass unix:${config.services.phpfpm.pools.firefly-iii.socket};
              }
            }
          }
        '';
      in ''
        ${lib.getExe pkgs.nginx} \
          -c ${nginx_config} \
          -e /var/log/firefly-iii/error.log \
      '';
    };

    services.firefly-iii = {
      settings.DB_PASSWORD_FILE = cfg.secrets.db_password.file;
      settings.APP_KEY_FILE = cfg.secrets.app_key.file;
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      firefly-iii = {
        inherit (cfg) user secrets;
        paths = [ cfg.dataDir ];
      };
    };
  };
}

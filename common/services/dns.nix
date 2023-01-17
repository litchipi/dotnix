{ config, lib, pkgs, inputs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.dns;
in
libconf.create_common_confs [
  {
    name = "blocky";
    parents = ["services" "dns"];
    add_opts = {
      metrics_port = lib.mkOption {
        type = lib.types.int;
        default = 43963;
        description = "Port to serve the HTTP server used for API and metrics";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/blocky/";
        description = "Directory where to store data related to blocky";
      };
    };
    cfg = {
      setup.directories = [
        { path = "${cfg.blocky.dataDir}/logs"; perms = "700"; owner = "blocky"; }
      ];
      networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
      systemd.services.blocky.serviceConfig.LogsDirectory = "blocky";
    };
    cfg.services.blocky = {
      enable = true;
      settings = {
        httpPort = cfg.blocky.metrics_port;
        logLevel = "info";
        upstream.default = config.networking.nameservers;
        blocking.blackLists.custom = [
          "${inputs.StevenBlackHosts}/alternates/fakenews-gambling/hosts"
        ];
        caching = {
          prefetching = true;
          minTime = "1h";
        };
        prometheus.enable = true;
        queryLog = {
          type = "csv";
          target = "/var/log/blocky";
          logRetentionDays = 7;
        };
        customDNS = {
          mapping = {
            ${config.base.networking.domain} = config.base.networking.static_ip_address;
          };
        };
      };
    };
  }
]

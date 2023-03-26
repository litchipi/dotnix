{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.services.blocky;
in
  {
    options.services.blocky = {
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/blocky/";
        description = "Directory where to store data related to blocky";
      };
    };
    config = {
      setup.directories = [
        { path = cfg.dataDir; perms = "700"; owner = "blocky"; }
      ];
      networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
      systemd.services.blocky.serviceConfig.LogsDirectory = "blocky";
      services.blocky = {
        enable = true;
        settings = {
          httpPort = lib.mkDefault 43963;
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
            target = "${cfg.dataDir}/blocky";
            logRetentionDays = 7;
          };
          customDNS = {
            mapping = {
              ${config.base.networking.domain} = config.base.networking.static_ip_address;
            };
          };
        };
      };
    };
  }

{config, lib, ...}: let
  cfg = config.services.radicale;
in {
  options.services.radicale = {
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port on which to serve radicale";
    };
    backup = lib.mkEnableOption {
      description = "Wether to setup backup for this service";
    };
    secrets = lib.mkOption {
      type = lib.types.attrs;
      description = "Secrets for the radicale service";
    };
  };
  config = {
    secrets.setup.radicale = {
      user = "radicale";
      secret = cfg.secrets.htpasswd;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    services.radicale = {
      settings = {
        server = {
          hosts = [ "0.0.0.0:${builtins.toString cfg.port}" ];
        };
        auth = {
          type = "htpasswd";
          htpasswd_filename = cfg.secrets.htpasswd.file;
          htpasswd_encryption = "plain";
          delay = 60;
        };
        storage.filesystem_folder = "/var/lib/radicale/collections";
        logging.level = "info";
      };
    };

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      radicale = {
        user = "radicale";
        inherit (cfg) secrets;
        paths = [ "/var/lib/radicale/" ];
      };
    };
  };
}

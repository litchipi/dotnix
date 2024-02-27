{config, lib, ...}: let
  cfg = config.services.mealie;
in {
  options.services.mealie = {
    backup = lib.mkEnableOption {
      description = "Wether to setup backup for this service";
    };
    secrets = lib.mkOption {
      type = lib.types.attrs;
      description = "Secrets for the mealie service";
    };
  };
  config = {
    secrets.setup.mealie = {
      user = "mealie";
      secret = cfg.secrets;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    backup.services = lib.attrsets.optionalAttrs cfg.backup {
      mealie = {
        user = "mealie";
        inherit (cfg) secrets;
        paths = [ "/var/lib/mealie/" ];
      };
    };
  };
}

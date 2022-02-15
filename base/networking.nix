{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
in
{
  options.base.networking = {
    connect_wifi= lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
    };
  };

  config = {
      networking = {
        hostName = config.base.hostname;
        networkmanager.enable = true;
        enableIPv6 = false;
    };

    users.users."${config.base.user}".extraGroups = [ "networkmanager" ];
    services.avahi.enable = true;

    environment.systemPackages = with pkgs; [
      networkmanager
    ];

    networking.wireless.networks = builtins.listToAttrs (
      builtins.map (cfg: { name=cfg.ssid; value={ pskRaw = cfg.passwd; }; })
      (
        builtins.map libdata.load_wifi_cfg config.base.networking.connect_wifi
      )
    );
  };
}

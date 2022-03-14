{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.base.networking;
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
        networkmanager = {
          enable = true;
          unmanaged = [
            "*" "except:type:wwan" "except:type:gsm"
          ];
        };
        enableIPv6 = false;
    };

    users.users."${config.base.user}".extraGroups = [ "networkmanager" ];
    services.avahi.enable = true;

    networking.wireless.networks = builtins.listToAttrs (
      builtins.map (cfg: { name=cfg.ssid; value={ pskRaw = cfg.passwd; }; })
      (
        builtins.map libdata.load_wifi_cfg cfg.connect_wifi
      )
    );
  };
}

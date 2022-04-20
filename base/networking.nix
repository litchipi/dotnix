{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libssh = import ../lib/ssh.nix {inherit config lib pkgs;};

  cfg = config.base.networking;

  vm_config = {
    virtualisation.forwardPorts = lib.mkIf config.base.is_vm
      (lib.attrsets.mapAttrsToList (_: value: value) cfg.vm_forward_ports);
  };
in
{
  options.base.networking = {
    connect_wifi= lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
    };

    ssh_auth_keys = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "SSH authorizedKeys to add for this machine";
    };

    ssh = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether to setup OpenSSH or not";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name resolving to the IP of this machine";
      default = "localhost";
    };

    vm_forward_ports = lib.mkOption {
      type = lib.types.attrs;
      description = "Ports to forward if running config on VM";
      default = {};
    };
  };

  config = {
      networking = {
        hostName = config.base.hostname;
        # TODO  FIXME Breaks networking in VM
        # networkmanager = {
        #   enable = true;
        #   unmanaged = [
        #     "*" "except:type:wwan" "except:type:gsm"
        #   ];
        # };
        # enableIPv6 = false;
    };

    users.users."${config.base.user}" = {
      extraGroups = [ "networkmanager" ];
      openssh.authorizedKeys.keys = libssh.get_authorized_keys config.base.user cfg.ssh_auth_keys;
    };
    services.avahi.enable = true;

    networking.wireless.networks = builtins.listToAttrs (
      builtins.map (cfg: { name=cfg.ssid; value={ pskRaw = cfg.passwd; }; })
      (
        builtins.map libdata.load_wifi_cfg cfg.connect_wifi
      )
    );

    # Block unwanted internet data
    networking.stevenBlackHosts = {
      blockFakenews = true;
      blockGambling = true;
      blockPorn = true;
      blockSocial = true;
      enable = true;
    };

    services.openssh = lib.mkIf config.base.networking.ssh {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = lib.mkForce "no";
      kbdInteractiveAuthentication = false;
    };

    # Set up  recommended settings for nginx if used
    services.nginx = {
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  } // (lib.mkIf config.base.is_vm vm_config);
}

{ config, lib, pkgs, extra, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libssh = import ../lib/ssh.nix {inherit config lib pkgs;};

  cfg = config.base.networking;
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
      description = "SSH authorizedKeys to add for the base user of this machine";
    };

    ssh = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether to setup OpenSSH or not";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name resolving to the IP of this machine";
      default = extra.domain or "localhost";
    };

    # TODO  Use firewall open ports to automatically generate port forwarding
    vm_forward_ports = lib.mkOption {
      type = lib.types.attrs;
      description = "Ports to forward if running config on VM";
      default = {};
    };

    add_dns = lib.mkOption {
      type = with lib.types; listOf str;
      description = "Nameservers to add to the configuration";
      default = [];
    };
  };

  config = {
    networking = {
      firewall.enable = true;

      hostName = config.base.hostname;

        # TODO  FIXME Breaks networking in VM
        # networkmanager = {
        #   enable = true;
        #   unmanaged = [
        #     "*" "except:type:wwan" "except:type:gsm"
        #   ];
        # };
      nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ] ++ cfg.add_dns;
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
      blockFakenews = lib.mkDefault true;
      blockGambling = lib.mkDefault true;
      blockPorn = lib.mkDefault true;
      blockSocial = lib.mkDefault false;
    };

    services.openssh = lib.mkIf config.base.networking.ssh {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = lib.mkForce "no";
      kbdInteractiveAuthentication = false;
    };

    # Set up  recommended settings for nginx if used
    # TODO  if no subdomain, redirect to service provided in options, or display 404
    services.nginx = {
      enable = lib.mkDefault false;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = config.base.email;
    };
  };
}

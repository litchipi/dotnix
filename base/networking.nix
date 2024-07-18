{ config, lib, pkgs, ... }:
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

  config = let
    ssh_ident = "${config.base.user}@${config.base.hostname}";
  in {

    secrets.store.ssh_privk.${config.base.hostname}.${config.base.user} = {
      link = "/home/${config.base.user}/.ssh/id_rsa";
      transform = "cat - <(echo \"\")";
    };

    # TODO  IMPORTANT  Fixup ssh id private key permissions
    secrets.setup.ssh_privk = {
      user = config.base.user;
      secret = config.secrets.store.ssh_privk.${config.base.hostname}.${config.base.user};
    };

    base.home_cfg = {
      home.file.".ssh/id_rsa.pub".source = (
        libdata.get_data_path ["pubkeys" "ssh" "${ssh_ident}.pub"]
      );
    };

    system.activationScripts.chown_nginx_dir = ''
        if [ -d /var/cache/nginx ]; then
            chown -R nginx:nginx /var/cache/nginx
        fi
    '';
    # TODO      Report nginx cache dir misconfiguration to nixpkgs

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
      nameservers = cfg.add_dns ++ [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];
    };

    users.users."${config.base.user}" = {
      extraGroups = [ "networkmanager" ];
      openssh.authorizedKeys.keys = libssh.get_authorized_keys config.base.user cfg.ssh_auth_keys;
    };

    services.avahi = {
        enable = true;
        publish = {
            enable = true;
            workstation = true;
            addresses = true;
        };
        nssmdns4 = true;
    };

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

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = lib.mkForce "no";
        KbdInteractiveAuthentication = false;
      };
    };

    # Set up  recommended settings for nginx if used
    services.nginx = {
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

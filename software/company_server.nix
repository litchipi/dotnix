{ config, lib, pkgs, inputs, system, ... }:
let
  libnc = import ../lib/services/nextcloud.nix { inherit config lib pkgs;};
  company_name="tyf";

  persowebsite = {
    user = "op_persowebsite";
    port = 8095;
    dbname = "persowebsite";
    dir = "/var/www/persowebsite";
  };

  external_copy = {
    usb_a = {
      device = "/dev/disk/by-uuid/2da4b13f-c308-4fcf-995f-c7660401bac7";
      fsType = "btrfs";
    };
    usb_b = {
      device = "/dev/disk/by-uuid/1826cc9f-ad2b-4d7e-8076-6635478733f2";
      fsType = "btrfs";
    };
  };
in
{
  base.user = "op";
  base.email = "litchi.pi@proton.me";
  base.networking.ssh_auth_keys = [ "john@sparta" "tim@diamond" ];

  base.networking.domain = "orionstar.cyou";
  base.networking.static_ip_address = "192.168.1.163";

  base.add_pkgs = with pkgs; [
    glances
  ];

  cmn.server.enable = true;
  cmn.wm.enable = false;

  cmn.services.gitlab = {
    enable = true;
    backup = {
      gdrive = true;
      timerConfig.OnCalendar = "05/7:00:00";
      inherit external_copy;
    };
    runners = {
      enable = true;
      services.buster.runnerOpts.dockerImage = "debian:stable-20221024-slim";
      add_nix_service = true;
    };
  };

  cmn.services.cachix.server.enable = true;

  cmn.services.restic.global = {
    enable = true;
    gdrive = true;
    timerConfig.OnCalendar = "02/5:00:00";
    backup_paths = [ "/home/${config.base.user}/" ];
    inherit external_copy;
  };

  cmn.services.conduit.enable = true;
  cmn.services.nextcloud = {
    enable = true;

    theme = {
      name = company_name;
      logo = libnc.theme "logo.svg";
      favicon = libnc.theme "logo.svg";
      logoheader = libnc.theme "logo.svg";
      background = libnc.theme "background.jpg";
      slogan = "Where beer really matters";
      color = "#6E1852";
    };

    disable_apps = [
      "photos"
    ];
  };

  services.jitsi-meet = {
    enable = false;
    hostName = "meet.${config.base.networking.domain}";
  };

  cmn.services.postgresql = {
    enable = true;
    port = 5433;
    users.${persowebsite.user} = {
      databases = [ persowebsite.dbname ];
      permissions.${persowebsite.dbname} = "ALL PRIVILEGES";
    };
  };

  cmn.services.web_hosting = {
    enable = true;
    websites."static".package = pkgs.litchipi.tyf_website;
    applications = {

      # Personnal website
      "www" = {
        command = let
          startup = inputs.persowebsite.packages.${system}.prepare {
            port = persowebsite.port;
            posts_dir = "${persowebsite.dir}/posts";
            spawnDatabase = false;
            database = {
              inherit (config.cmn.services.postgresql) port dir;
              user = persowebsite.user;
              host = "/var/run/postgresql/";
              dbname = persowebsite.dbname;
            };
          };
        in "${startup}";
        service_user = persowebsite.user;
        wait_service = [ "postgresql.service" ];
        port = persowebsite.port;
      };
    };
  };

  setup.directories = [
    { path = persowebsite.dir; owner = persowebsite.user; }
  ];

  # Services to check
  # - syncstorage-rs
  # - ethercalc
  # - invoceplane
  # - vikunja

  cmn.services.shiori = {
    enable = true;
    backup = {
      gdrive = true;
      inherit external_copy;
    };
  };

  cmn.services.paperless = {
    enable = true;
    backup = {
      gdrive = true;
      inherit external_copy;
    };
  };

  services.teeworlds = {
    enable = true;
    openPorts = true;
    name = "Suzie";
    motd = "Je suis une truite";
  };

  cmn.nix.builders.setup = {
    enable = true;
    name = "orionstar";
  };
  cmn.nix.ecospace = {
    enable = true;
    olderthan = "15d";
    freq = "daily";
  };

  cmn.services.dns.blocky.enable = true;
  base.networking.add_dns = [
    "1.1.1.1" "1.0.0.1"
    "45.61.49.203"
    "138.197.140.189"
    "168.138.12.137"
    "168.138.8.38"
    "94.247.43.254"
    "172.104.242.111"
    "195.10.195.195"
    "128.76.152.2"
    "172.104.162.222"
    "94.16.114.254"
    "84.200.69.80"
  ];

  cmn.services.metrics = {
    grafana.enable = true;
    prometheus.enable = true;
    exporter.node.enable = true;
  };

  # TODO        Nixify the build of Massa, and create a NixOS module from it
  cmn.services.massa.enable = true;

  # TODO    Add https://github.com/nats-io/nats-server
}

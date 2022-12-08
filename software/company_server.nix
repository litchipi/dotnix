{ config, lib, pkgs, inputs, system, ... }:
let
  company_name="tyf";

  libnc = import ../lib/services/nextcloud.nix { inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix { inherit config lib pkgs;};

  persowebsite = {
    user = "op_persowebsite";
    port = 8095;
    dbname = "persowebsite";
    dir = "/var/www/persowebsite";
  };
in
{
  base.user = "op";
  base.email = "litchi.pi@proton.me";
  base.networking.ssh_auth_keys = [ "john@sparta" "tim@diamond" ];

  base.networking.domain = "orionstar.cyou";

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
    timerConfig.OnCalendar = "05/7:00:00";
    backup_paths = [ "/home/${config.base.user}/" ];
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
      auth_method = "peer";
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
}

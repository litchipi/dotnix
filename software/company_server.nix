{ config, lib, pkgs, inputs, system, ... }:
let
  company_name="tyf";

  libnc = import ../lib/services/nextcloud.nix { inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix { inherit config lib pkgs;};

  persowebsite = {
    user = "op_persowebsite";
    port = 8095;
    dbname = "persowebsite";
    dir = "/www/posts";
  };
in
{
  base.user = "op";
  base.networking.ssh_auth_keys = [ "john" "tim" "restic_backup_ssh" ];
  base.networking.connect_wifi = [ "SFR_11EF" ];

  # TODO    FIXME   Doesn't work when using a custom domain name
  base.networking.domain = "localhost";

  cmn.server.enable = true;
  cmn.wm.enable = false;

  cmn.services.gitlab.enable = true;
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

  cmn.services.postgresql = {
    enable = true;
    users.${persowebsite.user} = {
      databases = [ persowebsite.dbname ];
      permissions.${persowebsite.dbname} = "ALL PRIVILEGES";
      # TODO  Find anothing thing than "trust" to put there
      auth_method = "trust";
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
            posts_dir = persowebsite.dir;
            spawnDatabase = false;
            database = {
              user = persowebsite.user;
              dbname = persowebsite.dbname;
              inherit (config.cmn.services.postgresql) port dir;
            };
          };
        in "${startup}";
        initScript = ''
          mkdir -p ${persowebsite.dir}
          chown +R ${persowebsite.user} ${persowebsite.dir}
        '';
        service_user = persowebsite.user;
        wait_service = [ "postgresql.service" ];
        port = persowebsite.port;
      };
    };
  };
}

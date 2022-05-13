{ config, lib, pkgs, ... }:
let
  lib_nc = import ../../lib/services/nextcloud.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../../lib/utils.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.nextcloud;

  nextcloud_secret = name: libdata.set_secret "nextcloud" ["services" "nextcloud" config.base.hostname name] {};

  nextcloud_apps = (lib.attrsets.mapAttrsToList (name: value:
    {
      inherit name;
      parents = ["services" "nextcloud"];
      default_enabled = if (builtins.elem name cfg.disable_apps)
        then false
        else (value.enable or true);
      cfg.services.nextcloud.extraApps."${name}" = pkgs.fetchNextcloudApp {
        inherit name;
        sha256 = value.sha256;
        url = value.url;
        version = value.version;
      };
    }));

 # {"1":{"id":1,"name":"Company site","url":"http:\/\/www.localhost","lang":"","type":"link","device":"","icon":"external.svg","groups":[],"redirect":false}}
  externalSite = lib.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the website";
      };
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL of the website";
      };
      lang = lib.mkOption {
        type = lib.types.str;
        description = "Langage of the website";
      };
      icon = lib.mkOption {
        type = lib.type.str;
        description = "Icon to use for the website";
        default = "external.svg";
      };
    };
  };
in
libconf.create_common_confs ([
  {
    name = "nextcloud";
    parents = [ "services" ];

    add_opts = {
      port = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Nextcloud server";
        default = 4006;
      };

      dbport = lib.mkOption {
        type = lib.types.int;
        description = "Port of the Nextcloud database";
        default = 4007;
      };

      dbhost = lib.mkOption {
        type = lib.types.str;
        description = "Host of the Nextcloud database";
        default = "localhost";
      };

      extra_config_script = lib.mkOption {
        type = lib.types.str;
        description = "Configuration script for the Nextcloud instance";
        default = "";
      };

      theme = lib.mkOption {
        type = lib.types.attrs;
        description = "Theme to set for the website";
        default = {
          name = null;
          logo = null;
          slogan = null;
          color = null;
          background = null;
          favicon = null;
          logoheader = null;
        };
      };

      disable_apps = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Apps to disable";
        default = [];
      };

      external_sites = lib.mkOption {
        type = with lib.types; listOf externalSite;
        description = "List of the external sites to add to the top bar";
        default = [];
      };
    };
    add_pkgs = with pkgs; [
      pkgs.php
    ];
    cfg = {
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40080; guest.port = 80; };
        https= { from = "host"; host.port = 40443; guest.port = 443; };
      };

      users.users."${config.base.user}".extraGroups = [ "nextcloud" "postgres" ];

      base.secrets = {
        nextcloud_adminpass = nextcloud_secret "adminpass";
      };

      services.nextcloud = {
        enable = true;
        hostName = "nextcloud.${config.base.networking.domain}";
        home = "/var/nextcloud/";
        appstoreEnable = true;
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          adminpassFile = config.base.secrets.nextcloud_adminpass.dest;
          adminuser = "root";
        };
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "nextcloud" ];
        ensureUsers = [
          {
            name = "nextcloud";
            ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
         }
        ];
      };

      # ensure that postgres is running *before* running the setup
      systemd.services."nextcloud-setup" = {
        requires = ["postgresql.service"];
        after = ["postgresql.service"];
      };

      systemd.services."nextcloud-configure" = {
        enable = true;
        description = "Set up configuration for the nextcloud instance";
        wantedBy = [ "multi-user.target" ];
        after = ["nextcloud-setup.service"];
        serviceConfig.Type = "oneshot";
        script = lib.strings.concatStringsSep "\n" [
          (lib_nc.set_theme cfg.theme)
          cfg.extra_config_script
          ''
            ${lib_nc.occ} app:enable encryption
          ''
          # TODO  Add external websites
        ];
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
  }
] ++ (nextcloud_apps {
  breezedark = {
    sha256 = "sha256-id0eZrkXe4PQchEfgT79HJtIuu/xaoTCNlw8XT34zZ8=";
    url = "https://github.com/mwalbeck/nextcloud-breeze-dark/releases/download/v23.2.1/breezedark.tar.gz";
    version = "23.2.1";
  };

  files_readmemd = {
    sha256 = "sha256-WQpSGdZLUoChfwB48Pe3MfesWtJEvIDM6ADI3IGF704=";
    url = "https://gitlab.univ-nantes.fr/uncloud/files_readmemd/-/wikis/uploads/7cc2ee379111ac18df99d674676dda98/files_readmemd.tar.gz";
    version = "1.2.2";
  };

  mail = {
    sha256 = "sha256-469nRFdKIW0e+CO1Py5l/guTZ2dhH+F1cknJZ4Pt3gg=";
    url = "https://github.com/nextcloud-releases/mail/releases/download/v1.11.7/mail-v1.11.7.tar.gz";
    version = "1.11.7";
  };

  spreed = {
    sha256 = "sha256-566oKMVRBjaZ69Ntg4zC7rjW01u0GF4RT4vJnzIl2Zk=";
    url = "https://github.com/nextcloud-releases/spreed/releases/download/v13.0.5/spreed-v13.0.5.tar.gz";
    version = "13.0.5";
  };

  tasks = {
    sha256 = "sha256-kXXUzzODi/qRi2NqtJyiS1GmLTx0kFAwtH1p0rCdnRM=";
    url = "https://github.com/nextcloud/tasks/releases/download/v0.14.4/tasks.tar.gz";
    version = "0.14.4";
  };

  files_mindmap = {
    sha256 = "sha256-GcJqn90n9+3VDndNuiohLMDx9fmmMyMkNVNb/bB7ksM=";
    url = "https://github.com/ACTom/files_mindmap/releases/download/v0.0.26/files_mindmap-0.0.26.tar.gz";
    version = "0.0.26";
  };

  files_markdown = {
    sha256 = "sha256-6vrPNKcPmJ4DuMXN8/oRMr/B/dTlJn2GGi/w4t2wimk=";
    url = "https://github.com/icewind1991/files_markdown/releases/download/v2.3.6/files_markdown.tar.gz";
    version = "2.3.6";
  };

  calendar = {
    sha256 = "sha256-jVJERWFPKj1ygFde+SSySdaRKSM67Rx2G9SQJBDbs5E=";
    url = "https://github.com/nextcloud-releases/calendar/releases/download/v3.2.2/calendar-v3.2.2.tar.gz";
    version = "3.2.2";
  };

  twofactor_totp = {
    sha256 = "sha256-r6WuXAvGXIEn6SViBxyMp98JBTWL6fR8MJDcdba1gA8=";
    url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.2.0/twofactor_totp.tar.gz";
    version = "6.2.0";
  };

  unsplash = {
    enable = false;
    sha256 = "sha256-UHdRoVpZvIDFiNrssuV1E9suzty0Aa1yIrseNh19xZI=";
    url = "https://github.com/nextcloud/unsplash/releases/download/v1.2.4/unsplash.tar.gz";
    version = "1.2.4";
  };

  drawio = {
    sha256 = "sha256-9UM3rXD4gqzx0DRPHf5Rpa6Bz/iG8muDPmn4YYdKRIQ=";
    url = "https://github.com/pawelrojek/nextcloud-drawio/releases/download/v.1.0.2/drawio-v1.0.2.tar.gz";
    version = "1.0.2";
  };

  apporder = {
    sha256 = "sha256-p3VWxTYDCO2NePq6oLM8tBVqYkvoB7itqxp7IZwGDnE=";
    url = "https://github.com/juliushaertl/apporder/releases/download/v0.15.0/apporder.tar.gz";
    version = "0.15.0";
  };

  files_downloadactivity = {
    sha256 = "sha256-JMJM0GL5zpaNUHIGl1J37JdZlhrdL0TBXD9++bB6nvM=";
    url = "https://github.com/nextcloud-releases/files_downloadactivity/releases/download/v1.13.0/files_downloadactivity-v1.13.0.tar.gz";
    version = "1.13.0";
  };

  epubreader = {
    sha256 = "sha256-J0iW+WiCY0XEALbECE7lChnUslIOcqSCKFcDa3ZCuj0=";
    url = "https://github.com/e-alfred/epubreader/releases/download/1.4.7/epubreader-1.4.7.tar.gz";
    version = "1.4.7";
  };

  integration_gitlab = {
    sha256 = "sha256-KSoBZmq/OzEcrKyifARVDR/9iEQwyrJhbqbmav0TOqk=";
    url = "https://github.com/nextcloud/integration_gitlab/releases/download/v1.0.3/integration_gitlab-1.0.3.tar.gz";
    version = "1.0.3";
  };

  jitsi = {
    sha256 = "sha256-aFwYQpb2WrPD00qPtCu5zGu0LlKFYdwZYTAmvX2li4o=";
    url = "https://pubcode.weimann.digital/downloads/projects/nextcloud-jitsi/builds/48/artifacts/nextcloud-jitsi.tar.gz";
    version = "0.15.0";
  };

  # appointments = {
  #   sha256 = "sha256-gnmUGZDYtPh+Z1dCEyEue0Cqzs1dA8teBZi3rIiZmBw=";
  #   url = "https://github.com/SergeyMosin/Appointments/raw/95c9fcb8ef495a032ac5f1ea58dfb47fca871e55/build/artifacts/appstore/appointments.tar.gz";
  #   version = "1.12.3";
  # };
  #
  approval = {
    sha256 = "sha256-SkkmWJbCSuJGav5BBP7yzvu1oV3r1UvNQQYyUEoDQXg=";
    url = "https://github.com/nextcloud/approval/releases/download/v1.0.9/approval-1.0.9.tar.gz";
    version = "1.0.9";
  };

  external = {
    sha256 = "sha256-nenSP0Ou8DXoL4el3xS2xjgCwuMG2yWzP/qIowJqrBU=";
    url = "https://github.com/nextcloud-releases/external/releases/download/v3.10.2/external-v3.10.2.tar.gz";
    version = "3.10.2";
  };

  polls = {
    sha256 = "sha256-bdKOfYcPqAqyrGkEAOjq6hrsfGLmxZ16p621dfN8tyM=";
    url = "https://github.com/nextcloud/polls/releases/download/v3.5.4/polls.tar.gz";
    version = "3.5.4";
  };

  collectives = {
    sha256 = "sha256-RO8iMzAMMa4aWMcKZ6U7datN+QP0wUolR+zB5COliXw=";
    url = "https://gitlab.com/collectivecloud/collectives/uploads/564c569f8832f344d44111aa0707ccc0/collectives-1.0.0.tar.gz";
    version = "1.0.0";
  };

  riotchat = {
  # Enabled in the configuration of the synapse service
    enable = false;
    sha256 = "sha256-BgemR0c9oFk2vGm5h17vpqhsHGneHEswBnwOpD98qSc=";
    url = "https://github.com/gary-kim/riotchat/releases/download/v0.11.3/riotchat.tar.gz";
    version = "0.11.3";
  };

  deck = {
    sha256 = "sha256-Ze20arex7AZhHnSWIPN8DlAtalp+/Rl7qwTA+IBv3vo=";
    url = "https://github.com/nextcloud-releases/deck/releases/download/v1.6.1/deck-v1.6.1.tar.gz";
    version = "1.6.1";
  };

  gestion = {
    sha256 = "sha256-NpMqRhL/o7RSA+79w38PMd6Ii7xkQGtzLZteTz8FXDQ=";
    url = "https://github.com/baimard/gestion/releases/download/2.0.11/gestion.tar.gz";
    version = "2.0.11";
  };

  news = {
    sha256 = "sha256-C9iM33RPYmeJZaVeaQc9+xLfFcRHgNBDsztJx7ENVWk=";
    url = "https://github.com/nextcloud/news/releases/download/18.0.1/news.tar.gz";
    version = "18.0.1";
  };
}))

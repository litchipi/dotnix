{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../../lib/utils.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.services.nextcloud;

  nextcloud_secret = name: libdata.set_secret "nextcloud" ["services" "nextcloud" config.base.hostname name] {};

  nextcloud_apps = (lib.attrsets.mapAttrsToList (name: value:
    {
      inherit name;
      parents = ["services" "nextcloud"];
      default_enabled = value.enable or true;
      cfg.services.nextcloud.extraApps."${name}" = pkgs.fetchNextcloudApp {
        inherit name;
        sha256 = value.sha256;
        url = value.url;
        version = value.version;
      };
    }));
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
    };
    add_pkgs = with pkgs; [
      nextcloud23
    ];
    cfg = {
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40080; guest.port = 80; };
        https= { from = "host"; host.port = 40443; guest.port = 443; };
      };

      base.secrets = {
        nextcloud_dbpass = nextcloud_secret "dbpass";
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
         { name = "nextcloud";
           ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
         }
        ];
      };

      # ensure that postgres is running *before* running the setup
      systemd.services."nextcloud-setup" = {
        requires = ["postgresql.service"];
        after = ["postgresql.service"];
      };

      networking.firewall.enable = false; #allowedTCPPorts = [ 80 443 ];
    };
  }
] ++ (nextcloud_apps {
  breeze-dark = {
    sha256 = "sha256-id0eZrkXe4PQchEfgT79HJtIuu/xaoTCNlw8XT34zZ8=";
    url = "https://github.com/mwalbeck/nextcloud-breeze-dark/releases/download/v23.2.1/breezedark.tar.gz";
    version = "23.2.1";
  };

  cospend = {
    sha256 = "sha256-Kjgd5m2fZIExvZ09kq4aVM32CzL6U2PM/wvB6+Dn/e8=";
    url = "https://github.com/eneiluj/cospend-nc/releases/download/v1.4.6/cospend-1.4.6.tar.gz";
    version = "1.4.6";
  };

  readme_md = {
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

  mind-maps = {
    sha256 = "sha256-GcJqn90n9+3VDndNuiohLMDx9fmmMyMkNVNb/bB7ksM=";
    url = "https://github.com/ACTom/files_mindmap/releases/download/v0.0.26/files_mindmap-0.0.26.tar.gz";
    version = "0.0.26";
  };

  markdown-editor = {
    sha256 = "sha256-6vrPNKcPmJ4DuMXN8/oRMr/B/dTlJn2GGi/w4t2wimk=";
    url = "https://github.com/icewind1991/files_markdown/releases/download/v2.3.6/files_markdown.tar.gz";
    version = "2.3.6";
  };

  calendar = {
    sha256 = "sha256-jVJERWFPKj1ygFde+SSySdaRKSM67Rx2G9SQJBDbs5E=";
    url = "https://github.com/nextcloud-releases/calendar/releases/download/v3.2.2/calendar-v3.2.2.tar.gz";
    version = "3.2.2";
  };

  totp = {
    sha256 = "sha256-r6WuXAvGXIEn6SViBxyMp98JBTWL6fR8MJDcdba1gA8=";
    url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.2.0/twofactor_totp.tar.gz";
    version = "6.2.0";
  };

  splash = {
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

  shared-files-activities = {
    sha256 = "sha256-JMJM0GL5zpaNUHIGl1J37JdZlhrdL0TBXD9++bB6nvM=";
    url = "https://github.com/nextcloud-releases/files_downloadactivity/releases/download/v1.13.0/files_downloadactivity-v1.13.0.tar.gz";
    version = "1.13.0";
  };

  epubreader = {
    sha256 = "sha256-J0iW+WiCY0XEALbECE7lChnUslIOcqSCKFcDa3ZCuj0=";
    url = "https://github.com/e-alfred/epubreader/releases/download/1.4.7/epubreader-1.4.7.tar.gz";
    version = "1.4.7";
  };

  gitlab-integration = {
    sha256 = "sha256-KSoBZmq/OzEcrKyifARVDR/9iEQwyrJhbqbmav0TOqk=";
    url = "https://github.com/nextcloud/integration_gitlab/releases/download/v1.0.3/integration_gitlab-1.0.3.tar.gz";
    version = "1.0.3";
  };

  jitsi-integration = {
    sha256 = "sha256-zWJd8HhpmsvY7BgDDxqnWJoqDeq2ANxl/ExjX2voG5w=";
    url = "https://pubcode.weimann.digital/downloads/projects/nextcloud-jitsi/builds/42/artifacts/nextcloud-jitsi.tar.gz";
    version = "0.14.0";
  };

  appointments = {
    sha256 = "sha256-gnmUGZDYtPh+Z1dCEyEue0Cqzs1dA8teBZi3rIiZmBw=";
    url = "https://github.com/SergeyMosin/Appointments/raw/95c9fcb8ef495a032ac5f1ea58dfb47fca871e55/build/artifacts/appstore/appointments.tar.gz";
    version = "1.12.3";
  };

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

  rocketchat = {
    sha256 = "sha256-g8lou8QLltjwavxmtr7Afo+qb8scooVQGH7/rcNEcTw=";
    url = "https://files.nizu.io/rocketchat/rocketchat_nextcloud.tar.gz";
    version = "0.9.6";
    # Enabled in the configuration of the rocketchat service
    enable = false;
  };
}))

{ config, lib, pkgs, ... }:
let
  lib_nc = import ../../lib/services/nextcloud.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.services.nextcloud;
  sub = "nextcloud";

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

  all_nextcloud_apps = {
    breezedark = {
      sha256 = "sha256-2tBm45gh5VRKh+w5YcBGyuNB7EGIdBh67jSLfrq+4R4";
      url = v: "https://github.com/mwalbeck/nextcloud-breeze-dark/releases/download/v${v}/breezedark.tar.gz";
      version = "24.0.2";
    };

    files_readmemd = {
      sha256 = "sha256-/Cc8UCAXJH2F1ozOwh5jaG9xRJCllvvaZ9nvzmxXuvU";
      url = _: "https://gitlab.univ-nantes.fr/uncloud/files_readmemd/-/wikis/uploads/7cc2ee379111ac18df99d674676dda98/files_readmemd.tar.gz";
      version = "1.2.2";
    };

    mail = {
      sha256 = "sha256-945krvn6LNFSiOO5SEfVAnTKCSd+UoGhjvJ57cNq7bg";
      url = v: "https://github.com/nextcloud-releases/mail/releases/download/v${v}/mail-v${v}.tar.gz";
      version = "2.1.4";
    };

    tasks = {
      sha256="sha256-pbcw6bHv1Za+F351hDMGkMqeaAw4On8E146dak0boUo";
      url = v: "https://github.com/nextcloud/tasks/releases/download/v${v}/tasks.tar.gz";
      version = "0.14.5";
    };

    files_mindmap = {
      sha256 = "sha256-/u1H2QvyKfdGjelFAkLc3rRGQlm3T+OajAbpUF0+cdY";
      url = v: "https://github.com/ACTom/files_mindmap/releases/download/v${v}/files_mindmap-${v}.tar.gz";
      version = "0.0.27";
    };

    files_markdown = {
      sha256 = "sha256-vv/PVDlQOm7Rjhzv8KXxkGpEnyidrV2nsl+Z2fdAFLY";
      url = v: "https://github.com/icewind1991/files_markdown/releases/download/v${v}/files_markdown.tar.gz";
      version = "2.3.6";
    };

    calendar = {
      sha256 = "sha256-KALFhCNjofFQMntv3vyL0TJxqD/mBkeDpxt8JV4CPAM";
      url = v: "https://github.com/nextcloud-releases/calendar/releases/download/v${v}/calendar-v${v}.tar.gz";
      version = "4.1.0";
    };

    twofactor_totp = {
      sha256 = "sha256-zAPNugbvngXcpgWJLD78YAg4G1QtGaphx1bhhg7mLKE";
      url = v: "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v${v}/twofactor_totp-v${v}.tar.gz";
      version = "6.4.1";
    };

    unsplash = {
      enable = false;
      url = v: "https://github.com/nextcloud/unsplash/releases/download/v${v}/unsplash.tar.gz";
      version = "2.1.1";
    };

    files_downloadactivity = {
      sha256 = "sha256-YTJG4OSRN6cgRdHfQ3qsTcjQ998Znf7hKYkXY8GaXz8";
      url = v: "https://github.com/nextcloud-releases/files_downloadactivity/releases/download/v${v}/files_downloadactivity-v${v}.tar.gz";
      version = "1.15.0";
    };

    integration_gitlab = {
      sha256 = "sha256-OY/eZ+WJlazfHyNozPcccB6CSzmn/4ZK2fB1IAeXs4I";
      url = v: "https://github.com/nextcloud/integration_gitlab/releases/download/v${v}/integration_gitlab-${v}.tar.gz";
      version = "1.0.10";
    };

    # TODO FIXME
    # jitsi = {
    #   url = v: "https://pubcode.weimann.digital/downloads/projects/nextcloud-jitsi/builds/48/artifacts/nextcloud-jitsi.tar.gz";
    #   version = "0.15.0";
    # };

    approval = {
      sha256 = "sha256-FJYMquvrsj6pZyVzhH+twC6YcQXlbnrILmckXUzZisw";
      url = v: "https://github.com/nextcloud/approval/releases/download/v${v}/approval-${v}.tar.gz";
      version = "1.0.10";
    };

    external = {
      sha256 = "sha256-sRJVuUV4ZzsB1fVh7r0qwMBVgOfurc0oLJnVZWh3b3s";
      url = v: "https://github.com/nextcloud-releases/external/releases/download/v${v}/external-v${v}.tar.gz";
      version = "5.0.0";
    };

    polls = {
      sha256 = "sha256-OTCv4vy3yuyEBU8EuljiHamt925i+tDKgGER+2HiTB4";
      url = v: "https://github.com/nextcloud/polls/releases/download/v${v}/polls.tar.gz";
      version = "4.0.0";
    };

    collectives = {
      sha256 = "sha256-LsIH+7XdoidKfg7hCVX4ugJye0axvYj7HdspVCgLXNw";
      url = v: "https://gitlab.com/collectivecloud/collectives/uploads/cfa8755adfd38e8208f4f960fca2e0a5/collectives-${v}.tar.gz";
      version = "2.1.1";
    };

    riotchat = {
      # Enabled in the configuration of the conduit service
      enable = false;
      sha256 = "sha256-1CYXXSP8f2tmHsguXWusOm2nkwF+HbazEeMvepIF0K8=";
      url = v: "https://github.com/gary-kim/riotchat/releases/download/v${v}/riotchat.tar.gz";
      version = "0.13.11";
    };

    deck = {
      sha256 = "sha256-96ECROnw0qKGA3jH9YhYfOyPr6Y5iPVVnheOpHjky6Y";
      url = v: "https://github.com/nextcloud-releases/deck/releases/download/v${v}/deck-v${v}.tar.gz";
      version = "1.8.2";
    };

    gestion = {
      sha256 = "sha256-MvQk5eo1p5AlMYZtNWN09iEzlSJbJ9W+Wd1zjd4XP0M";
      url = v: "https://github.com/baimard/gestion/releases/download/${v}/gestion.tar.gz";
      version = "2.2.2";
    };

    news = {
      sha256 = "sha256-Fx8QKR/UKAhcWtqBcinecE0tlPGFXG9kVBPnTdXX16k";
      url = v: "https://github.com/nextcloud/news/releases/download/${v}/news.tar.gz";
      version = "19.0.0";
    };
  };
in
  {
    options.services.nextcloud = {
      secrets = lib.mkOption {
        type = lib.types.attrsets;
        description = "Secrets for the service Nextcloud";
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
    config = {
      environment.systemPackages = [ pkgs.php ];

      base.networking.subdomains = [ sub ];
      base.networking.vm_forward_ports = {
        http = { from = "host"; host.port = 40080; guest.port = 80; };
        https= { from = "host"; host.port = 40443; guest.port = 443; };
      };

      users.users."${config.base.user}".extraGroups = [ "nextcloud" "postgres" ];
      users.users.nextcloud.extraGroups = [ "postgres" ];

      secrets.store.services.nextcloud = libdata.set_common_secret_config {
        user = config.services.nextcloud.user;
      } config.secrets.store.services.nextcloud;

      services.postgresql = {
        enable = true;
        ensureDatabases = ["nextcloud"];
        ensureUsers = [{
          name = "nextcloud";
          ensurePermissions = {
            "DATABASE nextcloud" = "ALL PRIVILEGES";
          };
        }];
        authentication = ''
          local nextcloud nextcloud peer
        '';
      };

      services.backup.restic.global.backup_paths = [
        "${cfg.home}/data"
      ];

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud25;
        hostName = "${sub}.${config.base.networking.domain}";
        home = lib.mkDefault "/var/lib/nextcloud/";
        appstoreEnable = lib.mkDefault true;
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql:${builtins.toString config.services.postgresql.port}";
          dbname = "nextcloud";
          adminuser = "root";
          adminpassFile = cfg.secrets.admin_pwd.file;
        };
        extraApps = builtins.mapAttrs (name: app: pkgs.fetchzip {
          inherit name;
          url = app.url app.version;
          sha256 = app.sha256 or lib.fakeSha256;
        }) all_nextcloud_apps;
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

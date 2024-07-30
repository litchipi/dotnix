{ config, pkgs, pkgs_unstable, ... }:
{
  imports = [
    ../common/system/server.nix
    ../common/system/backup.nix
    ../common/system/nixcfg.nix
    ../common/system/maintenance.nix
    ../common/services/paperless.nix
    ../common/services/firefly.nix
    ../common/services/firefly_data_importer.nix
    ../common/services/forgejo.nix
    ../common/services/forgejo-runner.nix
    ../common/services/nas.nix
    ../common/services/mealie.nix
    ../common/services/ifm.nix
    ../common/services/radicale.nix
    ../common/software/shell/helix.nix
    ../common/software/shell/tui.nix
    ../common/software/backup-fetcher.nix
  ];

  base.user = "op";
  base.email = "litchi.pi@proton.me";
  base.networking.ssh_auth_keys = [ "john@sparta" ];
  networking.interfaces.enp2s0.ipv4.addresses = [
    { address = "192.168.1.163"; prefixLength = 24; }
  ];
  server.full = true;

  networking.firewall.allowedTCPPorts = [ 8080 ];
  networking.hosts = {
    "127.0.0.1" = [ "suzie.local" "suzie.remote"];
  };
  services.avahi.enable = false;

  environment.systemPackages = with pkgs; [
    gcc
    (pkgs_unstable.rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" ];
    })
  ];

  services.paperless = {
    enable = true;
    package = pkgs_unstable.paperless-ngx;
    backup = true;
    port = 8081;
    secrets = config.secrets.store.services.paperless.${config.base.hostname};
  };

  services.firefly-iii = {
    enable = true;
    backup = true;
    port = 8082;
    secrets = config.secrets.store.services.firefly.${config.base.hostname};
    data-importer = {
      enable = true;
      port = 8087;
      settings.FIREFLY_III_URL = "http://suzie.local:8082";
      settings.FIREFLY_III_CLIENT_ID = 2;
    };
  };

  services.nas = {
    enable = true;
    rootPath = "/data/nas";
    usernameMap.${config.base.user} = "john";
  };

  # TODO  Module overlay
  secrets.setup.forgejo = {
    user = config.services.forgejo.user;
    secret = config.secrets.store.services.forgejo.${config.base.hostname};
  };
  services.forgejo = {
    enable = true;
    settings = {
      server = rec {
        HTTP_PORT = 8083;
        ROOT_URL = "http://suzie.local:${builtins.toString HTTP_PORT}";
      };
      webhook.ALLOWED_HOST_LIST = "*";
    };
    secrets = config.secrets.store.services.forgejo.${config.base.hostname};
    backup = true;
    lfs.contentDir = "/data/forgejo-lfs";
  };

  services.forgejo-runners = {
    enable = true;
    tokenFile = config.secrets.store.services.forgejo-runner.${config.base.hostname}.token;
    baseDir = "/data/forgejo-runners";
    labels = {
      nix = {
        repo = "nixos/nix";
        versions = [ "latest" "2.19.2" ];
      };
      ubuntu = {
        repo = "ubuntu";
        versions = [ "latest" "22.04" "23.04" "23.10"];
      };
      # TODO  Add Windows and MacOS here
    };
  };

  services.mealie = {
    enable = true;
    port = 8084;
    secrets = config.secrets.store.services.mealie.suzie;
    backup = true;
  };

  services.radicale = {
    enable = true;
    port = 8085;
    secrets = config.secrets.store.services.radicale.suzie;
    backup = true;
  };

  services.ifm = {
    enable = true;
    port = 8086;
    dataDir = "/data/nas";
  };

  # TODO Vikunja (+ backup) -> Or other kind of software for this
  # services.vikunja = {
  #   enable = true;
  # };

  # TODO  Set up overlay with backup enabled
  users.users.${config.services.jellyfin.user}.extraGroups = ["nas"];
  services.jellyfin = {
    enable = true;
    logDir = "/var/lib/jellyfin/log";
    configDir = "/var/lib/jellyfin/config";
    dataDir = "/var/lib/jellyfin";
    # Ports taken: 8096 8920
    openFirewall = true;
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    listenPort = 8088;

    services = [{ "Main" = [
      { "Paperless" = {
        description = "Document management system";
        href = "http://suzie.local:8081/";
        icon = "paperless.svg";
      }; }
      { "Firefly III" = {
        description = "Money management platform";
        href = "http://suzie.local:8082";
        icon = "firefly.png";
      }; }
      { "Firefly data importer" = {
        description = "Data importer for Firefly-iii";
        href = "http://suzie.local:8087";
        icon = "mdi-database-refresh";
      }; }
      { "Forgejo" = {
        description = "Code forging platform";
        href = "http://suzie.local:8083";
        icon = "forgejo.svg";
      }; }
      { "Mealie" = {
        description = "Meal planning and recipes scraper";
        href = "http://suzie.local:8084";
        icon = "mealie.svg";
      }; }
      { "Radicale" = {
        description = "CalDAV contacts addressbook server";
        href = "http://suzie.local:8085";
        icon = "radicale.svg";
      }; }
      { "IFM" = {
        description = "Improved File Manager, a web-based file manager";
        href = "http://suzie.local:8086";
        icon = "mdi-text-box";
      }; }
      { "Jellyfin" = {
        description = "Selfhosted Netflix";
        href = "http://suzie.local:8096";
        icon = "jellyfin.svg";
      }; }
    ];}];

    settings = {
      title = "Suzie homelab";
      background = {
        # TODO  Put this somewhere directly on suzie ?
        image = "https://vsthemes.org/uploads/posts/2022-04/1650638025_22-04-2022-19_32_45.webp";
        blur = "sm";
        opacity = 75;
        brightness = 50;
      };
      theme = "dark";
      color = "stone";
      headerStyle = "clean";
      language = "fr";
      target = "_blank";
      layout."Main" = {
        style = "row";
        columns = 4;
      };
    };

    widgets = [
      { resources = {
        label = "System";
        cpu = true;
        disk = "/";
        memory = true;
        uptime = true;
        cputemp = true;
      }; }
      { search = {
        provider = "duckduckgo";
        showSearchSuggestions = true;
        target = "_self";
      }; }
      { resources = {
        label = "Nix Store";
        disk = "/nix/store";
      }; }
      { resources = {
        label = "NAS";
        expanded = true;
        disk = "/data";
      }; }
    ];

    customJS = ''
    '';

    customCSS = ''
    '';
  };

  nix.ecospace = {
    gc-enable = true;
    olderthan = "15d";
    freq = "daily";
  };

  base.networking.add_dns = [
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

  backup.base_dir = "/data/backup";
  backup.services = let
    rcloneConf = config.secrets.store.backup.rclone.owncloud;
  in {
    global = {
      user = config.base.user;
      secrets = config.secrets.store.backup.suzie;
      timerConfig.OnCalendar = "02/5:00:00";
      pruneOpts = ["-y 10" "-m 12" "-w 4" "-d 30" "-l 5"];
      pathsFromFile = "/home/${config.base.user}/.backuplist";
      inherit rcloneConf;
    };
    paperless.rcloneConf = rcloneConf;
    forgejo.rcloneConf = rcloneConf;
    radicale.rcloneConf = rcloneConf;
    firefly-iii.rcloneConf = rcloneConf;
    mealie.rcloneConf = rcloneConf;
  };

  services.backup-fetcher = {
    enable = true;
    fetchers = {
      litchipiBlog = {
        timerConfig.OnCalendar = "02/5:00:00";
        runtimeDeps = [ pkgs.gzip pkgs.gawk ];
        outputFile = "/data/backup/blog.zip";
        sshTarget = "john@litchipi.site";
        paths = [
          "/etc/systemd/system/log_rotate.service"
          "/etc/systemd/system/log_rotate.timer"
          "/etc/systemd/system/fetch_blog_posts.service"
          "/etc/systemd/system/fetch_blog_posts.timer"
          "/etc/systemd/system/blog.service"
          "/var/www/ecoweb/start.sh"
          "/var/www/uploads/"
          "/home/john/update_ecoweb_bin.sh"
          "/home/john/update_blog_content.sh"
          "/home/john/log_rotate.sh"
          "/home/john/logs/"
          "/var/log/nginx/*"
          "/etc/nginx/sites-available/default"
        ];

        exitTargetScript = ''
          rm -f /home/john/logs/*
        '';

        beforeCompressScript = ''
          mv default ./nginx_conf
          mkdir -p nginx
          gunzip *.gz
          for f in $(ls access.log*); do
            fdate=$(head -n 1 "$f" | awk '{print $4}'|cut -d '[' -f 2|tr '/' '_'|tr ':' '_')
            mv "$f" "./nginx/access_$fdate.log"
          done

          for f in $(ls error.log*); do
            fdate=$(head -n 1 "$f" | awk '{print $1 "_" $2}' | tr '/' '_' | tr ':' '_')
            mv "$f" "./nginx/error_$fdate.log"
          done
        '';
      };

      spartaLaptop = {
        timerConfig.OnCalendar = "02/5:00:00";
        outputFile = "/data/backup/sparta.zip";
        sshTarget = "john@sparta.local";
        paths = [
          "/data/Backups/system"
        ];
      };
    };
  };

  # TODO  Factorize on the backup common module, with a "global" option
  environment.interactiveShellInit = ''
    addbackup() {
      for arg in "$@"; do
        realpath "$arg" >> /home/${config.base.user}/.backuplist
      done
    }
  '';

  maintenance = {
    enable = true;
    flakeUpdateAll.enable = true;
    nixosUpgrade.enable = true;
    nixStoreOptimize.enable = true;
  };
}

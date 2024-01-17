{ config, pkgs, pkgs_unstable, ... }:
{
  imports = [
    ../common/system/server.nix
    ../common/system/backup.nix
    ../common/system/nixcfg.nix
    ../common/services/paperless.nix
    ../common/services/shiori.nix
    ../common/services/forgejo.nix
    ../common/services/forgejo-runner.nix
    ../common/software/shell/helix.nix
  ];

  # TODO Vikunja (+ backup) -> Or other kind of software for this
  # TODO Auto-backup remote website
  # TODO Auto system update + reboot

  base.user = "op";
  base.email = "litchi.pi@proton.me";
  base.networking.ssh_auth_keys = [ "john@sparta" ];
  networking.interfaces.enp2s0.ipv4.addresses = [
    { address = "192.168.1.163"; prefixLength = 24; }
  ];

  environment.systemPackages = [ #with pkgs; [
    # zenith
    (pkgs_unstable.rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" ];
    })
  ];

  # TODO  IMPORTANT  Wire this to Google drive rclone
  backup.base_dir = "/data/backup";
  backup.services.global = {
    user = config.base.user;
    secrets = config.secrets.store.backup.suzie;
    timerConfig.OnCalendar = "02/5:00:00";
    pruneOpts = ["-y 10" "-m 12" "-w 4" "-d 30" "-l 5"];
    pathsFromFile = "/home/${config.base.user}/.backuplist";
  };

  services.paperless = {
    enable = true;
    package = pkgs_unstable.paperless-ngx;
    backup = true;
    port = 8081;
    secrets = config.secrets.store.services.paperless.${config.base.hostname};
  };

  services.shiori = {
    enable = true;
    backup = true;
    port = 8082;
    secrets = config.secrets.store.services.shiori.${config.base.hostname};
  };

  # TODO Samba module
  users.groups.nas = {};
  users.users.${config.base.user}.extraGroups = [ "nas" ];
  setup.directories = [
    {
      path = config.services.samba.shares.default.path;
      owner = "root";
      group = "nas";
    }
  ];
  services.samba = {
    enable = true;
    openFirewall = true;
    shares.default = {
      path = "/data/nas";
      "read only" = false;
      browseable = true;
      "guest ok" = false;
      comment = "NAS of suzie";
      "create mask" = "0660";
      "directory mask" = "0770";
    };
    extraConfig = let
      username_map = pkgs.writeText "samba_username_map" ''
        ${config.base.user}=john
      '';
    in ''
    username map = ${username_map}
    '';
  };

  # TODO  Module overlay
  secrets.setup.forgejo = {
    user = config.services.forgejo.user;
    secret = config.secrets.store.services.forgejo.${config.base.hostname};
  };
  services.forgejo = {
    enable = true;
    settings.server.HTTP_PORT = 8083;
    secrets = config.secrets.store.services.forgejo.${config.base.hostname};
    backup = true;
    lfs.contentDir = "/data/forgejo-lfs";
  };

  # TODO Forgejo runners
  # - Test forgejo runners on suzie
  # - Have to provide a TOKEN first in the secrets
  # TODO  Create a CI workflow to test this repository every time
  services.forgejo-runners = {
    enable = true;
    tokenFile = config.secrets.store.services.forgejo-runner.${config.base.hostname}.token;
    labels = {
      nix = {
        repo = "nixos/nix";
        versions = [ "latest" "2.19.2" ];
      };
      ubuntu = {
        repo = "ubuntu";
        versions = [ "latest" "22.04" "23.04" "23.10"];
      };
      rust = {
        repo = "cimg/rust";
        versions = ["1.75.0" "1.72.0" "1.70.0" "1.65.0" "1.60.0"];
      };
      python = {
        repo = "cimg/python";
        versions = ["3.10" "3.11" "3.12"];
      };
    };
  };

  services.mealie = {
    enable = true;
    port = 8084;
  };

  # services.vikunja = {
  #   enable = true;
  # };

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

  software.tui.jrnl.editor = "hx";
}

{ config, pkgs, pkgs_unstable, inputs, ... }:
{
  imports = [
    ../common/system/nixcfg.nix
    ../common/services/paperless.nix
    ../common/services/shiori.nix
    ../common/services/forgejo.nix
    # ../common/software/shell/tui.nix
    # ../common/software/shell/helix.nix
    ../common/system/backup.nix
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

  environment.systemPackages = with pkgs; [
    # zenith
  ];

  backup.base_dir = "/data/backup";

  networking.firewall.allowedTCPPorts = [
    config.services.paperless.port
    config.services.shiori.port
    config.services.forgejo.settings.server.HTTP_PORT
  ];

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
      perms = "0770";
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

  # TODO Forgejo runners
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

  # TODO  IMPORTANT  Wire this to Google drive rclone
  # TODO FIXME Secret doesn't exist
  #  Use the same format as used with sparta
  services.restic.backups.global = {
    initialize = true;
    user = config.base.user;
    dynamicFilesFrom = "cat /home/${config.base.user}/.backup_list";
    passwordFile = config.secrets.store.services.restic.${config.base.hostname}.restic_repo_pwd.file;
    repository = "${config.backup.base_dir}/${config.base.user}";
    timerConfig = {
      Persistent = true;
      OnCalendar = "02/5:00:00";
    };
    pruneOpts = ["-y 10" "-m 12" "-w 4" "-d 30" "-l 5"];
  };
}

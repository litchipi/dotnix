{ config, pkgs, ... }:
let
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
  imports = [
    ../common/services/gitlab.nix
    ../common/services/gitlab_runner.nix
    ../common/services/restic.nix
    ../common/services/shiori.nix
    ../common/services/paperless.nix
    ../common/services/grafana.nix
    ../common/services/prometheus.nix
    ../common/services/blocky.nix
    ../common/system/server.nix
    ../common/system/nixcfg.nix
  ];

  base.user = "op";
  base.email = "litchi.pi@proton.me";
  base.networking.ssh_auth_keys = [ "john@sparta" "tim@diamond" ];

  base.networking.domain = "orionstar.cyou";
  base.networking.static_ip_address = "192.168.1.163";

  environment.systemPackages = with pkgs; [
    zenith
  ];

  services.gitlab = {
    enable = true;
    secret-store = config.secrets.store.services.gitlab.${config.base.hostname};
    backup = {
      gdrive = true;
      timerConfig.OnCalendar = "05/7:00:00";
      inherit external_copy;
    };
  };

  services.gitlab-runner = {
    enable = true;
    secrets = config.secrets.store.services.gitlab.${config.base.hostname};
    runner-images = {
      debian = {
        runnerOpts.dockerImage = "debian:stable-20221024-slim";
      };
    };
    add_nix_service = true;
  };

  services.backup.restic.global = {
    gdrive = true;
    timerConfig.OnCalendar = "02/5:00:00";
    backup_paths = [ "/home/${config.base.user}/" ];
    inherit external_copy;
  };

  services.shiori = {
    enable = true;
    secrets = config.secrets.store.services.shiori.${config.base.hostname};
    backup = {
      gdrive = true;
      inherit external_copy;
    };
  };

  services.paperless = {
    enable = true;
    secrets = config.secrets.store.services.paperless.${config.base.hostname};
    backup = {
      gdrive = true;
      inherit external_copy;
    };
  };

  nix.ecospace = {
    gc-enable = true;
    olderthan = "15d";
    freq = "daily";
  };

  services.blocky.enable = true;

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

  services.prometheus.enable = true;
  services.grafana = {
    enable = true;
    secrets = config.secrets.store.services.grafana.${config.base.hostname};
  };
}

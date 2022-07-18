{ config, lib, pkgs, ... }:
let
  company_name="tyf";

  libnc = import ../lib/services/nextcloud.nix { inherit config lib pkgs;};
in
{
  base.user = "op";
  base.hostname = "${company_name}";
  base.networking.ssh_auth_keys = [ "john" "tim" "restic_backup_ssh" ];
  base.networking.connect_wifi = [ "SFR_11EF" ];
  base.disks.add_swapfile = 2000;

  cmn.server.enable = true;
  # TODO  Investigate 502 timeout error
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

  cmn.services.web_hosting = {
    enable = true;
    websites."www".package = pkgs.litchipi.tyf_website;
    applications."app" = rec {
      add_pkgs = [ pkgs.litchipi.webapp ];
      command = "app -p ${builtins.toString port}";
      port = 8189;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };

    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_rpi3;

  boot.kernelParams = [
    "console=ttyS1,115200n8"
  ];
  boot.loader.raspberryPi = {
    enable = true;
    version = 3;
  };
}

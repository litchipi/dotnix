{ config, lib, pkgs, ... }:
let
  company_name="tyf";
in
{
  base.user = "op";
  base.hostname = "${company_name}";
  base.networking.ssh_auth_keys = [ "john" "tim" "restic_backup_ssh" ];

  cmn.server.enable = true;
  # TODO  Investigate 502 timeout error
  cmn.services.gitlab.enable = true;

  cmn.services.conduit.enable = true;

  cmn.services.nextcloud = {
    enable = true;

    theme = {
      name = company_name;
      logo = ../data/assets/nextcloud/${company_name}/logo.svg;
      favicon = ../data/assets/nextcloud/${company_name}/logo.svg;
      logoheader = ../data/assets/nextcloud/${company_name}/logo.svg;
      background = ../data/assets/nextcloud/${company_name}/background.jpg;
      slogan = "Where beer really matters";
      color = "#6E1852";
    };

    disable_apps = [
      "photos"
    ];
  };

  # TODO  Serve company website
  # cmn.services.website = {
  #   enable = true;
  #   derivation = pkgs.litchipi.website;
  # };

  base.add_pkgs = with pkgs; [
    cowsay
  ];
}

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

  # TODO Create a Jitsi-meet service and configure Nextcloud to use it
  # https://search.nixos.org/options?channel=21.11&from=0&size=50&sort=relevance&type=packages&query=jitsi-meet

  # TODO  Add protonmail-bridge to server and use it to serve Nextcloud Mail

  # TODO Set up restic backup
  # Additionnal packages to install
  base.add_pkgs = with pkgs; [
    cowsay
  ];
}

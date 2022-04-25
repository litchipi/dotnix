{ config, lib, pkgs, ... }:
let
  company_name="tyf";
in
{
  # The name of the main user of the system
  base.user = "op";

  # The system hostname
  base.hostname = "${company_name}";

  # What SSH key to allow for remote login
  #   (has to be a file in data/ssh/pubkeys/<name>.pub)
  base.networking.ssh_auth_keys = [ "john" "tim" ];

  cmn.server.enable = true;
  # TODO  Investigate 502 timeout error
  # cmn.services.gitlab.enable = true;

  cmn.services.nextcloud = {
    enable = true;

    # TODO Pimp theming from here
    theme = {
      name = company_name;
      logo = ../data/assets/tyf/logo.png;
      slogan = "Where beer really matters";
      color = "#9A2462";
      background = ../data/assets/tyf/background.jpg;
      favicon = ../data/assets/tyf/favicon.png;
    };
  };

  # Additionnal packages to install
  base.add_pkgs = with pkgs; [
    wget
    cowsay
  ];
}

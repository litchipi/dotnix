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
  cmn.services.nextcloud = let
    occ = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
  in {
    enable = true;
    # TODO Pimp theming from here
    # https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/theming.html?highlight=logo
    configuration_script = ''
      ${occ} theming:config logo ${../data/assets/tyf/logo.jpg}
    '';
  };

  # Additionnal packages to install
  base.add_pkgs = with pkgs; [
    wget
    cowsay
  ];
}

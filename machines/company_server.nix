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
  #
  cmn.server.enable = true;
  cmn.services.gitlab.enable = true;
  cmn.services.nextcloud.enable = true;

  # Additionnal packages to install
  base.add_pkgs = with pkgs; [
    wget
    cowsay
  ];
}

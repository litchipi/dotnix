{ config, lib, pkgs, ... }:
{
  base.user = "op";
  base.networking.ssh_auth_keys = [ "john" "tim" ];

  # TODO  Adapt this configuration to new restic service definition
  cmn.server.enable = true;
  cmn.services.restic.from_remote = {
    enable = true;
    targets.orion3 = {
      user = "john";
      host = "185.167.99.178"; #orionstar.cyou";
      ssh_host_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2iho7IJHVASGV6m9jqHLTQDePx4RAGaVSd2+FZLbkh";
      remote_dirs_backup = [
        "/home/john/"
        # "/var/nextcloud"
        # "/var/gitlab"
      ];
      backup_timer = "*:0/5";
    };
  };
}

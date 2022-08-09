{ config, lib, pkgs, ... }:
let
  company_name="tyf";

  libnc = import ../lib/services/nextcloud.nix { inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix { inherit config lib pkgs;};
in
{
  base.user = "op";
  base.hostname = "${company_name}";
  base.networking.ssh_auth_keys = [ "john" "tim" "restic_backup_ssh" ];
  base.networking.connect_wifi = [ "SFR_11EF" ];

  # TODO    FIXME   Doesn't work when using a custom domain name
  base.networking.domain = "localhost";

  cmn.server.enable = true;
  cmn.wm.enable = false;

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
}

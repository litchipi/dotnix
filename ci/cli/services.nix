machines: { config, lib, pkgs, ... }: {
  cmn.services.gitlab = machines.suzie.cmn.services.gitlab // {
    backup.gdrive = false;
  };
  cmn.services.conduit.enable = machines.suzie.cmn.services.conduit.enable;
  cmn.services.nextcloud = machines.suzie.cmn.services.nextcloud // {
    theme = {};
  };
}

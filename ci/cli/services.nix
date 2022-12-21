machines: { config, lib, pkgs, ... }: {
  cmn.services.gitlab = machines.suzie.cmn.services.gitlab // {
    backup.gdrive = false;
  };
  cmn.services.paperless = machines.suzie.cmn.services.paperless;
  cmn.services.conduit.enable = machines.suzie.cmn.services.conduit.enable;
  cmn.services.nextcloud = machines.suzie.cmn.services.nextcloud // {
    theme = {};
  };
  cmn.nix.builders.setup = machines.suzie.cmn.nix.builders.setup;
}

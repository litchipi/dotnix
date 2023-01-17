machines: { ... }: {
  base.networking.static_ip_address = machines.suzie.base.networking.static_ip_address;

  cmn.nix.builders.setup = machines.suzie.cmn.nix.builders.setup;

  cmn.services = machines.suzie.cmn.services // {
    nextcloud.theme = {};
  };
}

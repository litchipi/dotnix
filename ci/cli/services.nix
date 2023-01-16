machines: { ... }: {
  base.networking.static_ip_address = machines.suzie.base.networking.static_ip_address;

  cmn.nix.builders.setup = machines.suzie.cmn.nix.builders.setup;
  cmn.services.restic.global = machines.suzie.cmn.services.restic.global;
  cmn.services.gitlab = machines.suzie.cmn.services.gitlab;
  cmn.services.shiori = machines.suzie.cmn.services.shiori;
  cmn.services.paperless = machines.suzie.cmn.services.paperless;
  cmn.services.conduit = machines.suzie.cmn.services.conduit;
  cmn.services.nextcloud = machines.suzie.cmn.services.nextcloud // { theme = {}; };
  cmn.services.dns.blocky = machines.suzie.cmn.services.dns.blocky;
}

machines: { config, lib, pkgs, inputs, system, ... }: {
  cmn.services.postgresql = machines.suzie.cmn.services.postgresql;
  cmn.services.web_hosting = machines.suzie.cmn.services.web_hosting;
}

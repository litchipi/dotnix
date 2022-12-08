machines: { config, lib, pkgs, ... }: {
  cmn.services.cachix.client = machines.sparta.cmn.services.cachix.client;
  cmn.nix.builders.remote = machines.sparta.cmn.nix.builders.remote;
}

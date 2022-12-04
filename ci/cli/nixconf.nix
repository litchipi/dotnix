machines: { config, lib, pkgs, ... }: let
  libcachix = import ../../lib/services/cachix.nix { inherit config lib pkgs; };
in {
  # TODO  Add builder nix settings
  cmn.services.cachix.client = machines.sparta.cmn.services.cachix.client;
}

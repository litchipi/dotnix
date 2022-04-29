{ stdenv, lib, pkgs, ... }:
let
  src = ./app; # fetchGit here if stored in remote
  cargoNix = import "${src}/Cargo.nix" { inherit pkgs; };
in
  cargoNix.rootCrate.build

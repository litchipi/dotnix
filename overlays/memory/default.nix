# https://discourse.nixos.org/t/adding-folders-and-scripts/5114/3
{ stdenv, lib, pkgs, ... }:
stdenv.mkDerivation rec {
  pname = "litchipi.memory";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner  = "litchipi";
    repo   = "Memory";
    rev    = "9290e21b70c7fc48322eb6baa6edc0ffb4f10ace";
    sha256 = "sha256-jZ/oZiwCSj9OhJSm20dHejiYHA9rOesC+08BwMIzQYg=";
  };

  buildInputs = with pkgs; [
    python39Full
    restic
    python39Packages.toml
  ];

  installPhase = ''
    . $stdenv/setup
    mkdir -p $out/bin
    ln -s ${src}/memory.py $out/bin/memory
  '';
}

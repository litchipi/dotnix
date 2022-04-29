{ stdenv, lib, pkgs, ... }:
stdenv.mkDerivation rec {
  pname = "litchipi.tyf_website";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    mkdir -p $out/
    echo "<!DOCTYPE html><html><body>Hello static website World!</body></html>" >> $out/index.html
  '';
}

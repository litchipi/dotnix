#https://github.com/adi1090x/plymouth-themes
{ stdenv, lib, pkgs, ... }:
stdenv.mkDerivation rec {
  pname = "litchipi.plymouth-themes";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner  = "adi1090x";
    repo   = "plymouth-themes";
    rev    = "bf2f570bee8e84c5c20caac353cbe1d811a4745f";
    sha256 = lib.fakeSha256;
  };

  buildInputs = [
    pkgs.plymouth
  ];

  installPhase = ''
    . $stdenv/setup
    ALL_THEMES=$(find $src -name "*.plymouth" | grep -v "template")
    for theme in $ALL_THEMES; do
      ln -sf $(dirname $theme) /usr/share/plymouth/themes/
    done
  '';
}

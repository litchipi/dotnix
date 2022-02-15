# https://discourse.nixos.org/t/adding-folders-and-scripts/5114/3
{ stdenv, lib, pkgs, ... }:
stdenv.mkDerivation rec {
  pname = "litchipi.pomodoro";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner  = "litchipi";
    repo   = "pomodoro.sh";
    rev    = "744133c890ba8447309fbc9c6de1c4e30f2ce9b9";
    sha256 = "B7XcdhUY3Iw9BUutSwlCCEbzdST/4t7TQaXTfz+gfso=";
  };

  buildInputs = [
    pkgs.gnome.zenity
    pkgs.mpv
  ];

  installPhase = ''
    . $stdenv/setup
    mkdir -p $out/bin
    ln -sf ${src}/pomodoro.sh $out/bin/pomodoro.sh
  '';
}

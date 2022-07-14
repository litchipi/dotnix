{ stdenv, lib, pkgs, ... }: let
  startupFile = ''
    /statusbar awl_0 add -before awl_0 -alignment left usercount
    /set neat_colors X30rRX61X6CX3CyX1DcCBX3HX2AbMX3AX42X6M
    /set theme nixos
    /set trackbar_string ―
    /set trackbar_style %r
  '';

  fetchscript = name: sha: pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/irssi/scripts.irssi.org/master/scripts/${name}.pl";
    sha256 = sha;
  };

  scripts = {
    dim_nicks = fetchscript "dim_nicks" "sha256-U0R0MT2lMIQSfrWpUgtBbPsS7KIXdENFBSj4aJxW6gQ=";
    adv_windowlist = fetchscript "adv_windowlist" "sha256-LgkNeHaOWONBPtUfCRFXyUalfpHpZHTeYFDuGN0GZHE=";
    nickcolor = fetchscript "nickcolor" "sha256-Ice18JORQiAdQ72T4c6f1A0U87fSM+SjaEci3H0WtsY=";
    openurl = fetchscript "openurl" "sha256-ak4PGs+AVI9I4srFlulm8uJ/4vRQFVNYCRR3klGVuKA=";
    trackbar = fetchscript "trackbar" "sha256-lCiWkFcVMvQ+OjQkbShYBn03xBk4imddI7Tq2rfQEMI=";
    usercount = fetchscript "usercount" "sha256-6397b0UOKYavdHJa6MSNkstEYGRHCz+pHo9YnrEriJ8=";
    revolve = fetchscript "revolve" "sha256-362JMTSdUomfEDQBkob68ENzov3NLJT4hsXKnXNQa4E=";
  };

in stdenv.mkDerivation rec {
  pname = "litchipi.irssitheme";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    . $stdenv/setup
    mkdir -p $out/ $out/scripts/autorun

  '' + (builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (name: s:
    "cp ${s} $out/scripts/autorun/${name}.pl"
    ) scripts)) + ''

    cp $src/nixos.theme $out/nixos.theme

    echo "${startupFile}" > $out/startup
  '';
}

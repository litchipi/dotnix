{ stdenv, lib, pkgs, ... }: let
  startupFile = ''
    /statusbar awl_0 add -before awl_0 -alignment left usercount
    /set neat_colors X30rRX61X6CX3CyX1DcCBX3HX2AbMX3AX42X6M
    /set theme nixos
    /set trackbar_string ―
    /set trackbar_style %r
  '';

  rev = "a3ad360011dc2b9093ff070ecfcbefd0a58c3d02";

  fetchscript = name: sha: pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/irssi/scripts.irssi.org/${rev}/scripts/${name}.pl";
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
    tmux-nicklist = fetchscript "tmux-nicklist-portable" "sha256-dnFaw5TETmJTA2DagaExr/mQCaYKFnyzvoJ3Mlho8mY";
    ignore_join_blob = fetchscript "ignore_join_blob" "sha256-kfNLvTiv1A+JtmiVhx13c/i3i8rFHw3ok0302TP33i8";
    urlwindow = fetchscript "urlwindow" "sha256-7lyNcEFUQcEY+OZrsBHoK0YVo9m3ZmiKvd0n2d54dc8";
    # chansearch = fetchscript "chansearch" "sha256-bTpU4DrXk1maGgkbWeFuGtRWdG8agaZWZGeUw5SbnVo=";
    complete_at = fetchscript "complete_at" "sha256-EEYThqwNV/NyXzYvohm7y4VqYCRSfbncefyNHd01WYE";
    history_search = fetchscript "history_search" "sha256-GfYypLHtzwbRvR+1yi5n0gIeXjrglaqwsIlhH0uLUow";
    colorswap = fetchscript "colorswap" "sha256-vmPcwwFFkrgv/V0Tl9Kdoad8GOb29d53I6OYyRu0tvI";
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

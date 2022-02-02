# https://discourse.nixos.org/t/adding-folders-and-scripts/5114/3
{ stdenv, lib, pkgs, ... }:

let
  myScript = pkgs.writeTextFile {
    name = "pomodoro";
    executable = true;
    destination = "/bin/pomodoro.sh";
    text = builtins.readFile ./pomodoro.sh;
  };
in stdenv.mkDerivation rec {
  pname = "litchipi.pomodoro";
  version = "0.0.1";

  buildInputs = [ myScript ];
  builder = pkgs.writeTextFile {
    name = "builder.sh";
    text = ''
      . $stdenv/setup
      mkdir -p $out/bin
      ln -sf ${myScript}/bin/pomodoro.sh $out/bin/pomodoro.sh
    '';
  };
}

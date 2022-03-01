{ config, lib, pkgs, ... }:
let 
  ip = a : b : c : d : {
    inherit a b c d;
    address = "${toString a}.${toString b}.${toString c}.${toString d}";
  };
in
{
  IpFromString = with lib; str :
    let
      splits1 = splitString "." str;
      splits2 = flatten (map (x: splitString "/" x) splits1);

      e = i : toInt (builtins.elemAt splits2 i);
    in
      ip (e 0) (e 1) (e 2) (e 3);
}

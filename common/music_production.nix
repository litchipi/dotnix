{ config, lib, pkgs, ... }:
let
  build_lib = import ../lib/build.nix {inherit config lib pkgs;};
  import_if = cond: pkgs: if cond then pkgs else [];
in
 build_lib.create_common_conf {
   name = "music_production";
   enable_flags = [ "electro" "guitar" "score" ];
 } {
   # Base
   environment.systemPackages = with pkgs; [
   ] ++

   # Electro
   import_if config.commonconf.music_production.electro.enable [
     lmms
     mixxx
   ] ++

   # Guitar
   import_if config.commonconf.music_production.guitar.enable [
     guitarix
     gxplugins-lv2
   ] ++

   # Score
   import_if config.commonconf.music_production.score.enable [
     musescore
   ];
  }

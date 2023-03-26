{ config, lib, pkgs, ... }@args:
let
  libsoft = import ../../lib/software/package_set.nix args;
  cfg = config.software.music;

  all_packages_sets = with pkgs; {
    electro = [
      lmms
      mixxx
    ];
    guitar = [
      guitarix
      gxplugins-lv2
    ];
    score = [
      musescore
    ];
  };
in
  {
    options.software.music = libsoft.mkPackageSetsOptions all_packages_sets;
    config = {
      environment.systemPackages = with pkgs; [
        youtube-dl
        ffmpeg
        audacity
      ] ++ (libsoft.mkPackageSetsConfig cfg all_packages_sets);
    };
  }

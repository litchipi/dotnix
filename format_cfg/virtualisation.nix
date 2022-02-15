{ config, lib, pkgs, ... }:
{
  config.virtualisation = {
    cores = 2;
    memorySize = 2048;
  };
}

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    htop
    vim
  ];
}

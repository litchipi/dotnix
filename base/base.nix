{ config, lib, pkgs, ... }:
{
  users.mutableUsers = false;
  environment.systemPackages = with pkgs; [
    htop
    vim
  ];
}

{ config, lib, pkgs, ... }:
{
  users.mutableUsers = false;
  environment.systemPackages = with pkgs; [
    coreutils-full
    htop
    vim
  ];
}

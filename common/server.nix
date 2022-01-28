{ config, lib, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    challengeResponseAuthentication = false;
    kbdInteractiveAuthentication = false;
  };
}

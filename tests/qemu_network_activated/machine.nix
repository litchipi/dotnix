{ config, lib, pkgs, ...}:
{

  users.users."joe" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "joe";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSnXhAtywJHWw3+S+yY3IvhpahOTqfs9OPfj2weANwuRauJMa+EYG3/kUNZiYLtejtpPp7HF7C1/n3IR08WmYFGF8F2eMsVoKYWrCzg1xYdTxVAoSPf+eefKI4VWXlcvV4rj9AQ/SVQq2p8NrIoNboixPKcfvmT9ydN36GaZ8dPYC9A1iPYKPZaTsMoH1I4ghRdKiQHvoFTkk6ouhadvre3eAmirUZqULbolF72rM2OA6xGSgzTM4Q2eWXS79DNnqUaqx31A3X+mILeqh4qxHezQTJqwBaWtQP7ZbL59bbRCdYo/UTzFFELUWUxdQZyWnath8XRBOmaRc8TpGy75wiE6qpr7vXEKpKsLA9ASzJWerRjly76JwqAjjAXzCQgvrwKvZXAVJ77UswCcUIHCRCjWiC+6TxIeDLCyKjlK2AMDMZN0zmSs3hgrueekrvvvSOKseBSTRnzfLGfaM1JyJ3L5Swqt6oZGcYPIIpmH9M7s0SUstZbIBBkLNTL8QLL58= tim@diamond"
    ];
  };
  
  networking.hostName = "joevm";

  users.mutableUsers = false;
  
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = lib.mkForce "no";
    kbdInteractiveAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    coreutils-full
    htop
    vim
    nmap
    nettools
    python39Packages.httpserver
    wget
    gotop
  ];

  cmn.services.nextcloud.enable = true;

  virtualisation = {
    cores = 2;
    memorySize = 2048;
    diskSize = 1024*4;
  };
  
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 50080; guest.port = 80; }
    { from = "host"; host.port = 58080; guest.port = 8080; }
    { from = "host"; host.port = 50443; guest.port = 443; }
  ];
}

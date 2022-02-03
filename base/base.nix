{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libssh = import ../lib/ssh.nix {inherit config lib pkgs;};

in
{
  options.base = {
    user = lib.mkOption {
      type = with lib.types; str;
      description = "Username of the main user of the system";
    };

    hostname = lib.mkOption {
      type = with lib.types; str;
    };

    ssh_auth_keys = lib.mkOption {
      type = with lib.types; listOf str;
    };

    base_hosts = lib.mkOption {
      type = with lib.types; bool;
      default = true;
    };
  };

  config = {
      users.users."${config.base.user}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = libssh.get_authorized_keys config.base.user config.base.ssh_auth_keys;
        password = libdata.try_get_password config.base.user;
      };

    users.mutableUsers = false;
    environment.systemPackages = with pkgs; [
      coreutils-full
      htop
      vim
    ];
  };
}

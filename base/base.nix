{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libssh = import ../lib/ssh.nix {inherit config lib pkgs;};

  pwds = lib.importTOML ../data/secrets/passwords.toml;
  try_get_password = user:
    if (builtins.hasAttr user pwds.machine_login)
      then pwds.machine_login."${user}"
      else null;
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

  # TODO    Write assertions here to check if mandatory options are set
  config = {
      networking = {
        hostName = config.base.hostname;
        extraHosts = (
          if config.base.base_hosts
          then libdata.read_data ["base_hosts"]
          else ""
        ); # + "\n" + add_hosts;
      };


      users.users."${config.base.user}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = libssh.get_authorized_keys config.base.user config.base.ssh_auth_keys;
        password = try_get_password config.base.user;
      };

    users.mutableUsers = false;
    environment.systemPackages = with pkgs; [
      coreutils-full
      htop
      vim
    ];
  };
}

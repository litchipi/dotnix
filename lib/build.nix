{ config, lib, pkgs, ... }:
let
  # Libraries to import
  libdata = import ./manage_data.nix {inherit config lib pkgs;};
  libssh = import ./ssh.nix {inherit config lib pkgs;};

  pwds = lib.importTOML ../data/secrets/passwords.toml;
  try_get_password = user:
    if (builtins.hasAttr user pwds.machine_login)
      then pwds.machine_login."${user}"
      else null;
in
  {
  # Bootstrap a machine configuration based on machine name, main user and common configs
  bootstrap_machine = {
    hostname, user,
    ssh_auth_keys,
    base_hosts ? true, add_hosts ? "",
    add_pkgs ? [],
  }:
  {
    networking = {
      hostName = hostname;
      extraHosts = (
        if base_hosts
        then libdata.read_data ["base_hosts"]
        else ""
      ) + "\n" + add_hosts;
    };

    users.users."${user}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = libssh.get_authorized_keys user ssh_auth_keys;
      password = try_get_password user;
    };
  };

  # Create a common configuration to be enabled with a `enable` flag set to True
  create_common_conf = { name, add_options ? {} }: cfg:
    {
      options = {
        commonconf."${name}".enable = lib.mkEnableOption "'${name}' common behavior";
      } // add_options;
      config = lib.mkIf config.commonconf."${name}".enable cfg;
    };
}

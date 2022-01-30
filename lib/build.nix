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
  }:
  {
    networking.hostName = hostname;
    users.users."${user}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = libssh.get_authorized_keys user ssh_auth_keys;
      password = try_get_password user;
    };
  };

  create_common_conf = { name }: cfg:
    {
      options = {
        commonconf."${name}".enable = lib.mkEnableOption "'${name}' common behavior";
      };
      config = lib.mkIf config.commonconf."${name}".enable cfg;
    };
}

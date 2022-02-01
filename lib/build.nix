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

  generate_add_opts = all_opts: builtins.listToAttrs (
    builtins.map
      (addopt: {
        name = "${addopt.name}";
        value = lib.mkOption addopt.option;
      })
    all_opts);

  generate_enable_opts = flags: builtins.listToAttrs (
    builtins.map
      (flag: {
        name = "${flag}";
        value = { enable = lib.mkEnableOption "Enable '${flag}' option"; };
      })
    flags);

  # Create a common configuration to be enabled with a `enable` flag set to True
  generate_config = user_config:
  let
    c = { enable_flags = []; add_options = []; } // user_config;
  in
    {
      options = {
        commonconf."${c.name}" = {
          enable = lib.mkEnableOption "'${c.name}' common behavior";
        } // (generate_add_opts c.add_options) // (generate_enable_opts c.enable_flags);
      };
      config = lib.mkIf config.commonconf."${c.name}".enable c.cfg;
    };

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

  create_common_confs = configs:
    (lib.lists.fold (cfg: acc: lib.attrsets.recursiveUpdate acc (generate_config cfg)) {} configs);
}

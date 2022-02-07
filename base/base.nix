{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libssh = import ../lib/ssh.nix {inherit config lib pkgs;};

  mergeall = setlist: lib.lists.fold (set: acc: lib.attrsets.recursiveUpdate acc set) {} setlist;

  get_all_homeconf = config: user: homecfg: lib.lists.flatten (lib.attrsets.mapAttrsToList
    (_: conf:
      if (lib.attrsets.hasAttr "home_conf" conf)
        then (if conf.enable
          then conf.home_conf user homecfg
          else {})
        else get_all_homeconf conf user homecfg
    ) config
  );
  all_common_conf_homecfg = user: homecfg: mergeall (get_all_homeconf config.commonconf user homecfg);
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

    user_cfg = lib.mkOption {
      type = with lib.types; functionTo anything;
      default = {config}: {};
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

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users."${config.base.user}" = hmcfg: #{config, ...}:
      lib.attrsets.recursiveUpdate
        (config.base.user_cfg {config=hmcfg.config;})
      (all_common_conf_homecfg config.base.user hmcfg.config);

    environment.systemPackages = with pkgs; [
      coreutils-full
      htop
      vim
    ];
  };
}

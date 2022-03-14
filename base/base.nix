{ config, lib, pkgs, ... }:
let
  cfg = config.base;
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../lib/utils.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  extract_home_conf = conf: if (lib.attrsets.hasAttr "home_conf" conf)
    then conf.home_conf
    else {};

  check_extract = name: conf: lib.lists.foldr (x: y: x && y) true [
    (!(lib.attrsets.isDerivation conf))
    (!(lib.options.isOption conf))
    ((builtins.typeOf conf) == "set")
    (name != "home_conf")
  ];

  get_all_homeconf = config: lib.lists.flatten (lib.attrsets.mapAttrsToList
    (name: conf:
    if (check_extract name conf)
      then (
        lib.attrsets.recursiveUpdate
          (extract_home_conf conf)
          (libutils.mergeall (get_all_homeconf conf))
      )
      else {}
    ) config
    );

  all_common_conf_homecfg = libutils.mkmergeall (get_all_homeconf config.commonconf);

  base_home_config = {
    programs.git = {
      enable = true;
      userName = libutils.email_to_name cfg.email;
      userEmail = cfg.email;
    };
    programs.bash.initExtra = ''
      source ${libdata.get_data_path [ "shell" "git-prompt.sh" ]}
      export PS1="${colors.fg.ps1.username}\\u ${colors.fg.ps1.wdir}\\w ${colors.fg.ps1.gitps1}\`__git_ps1 \<%s\>\` ${colors.fg.ps1.dollarsign}$ ${colors.reset}";
    '';
  };
in
{
  options.base = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Username of the main user of the system";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for this machine";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email to use for this system";
      default = "${cfg.user}@${cfg.hostname}.nix";
    };

    home_cfg = lib.mkOption {
      type = lib.types.anything;
      default = {};
      description = "Additionnal home-manager configurations for this machine";
    };

    add_pkgs = lib.mkOption {
      type = lib.types.anything;
      default = [];
      description = "Additionnal packages to set for this machine";
    };
  };

  config = {
      users.users."${cfg.user}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = libdata.try_get_password cfg.user;
      };

    users.mutableUsers = false;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users."${cfg.user}" = lib.mkMerge [
      (lib.attrsets.mapAttrsRecursive (_: value: lib.mkForce value) cfg.home_cfg)
      base_home_config
      all_common_conf_homecfg
    ];

    services.xserver.desktopManager.wallpaper.mode = lib.mkIf config.services.xserver.enable "fill";

    environment.systemPackages = with pkgs; [
      coreutils-full
      htop
      vim
    ] ++ cfg.add_pkgs;
  };
}

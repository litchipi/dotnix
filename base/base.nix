{ config, lib, pkgs, ... }:
let
  cfg = config.base;
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libutils = import ../lib/utils.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  base_home_config = {
    home = {
      homeDirectory = "/home/${cfg.user}";
      username = cfg.user;
      keyboard.layout = "fr";
      activation.create_user_dirs = let
        dirpaths = builtins.concatStringsSep " " (builtins.map (dir: "$HOME/${dir}") cfg.create_user_dirs);
      in ''
        if [ ! -z "${dirpaths}" ]; then
          mkdir -p ${dirpaths}
        fi
      '';
    };

    programs = {
      bash.initExtra = ''
        source ${libdata.get_data_path [ "shell" "git-prompt.sh" ]}
        export PS1="${colors.fg.ps1.username}\\u ${colors.fg.ps1.wdir}\\w '' +
        (if config.cmn.software.tui.git.enable
          then config.cmn.software.tui.git.ps1
          else ""
        ) + ''${colors.fg.ps1.dollarsign}$ ${colors.reset}"
      '';

      bash.sessionVariables = {
        COLORTERM="truecolor";
      };

      password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (exts: with exts; [
          pass-genphrase
          pass-otp
          pass-tomb
          pass-update
        ]);
        settings = {PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";};
      };
    };
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
      type = lib.types.attrs;
      default = {};
      description = "Additionnal home-manager configurations for this machine";
    };

    add_pkgs = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additionnal packages to set for this machine";
    };

    full_pkgs = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additionnal packages that are not included for a minimal configuration";
    };

    extraGroups = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Extra groups to add the base user into";
    };

    create_user_dirs = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Folders to create in $HOME of the user";
    };

    minimal.cli = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether to enable minimal CLI config";
    };

    minimal.gui = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wether to enable minimal GUI config";
    };
  };

  config = {
    system.stateVersion = "22.05";

    boot.cleanTmpDir = true;

    # clean logs older than 2d
    services.cron.systemCronJobs = [
        "0 20 * * * root journalctl --vacuum-time=2d"
    ];

    console.keyMap = "fr";
    i18n.defaultLocale = "fr_FR.UTF-8";

    users = {
      groups = lib.mkMerge (builtins.map (group:
        lib.attrsets.setAttrByPath [ group ] {}
      ) cfg.extraGroups);

      users."${cfg.user}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ] ++ cfg.extraGroups;
        password = libdata.plain_secrets.logins."${cfg.user}_${cfg.hostname}";
      };
      mutableUsers = false;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users."${cfg.user}" = lib.mkMerge [
        (lib.attrsets.mapAttrsRecursive (_: value: lib.mkForce value) cfg.home_cfg)
        base_home_config
      ];
    };

    time.timeZone = lib.mkDefault "Europe/Paris";

    hardware.firmware = if config.setup.is_nixos
      then with pkgs; [
        linux-firmware
      ]
      else [];
    environment.systemPackages = with pkgs; [
      coreutils-full
      util-linux
      vim
      wget
      lshw
      git
      git-crypt
    ] ++ cfg.add_pkgs
    ++ (if (config.base.minimal.cli || config.base.minimal.gui) then [] else cfg.full_pkgs);
  };
}

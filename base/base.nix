{ config, lib, pkgs, ... }:
let
  cfg = config.base;
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};

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

    add_fonts = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additional fonts to add to the system";
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
      ) ([cfg.user] ++ cfg.extraGroups));

      users."${cfg.user}" = {
        isNormalUser = true;
        group = cfg.user;
        extraGroups = [ "wheel" ] ++ cfg.extraGroups;
        password = libdata.plain_secrets.logins."${cfg.user}_${cfg.hostname}";
      };
      mutableUsers = false;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users."${cfg.user}" = lib.mkMerge [
        cfg.home_cfg
        base_home_config
      ];
    };

    time.timeZone = lib.mkDefault "Europe/Paris";

    hardware.firmware = if config.setup.is_nixos
      then with pkgs; [
        linux-firmware
      ]
      else [];

    services.pcscd.enable = true;
    programs.gnupg.agent = {
       enable = true;
       pinentryFlavor = "curses";
       enableSSHSupport = true;
    };

    environment.systemPackages = with pkgs; [
      complete-alias
      coreutils-full
      git git-crypt pass-git-helper
      gnupg pinentry pinentry-curses
      file
    ] ++ cfg.add_pkgs
    ++ (if (config.base.minimal.cli || config.base.minimal.gui) then [] else cfg.full_pkgs);

    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      trusted-users = [ config.base.user ];
    };
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    # unlock gpg keys with my login password
    security.pam.services.login.gnupg.enable = true;
    security.pam.services.login.gnupg.noAutostart = true;
    security.pam.services.login.gnupg.storeOnly = true;

    # Hardware-accelerated video decoding
    hardware.opengl.extraPackages = builtins.attrValues {
      inherit (pkgs)
        vaapiVdpau
      ;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    fonts = {
      fontDir.enable = true;
      fontconfig.enable = true;
      enableDefaultFonts = true;
      fonts = with pkgs; [
        pkgs.nerdfonts
        pkgs.powerline-fonts
        pkgs.ubuntu_font_family
      ] ++ cfg.add_fonts;
    };
  };
}

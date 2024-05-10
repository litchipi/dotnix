{ config, lib, pkgs, pkgs_unstable, ... }:
let
  cfg = config.base;

  base_home_config = {
    home = {
      homeDirectory = "/home/${cfg.user}";
      username = cfg.user;
      keyboard.layout = lib.mkDefault "fr";
      activation.create_user_dirs = let
        dirpaths = builtins.concatStringsSep " "
          (builtins.map (dir: "$HOME/${dir}") cfg.create_user_dirs);
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

    add_fonts = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additional fonts to add to the system";
    };

    create_user_dirs = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Folders to create in $HOME of the user";
    };

    home_cfg = lib.mkOption {
      type = lib.types.anything;
      default = {};
      description = "Configuration to set for home-manager on the user defined in config";
    };
  };

  config = {
    system.stateVersion = "23.11";
    base.home_cfg.home.stateVersion = "23.11";

    boot = {
      tmp.cleanOnBoot = true;
      loader.systemd-boot.editor = false;
    };

    # clean logs older than 2d
    services.cron.systemCronJobs = [
      "0 20 * * * root journalctl --vacuum-time=2d"
    ];

    console.keyMap = lib.mkDefault "fr";
    i18n.defaultLocale = lib.mkDefault "fr_FR.UTF-8";

    secrets.store.credentials.logins.${cfg.hostname}.${cfg.user}.transform = "${pkgs.openssl}/bin/openssl passwd -6 -stdin";
    secrets.setup.system_login.secret = config.secrets.store.credentials.logins.${cfg.hostname}.${cfg.user};

    users = {
      groups.${cfg.user} = {};
      users."${cfg.user}" = {
        isNormalUser = true;
        group = cfg.user;
        extraGroups = [ "wheel" ];
      } // (if config.setup.is_vm then {
        password = builtins.trace "Using ${cfg.user} as password (VM only)" cfg.user;
      } else {
        hashedPasswordFile = config.secrets.store.credentials.logins.${cfg.hostname}.${cfg.user}.file;
      });
      mutableUsers = false;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users."${cfg.user}" = lib.attrsets.recursiveUpdate cfg.home_cfg base_home_config;
    };
    time.timeZone = lib.mkDefault "Europe/Paris";

    hardware.firmware = if config.setup.is_nixos
      then with pkgs; [
        linux-firmware
      ]
      else [];

    services.pcscd.enable = lib.mkDefault true;
    programs.gnupg.agent = {
       enable = lib.mkDefault true;
       pinentryFlavor = "curses";
       enableSSHSupport = true;
    };

    environment = {
      variables = {
        DOTNIX_SRC="${./..}";
      };

      localBinInPath = true;

      systemPackages = with pkgs; [
        # TODO    Put in hardware.firmware directly ?
        # Firmwares
        linux-firmware
        sof-firmware
        alsa-firmware

        complete-alias
        coreutils-full
        gitFull git-crypt pass-git-helper git-lfs
        gnupg pinentry pinentry-curses
        file
        srm
        zip

        # Libraries used pretty much everywhere
        openssl.dev
      ];
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ config.base.user ];
    };
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    # TODO  Revise this service definition
    # unlock gpg keys with my login password
    security.pam.services.login = {
      gnupg = {
        enable = lib.mkDefault true;
        noAutostart = true;
        storeOnly = true;
      };
    };

    # Hardware-accelerated video decoding
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = builtins.attrValues {
        inherit (pkgs)
          vaapiVdpau
        ;
      };
    };

    zramSwap = {
      enable = lib.mkDefault true;
      algorithm = "zstd";
    };

    fonts = {
      fontDir.enable = lib.mkDefault true;
      fontconfig.enable = lib.mkDefault true;
      enableDefaultPackages = lib.mkDefault true;
      packages = with pkgs; [
        pkgs_unstable.nerdfonts
        pkgs_unstable.powerline-fonts
        ubuntu_font_family
        fira-code
        fira-code-symbols
        hack-font
      ] ++ cfg.add_fonts;
    };
  };
}

{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  cfg = config.base.disks;

  # systemconfig = builtins.fetchGit {
  #   url = "/home/tim/Projects/perso/dotnix/";
  #   ref = "${cfg.systemconfig_ref}";
  #   name = "dotnix";
  # };

  bootCfgLegacy = ''
    boot.loader.grub = {
      enable = true;
      device = "/dev/disks/by-label/boot";
    };
  '';

  bootCfgUefi = ''
    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        devices = [ "nodev" ];
        efiSupport = true;
        enable = true;
      };
    };
  '';

  configClone = ''
    { config, pkgs, ... }:

    {
      imports = [
        ./hardware-configuration.nix
      ];

      time.hardwareClockInLocalTime = true;
      boot.loader.grub.useOSProber = true;
  '' + (if cfg.use_uefi then bootCfgUefi else bootCfgLegacy) + ''
    }
  '';

  generate_config = ''
    echo -e "${colors.fg.primary}Generating base NixOS configuration${colors.reset}"

    mkdir -p /mnt/etc/

    # Cloning the repo from remote source
    git clone --depth 1 ${config.installscript.nixos_config_repo} -b ${config.installscript.nixos_config_branch} /mnt/etc/nixos/
    cd /mnt/etc/nixos/

    # Unlocking the git-crypt repo
    gpg -d gitcrypt.key.gpg > gitcrypt.key
    git-crypt unlock gitcrypt.key
    srm gitcrypt.key

    echo '${configClone}' > configuration.nix

    # Still generates the "hardware-configuration.nix"
    nixos-generate-config --root /mnt

    cd -
  '';
in
{
  config = let
    install_script = pkgs.writeShellScriptBin "install_nixos" (''
      set -e
      echo -e "${colors.fg.primary}Mounting the disk${colors.reset}"
      mount /dev/disk/by-label/${cfg.root_part_label} /mnt
    '' + (if cfg.use_uefi then ''
      mkdir -p /mnt/boot
      mount /dev/disk/by-label/boot /mnt/boot
    '' else "") + generate_config + ''
      echo -e "${colors.fg.primary}Installing NixOS${colors.reset}"
      nbcores=$(cat /proc/cpuinfo |grep cores|tail -n 1|awk -F ': ' '{print $2}')
      nixos-install -j $nbcores
    '');
  in
  {
    environment.systemPackages = [
      pkgs.git
      pkgs.gnupg
      pkgs.pinentry
      pkgs.srm
      pkgs.git-crypt
      install_script
    ];
  };
}

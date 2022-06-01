{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  cfg = config.base.disks;
  quiet = "2>/dev/null 1>/dev/null";
in
{
  config = let
    install_script = let
      gitcrypt_key = config.base.secrets.store.installiso_gitcrypt_key.dest;
    in pkgs.writeShellScriptBin "install_nixos" (''
      set -e

      if ! ping -w 3 -c 1 8.8.8.8 ${quiet}; then
        echo -e "${colors.fg.bad}Error:${colors.reset} Internet connection required to fetch remote configuration"
        exit 1
      fi

      echo -e "This script will install NixOS on disk ${colors.fg.secondary}${cfg.root_part_label}${colors.reset}, press ENTER to start"
      read
      echo -e "${colors.fg.primary}Mounting the disk${colors.reset}"
      if [ ! cat /proc/mounts | grep "/mnt" ${quiet}; then
        mount /dev/disk/by-label/${cfg.root_part_label} /mnt
      fi

      echo -e "${colors.fg.primary}Fetching the NixOS configuration from remote source ...${colors.reset}"
      mkdir -p /mnt/etc/

      if [ ! -d /mnt/etc/nixos/.git ]; then
        if [ -d /mnt/etc/nixos ]; then
          rm -rf /mnt/etc/nixos
        fi
        git clone ${config.installscript.nixos_config_repo} -b ${config.installscript.nixos_config_branch} /mnt/etc/nixos/
      fi

      pushd /mnt/etc/nixos/
      git-crypt unlock ${gitcrypt_key}

      echo -e "${colors.fg.primary}Installing NixOS${colors.reset}"
      nbcores=$(cat /proc/cpuinfo |grep cores|tail -n 1|awk -F ': ' '{print $2}')
      nixos-install -j $nbcores --flake .#${config.installscript.flake_target_name}
    '');
  in
  {
    base.minimal.gui = true;  # Do not include random big software of the config
    base.secrets.store.installiso_gitcrypt_key = libdata.set_secret config.base.user ["dotnix_gitcrypt_key"] {};
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

{ config, lib, pkgs, ... }: let
  cfg = config.cleaner;

  # TODO  IMPORTANT  cleaner module
  #    Set up update process with timer to automatically perform it
  #    Update flatpak, NixOS upgrade, clean old NixOS systems
  #    Create notification if update / upgrade failed

  scripts = {
    flatpak = ''
      if flatpak --version 2>/dev/null 1>/dev/null; then
        echo "[*] Updating flatpak"
        flatpak update --noninteractive
      fi
    '';

    nixos = ''
      nixos-rebuild dry-activate --flake ${config.setup.config_repo_path}
    '';

    nixgc = ''
      nix-collect-garbage --delete-older-than 30d
      nix store optimise
    '';
  };
in {
  options.cleaner = {
    # TODO  add enable option
    # TODO  Add options in here to enable some scripts
  };

  config = {
  };
}

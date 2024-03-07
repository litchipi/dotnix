{ config, lib, pkgs, pkgs_unstable, ... }@args:
let
  libutils = import ../../../lib/utils.nix {inherit config lib pkgs;};
  libsoft = import ../../../lib/software/package_set.nix args;

  all_packages_sets = with pkgs; {
    complete = [
      du-dust
      yt-dlp
      termusic
      ffmpeg
      neofetch
      bat
      python310Packages.deemix
    ];
  };
  cfg = config.software.tui;
in
  {
    imports = [
      ./shell_aliases.nix
      ./tmux.nix
      ./irssi.nix
    ];
    options.software.tui = {
      package_sets = libsoft.mkPackageSetsOptions all_packages_sets;
    };
    config = {
      environment.systemPackages = with pkgs; [
        gitFull
        fzf
        ripgrep
        autojump
        python310
        unzip unrar
        pkgs_unstable.zenith

        # Custom pomodoro tool from the overlay
        pomodoro
      ] ++ (libsoft.mkPackageSetsConfig cfg.package_sets all_packages_sets);

      base.home_cfg.programs.git = {
        enable = true;
        userName = lib.mkDefault (libutils.email_to_name config.base.email);
        userEmail = lib.mkDefault config.base.email;
        extraConfig = {
          init.defaultBranch = "main";
          # safe.directory = "/etc/nixos";
          credential.helper = "${
              pkgs.git.override { withLibsecret = true; }
            }/bin/git-credential-libsecret";
        };
      };
    };
  }

{ config, lib, pkgs, ... }: let
  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
in {
  imports = [
    ../common/system/nixcfg.nix
    ../common/system/maintenance.nix
    ../common/software/shell/helix.nix
    ../common/software/shell/tui.nix
    #../common/software/shell/dev.nix
    #../common/software/backup-fetcher.nix
  ];

  base.user = "john";
  base.email = "litchi.pi@proton.me";
  base.networking.ssh_auth_keys = [ "john@sparta" ];
  base.create_user_dirs = [ "work" ];

  base.shell.ps1.add_hostname = true;

  environment = {
    #variables.EDITOR = "hx";
    systemPackages = with pkgs; [
      zenith
      zenith-nvidia
      mold
      config.boot.kernelPackages.perf
    ];
  };

  users.users.${config.base.user} = {
    extraGroups = [
    ];
  };

  # Open a bunch of ports for fun things
  networking.firewall.allowedTCPPorts = [ 4444 4445 4446 ];

  colors.palette = {
    primary = libcolors.fromHex "#AAF0C1";
    secondary = libcolors.fromHex "#F0AAD9";
    tertiary = libcolors.fromHex "#dddddd";

    highlight = libcolors.fromHex "#DD25E9";
    dark = libcolors.fromHex "#712433";
    light = libcolors.fromHex "#F3B6C2";
    active = libcolors.fromHex "#BBEEDA";
    inactive = libcolors.fromHex "#5B5B5B";
    dimmed = libcolors.fromHex "#DFBBC2";
  };

  #software.dev.profiles = {
  #  rust = true;
  #  nix = true;
  #  python = true;
  #  c = true;
  #  svelte = true;
  #};

  software.tui.helix.configuration = {
   editor = {
     true-color = true;
     bufferline = "always";
     file-picker.hidden = false;
     indent-guides.character = "│";
   };
   keys = {
     select."Y" = ":clipboard-yank";
     normal=  {
       "Y" = ":clipboard-yank";
       "$" = {
         s = ":buffer-close";
         S = ":buffer-close!";
       };
     };
   };
  };

  environment.etc.hosts.mode = "0644";

  maintenance = {
    enable = true;
    nixStoreOptimize.enable = true;
  };

  nix.settings = {
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
    substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
  };
}

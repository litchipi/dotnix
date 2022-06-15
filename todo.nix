{
  # TODO
  programs.dircolors.enable = true;
  programs.dircolors.extraConfig = ''
    TERM alacritty
  '';
  programs.dircolors.settings = {
    ".iso" = "01;31"; # .iso files bold red like .zip and other archives
    ".gpg" = "01;33"; # .gpg files bold yellow
    # Images to non-bold magenta instead of bold magenta like videos
    ".bmp"   = "00;35";
    ".gif"   = "00;35";
    ".jpeg"  = "00;35";
    ".jpg"   = "00;35";
    ".mjpeg" = "00;35";
    ".mjpg"  = "00;35";
    ".mng"   = "00;35";
    ".pbm"   = "00;35";
    ".pcx"   = "00;35";
    ".pgm"   = "00;35";
    ".png"   = "00;35";
    ".ppm"   = "00;35";
    ".svg"   = "00;35";
    ".svgz"  = "00;35";
    ".tga"   = "00;35";
    ".tif"   = "00;35";
    ".tiff"  = "00;35";
    ".webp"  = "00;35";
    ".xbm"   = "00;35";
    ".xpm"   = "00;35";
  };
  xsession.numlock.enable = true;
  xsession.pointerCursor = { package = pkgs.numix-cursor-theme; name = "Numix-Cursor-Light"; size = 24; };
  gtk.gtk3.bookmarks = [ "file:///home/tejing/data" ];
  
  boot.loader.timeout = 1;
  boot.kernelParams = [ "quiet" ];
  boot.loader.grub.gfxmodeEfi = "3840x2160,1280x1024,auto";
  
  powerManagement.cpuFreqGovernor = "performance";
  
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/98d52540-e5ea-41ee-b012-300cb3424aae";
    fsType = "btrfs";
    options = [ "subvol=tejingdesk/root/new" ];
  };
  
  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/mnt/persist/tejingdesk/ssh_host_keys/ssh_host_rsa_key"; }
    { type = "ed25519";          path = "/mnt/persist/tejingdesk/ssh_host_keys/ssh_host_ed25519_key"; }
  ];
  
  # unlock gpg keys with my login password
  security.pam.services.login.gnupg.enable = true;
  security.pam.services.login.gnupg.noAutostart = true;
  security.pam.services.login.gnupg.storeOnly = true;
  
  fonts.fonts = builtins.attrValues {
    inherit (pkgs)
      corefonts
      nerdfonts
    ;
  };
  
  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.mouse.accelSpeed = "0.6";
  
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  
  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Hardware-accelerated video decoding
  hardware.opengl.extraPackages = builtins.attrValues {
    inherit (pkgs)
      vaapiVdpau
    ;
  };

  # 32-bit graphics libraries
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = builtins.attrValues {
    inherit (pkgs.pkgsi686Linux)
      vaapiVdpau
    ;
  };
  
  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;
  
  programs.htop = {
    enable = true;
    settings = {
      color_scheme = 6;
      cpu_count_from_zero = true;
      highlight_base_name = true;
      show_cpu_usage = true;
    };
  };
  
  home.packages = with pkgs; [
    gitAndTools.pass-git-helper
  ];

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: with exts; [
      pass-genphrase
      pass-otp
      pass-tomb
      pass-update
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
  };
  
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[λ](bold green)";
        error_symbol = "[λ](bold red)";
      };
      format = builtins.concatStringsSep "" [
        "$username"
        "$hostname"
        "$shlvl"
        "$kubernetes"
        "$directory"
        # "$vcsh"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_status"
        # "$hg_branch"
        # "$docker_context"
        "$package"
        # "$cmake"
        # "$dart"
        # "$deno"
        # "$dotnet"
        "$elixir"
        # "$elm"
        "$erlang"
        "$golang"
        "$helm"
        "$java"
        # "$julia"
        # "$kotlin"
        # "$nim"
        "$nodejs"
        "$ocaml"
        "$perl"
        # "$php"
        "$purescript"
        "$python"
        # "$red"
        "$ruby"
        "$rust"
        # "$scala"
        # "$swift"
        "$terraform"
        # "$vagrant"
        # "$zig"
        "$nix_shell"
        # "$conda"
        "$memory_usage"
        "$aws"
        # "$gcloud"
        # "$openstack"
        "$env_var"
        # "$crystal"
        # "$custom"
        "$cmd_duration"
        # "$line_break"
        # "$lua"
        "$jobs"
        # "$battery"
        "$time"
        "$line_break" # added
        "$status"
        # "$shell"
        "$character"
      ];
      git_branch.symbol = "🌱 ";
      git_commit.tag_disabled = false;
      git_status = {
        ahead = ''⇡''${count}'';
        behind = ''⇣''${count}'';
        diverged = ''⇕⇡''${ahead_count}⇣''${behind_count}'';
        staged = "+$count";
      };
      kubernetes.disabled = false;
      nix_shell = {
        format = "via [$symbol$state]($style) ";
        impure_msg = "ι";
        pure_msg = "﻿ρ";
        symbol = "❄️";
      };
      time.disabled = false;
    };
  };
  
  boot.initrd.luks.devices.root.device = "/dev/nvme0n1p2";
  
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  pkgs.amdvlk
  
  boot.initrd.luks.devices = {
    cryptkey.device = "/dev/disk/by-uuid/2a44a760-206c-448d-a126-527b8b63f5d0";

    cryptroot = {
      device = "/dev/disk/by-uuid/6cd51820-547b-4378-b566-47f8cdbc46df";
      keyFile = "/dev/mapper/cryptkey";
    };

    cryptswap = {
      device = "/dev/disk/by-uuid/7d80e701-3a6b-4bb0-b8a3-dd5dfb432cdd";
      keyFile = "/dev/mapper/cryptkey";
    };
  };
  
  services.xserver = {
    config = ''
      Section "Device"
        Identifier  "Intel Graphics"
        Driver      "intel"
        Option      "TearFree"        "true"
        Option      "SwapbuffersWait" "true"
        BusID       "PCI:0:2:0"
      EndSection
    '';

    screenSection = ''
      Option         "AllowIndirectGLXProtocol" "off"
      Option         "TripleBuffer" "on"
    '';
  };
  
  boot = {
    cleanTmpDir = true;
  };
  
  console.font = "Lat2-Terminus16";
  console.useXkbConfig = true;
  
  networking.networkmanager.enable = true;

  xserver = {
    libinput = {
        enable = true;
        touchpad = {
          accelSpeed = "1.0";
          disableWhileTyping = true;
          naturalScrolling = false;
          tapping = true;
        };
      };

      videoDrivers = lib.mkDefault [ "intel" ];
  };
}

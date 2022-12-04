{ config, lib, pkgs, ... }: let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  libcolors = import ../lib/colors.nix {inherit config lib pkgs;};
  libcachix = import ../lib/services/cachix.nix {inherit config lib pkgs; };
in {
  base.user = "tim";
  base.email = "litchi.pi@proton.me";

  base.networking.ssh_auth_keys = [ "john@sparta" ];
  base.create_user_dirs = [ "Projects" "Admin" ];
  base.networking.connect_wifi = [ "SFR_11EF" ];    # TODO  Check works

  colors.palette = {
    primary = libcolors.fromhex "#B14078";
    secondary = libcolors.fromhex "#BCFF99";
    tertiary = libcolors.fromhex "#8CAED0";
    highlight = libcolors.fromhex "#0ED99A";
    dark = libcolors.fromhex "#26486A";
    light = libcolors.fromhex "#B2DFDF";
    active = libcolors.fromhex "#A86DCC";
    inactive = libcolors.fromhex "#A995A1";
    dimmed = libcolors.fromhex "#C0C0C0";
  };

  cmn.wm = {
    autologin = true;
    boot.enable = true;
    bck-img = libdata.get_wallpaper "we-must-conquer-mars.jpg";
    cursorTheme = {
      name = "Qogir-dark";
      package = pkgs.qogir-icon-theme;
    };
    iconTheme = {
      name = "Tela-orange-dark";
      package = pkgs.tela-icon-theme;
    };
    gtkTheme = {
      name = "Flat-Remix-GTK-Orange-Dark";
      package = pkgs.flat-remix-gtk;
    };
  };

  cmn.wm.gnome = {
    enable = true;
    theme = {
      name = "Zuki-shell";
      package = pkgs.zuki-themes;
      dark = true;
    };
    user_icon = libdata.get_data_path ["assets" "desktop" "user_icons" "litchi.jpg"];
  };

  cmn.software.tui.irssi = {
    default_nick = "stixp";
    theme = pkgs.litchipi.irssitheme;
  };
  cmn.software.protonvpn = {
    enable = true;
    username = "litchipi";
  };

  cmn.basic.enable = true;
  cmn.server.enable = true;
  networking.stevenBlackHosts.enable = true;

  cmn.software.dev.basic = true;

  services.flatpak.enable = true;

  cmn.services.restic.global = {
    enable = true;
    gdrive = true;
    forget_opts = [ "-y 50" "-m 15" "-w 4" "-d 6" "-l 10" ];
    timerConfig.OnCalendar = "05/7:00:00";
  };

  # TODO Add to general settings
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Wait for https://github.com/NixOS/nixpkgs/issues/200124 to be fixed
  cmn.hardware.displaylink.enable = false;

  # TODO List
  # - Fixup Nerdfont too small in shix
  # - Restore projects dir
  # - Allow diamond on gitlab

  base.full_pkgs = with pkgs; [
    # Writing
    apostrophe  # Markdown editor
    # marp # Markdown to PDF  # Insecure

    # Music
    blanket # Play relaxing sound
    shortwave # Listen Internet radio
    gnome-podcasts # Listen to podcasts

    # System
    authenticator # 2FA TOTP app
    blueman     # Bluetooth manager

    # Dev
    cmake
  ];
  cmn.services.cachix.client = {
    enable = true;
    servers = libcachix.set_servers [
      { fqdn = "cachix.orionstar.cyou"; }
    ];
  };
}

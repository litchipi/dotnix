{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
libconf.create_common_confs [
  {
    name = "retroarch";
    parents = ["software" "games"];
    add_pkgs = with pkgs; [
      retroarchFull
    ];
  }
  {
    name = "ankama-launcher";
    parents = ["software" "games"];
    add_pkgs = let
      name = "ankama-launcher";
      # https://download.ankama.com/launcher/full/linux/x64
      src = pkgs.fetchurl {
        url = "https://launcher.cdn.ankama.com/installers/production/Ankama%20Launcher-Setup-x86_64.AppImage";
        sha256 = "e7c700b04b2d601014009e55bd9d8225d9ddbc1513bf95ef1d4a0309be30c100";
        name = "ankama-launcher.AppImage";
       };
    in with pkgs; [
      libGL
      winetricks
      wine-wayland
      wineasio
      wineWowPackages.waylandFull
      winePackages.waylandFull
      mesa
      gnutls.dev
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-plugins-viperfx
      gst_all_1.gstreamermm
      gst_all_1.gst-libav
      gst_all_1.gst-vaapi
      (appimageTools.wrapType2 {
        inherit name src;
        extraInstallCommands = let
          appimageContents = appimageTools.extractType2 { inherit name src; };
        in ''
          install -m 444 -D ${appimageContents}/zaap.desktop $out/share/applications/ankama-launcher.desktop
          sed -i 's/.*Exec.*/Exec=ankama-launcher/' $out/share/applications/ankama-launcher.desktop
          install -m 444 -D ${appimageContents}/zaap.png $out/share/icons/hicolor/256x256/apps/zaap.png
        '';
      })
    ];
  }
]

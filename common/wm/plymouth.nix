{ config, lib, pkgs, ... }:
let
  cfg = config.wm.boot.style.plymouth;
  plymouth_themes = pkgs.stdenv.mkDerivation {
    pname = "plymouth-themes";
    version = "0.0.1";

    src = pkgs.fetchFromGitHub {
      owner  = "adi1090x";
      repo   = "plymouth-themes";
      rev    = "bf2f570bee8e84c5c20caac353cbe1d811a4745f";
      sha256 = "sha256-VNGvA8ujwjpC2rTVZKrXni2GjfiZk7AgAn4ZB4Baj2k=";
    };

    installPhase = ''
      . $stdenv/setup
      ALL_THEMES=$(find $src -name "*.plymouth" | grep -v "template")
      if ! echo "$ALL_THEMES" | grep "${cfg.theme}" 2>/dev/null 1>/dev/null; then
        echo "Theme ${cfg.theme} not found"
        echo ""
        echo "All themes found: "
        echo "$ALL_THEMES"
        exit 1;
      fi
      theme=$(realpath $(echo "$ALL_THEMES" | grep "${cfg.theme}"))
      mkdir -p $out/share/plymouth/themes/
      cp -r $(dirname $theme) $out/share/plymouth/themes/
    '';
  };
in
  {
    options.wm.boot.style.plymouth = {
      theme = lib.mkOption {
        type = lib.types.str;
        description = "Name of the Plymouth theme to apply";
        default = "lone";
      };
    };
    config.boot.plymouth = {
      enable = lib.mkDefault false;
      theme = config.wm.boot.style.plymouth.theme;
      themePackages = [ plymouth_themes ];
      # extraConfig = ''
      #   UseFirmwareBackground=false
      #   ShowDelay=1
      # '';
    };
  }

{ config, lib, pkgs, ... }:
let
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  cfg = config.cmn.wm.boot;

  plymouth_themes = pkgs.stdenv.mkDerivation rec {
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
libconf.create_common_confs [
  {
    name = "boot";
    parents = ["wm"];
    add_opts = {
      theme = lib.mkOption {
        type = lib.types.str;
        description = "Name of the Plymouth theme to apply";
        default = "lone";
      };
    };
    cfg = {
      boot.plymouth = {
        enable = true;
        theme = cfg.theme;
        themePackages = [ plymouth_themes ];
        extraConfig = ''
          UseFirmwareBackground=false
          ShowDelay=1
        '';
      };
    };
  }
]

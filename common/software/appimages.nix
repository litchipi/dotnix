{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libappimg = import ../../lib/software/appimage.nix {inherit config lib pkgs;};
in
libconf.create_common_confs [
  {
    name = "sengi";
    parents = [ "software" "appimages" ];
    add_pkgs = let
      sengi_version = "1.1.5";
      sengi_appimg_sha = "sha256-eFiYqhI6RTFxXl9y8YLGqqURyMVpBQaw3OirPrPTsek=";
      sengi_icon_sha = "sha256-f6LoaXZR1ScFvqdUI7JriidbY0b8BrMmG3IPQQ8+TqA=";
    in [
      (libappimg.mkAppImageDerivation "sengi" {
        appimg = pkgs.fetchurl {
          url = "https://github.com/NicolasConstant/sengi/releases/download/${sengi_version}/Sengi-${sengi_version}-linux.AppImage";
          sha256 = sengi_appimg_sha;
        };
        desktop_options = {
          desktopName = "Sengi";
          icon = pkgs.fetchurl {
            url = "https://github.com/SengiApp/sengiapp.github.io/raw/gh-pages/assets/icons/icon-96x96.png";
            sha256 = sengi_icon_sha;
          };
          keywords = [ "sengi" "mastodon" ];
        };
      })
    ];
  }
]

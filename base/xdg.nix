{ config, lib, pkgs, ...}:
let
  cfg = config.xdg;

  make_dir_opt = type: default: lib.mkOption {
    type = with lib.types; str;
    description = "Location of the \"${type}\" folder";
    inherit default;
  };
in
{
  config = {
    home-manager.users."${config.base.user}" = hmcfg: {
      xdg.userDirs = {
        download = "\$HOME/${cfg.dirs.download}";
        desktop = "\$HOME";
        documents = "\$HOME/${cfg.dirs.documents}";
        music = "\$HOME/${cfg.dirs.music}";
        pictures = "\$HOME/${cfg.dirs.pictures}";
        templates = "\$HOME";
        videos = "\$HOME/${cfg.dirs.videos}";
      };
    };
  };

  options = {
    dirs = {
      download = make_dir_opt "download" "dl";
      documents = make_dir_opt "documents" "docs";
      music = make_dir_opt "music" "music";
      pictures = make_dir_opt "pictures" "pics";
      videos = make_dir_opt "videos" "vids";
    };
  };
}

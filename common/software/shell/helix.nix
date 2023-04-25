{ config, lib, pkgs, pkgs_unstable, ... }:
let
  cfg = config.software.tui.helix;
in {
  options.software.tui.helix = {
    configuration = lib.mkOption {
      type = lib.types.path;
      description = "Configuration for the Helix editor";
      default = libdata.get_data_path ["config" "helix" "config.toml"];
    };

    theme = lib.mkOption {
      type = lib.types.path;
      description = "Theme to apply to the Helix editor";
      default = libdata.get_data_path ["config" "helix" "theme.toml"];
    };

    languagesdef = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Lines to add to the `languages.toml` file";
      default = [];
    };
  };
  config = {
    environment.systemPackages = [ inputs.helix.packages.${system}.default ];
    home_cfg.home.file.".config/helix/config.toml".source = cfg.configuration;
    home_cfg.home.file.".config/helix/themes/nixos.toml".source = cfg.theme;
    home_cfg.home.file.".config/helix/languages.toml".text =
      builtins.concatStringsSep "\n\n" cfg.languagesdef;
  };
}

{ config, lib, pkgs, ... }:
let
  utils = import ./utils.nix {inherit config lib pkgs;};
  merge_all_configs = configs:
    {
      options = utils.mergeall (builtins.map (conf: conf.options) configs);
      config = lib.mkMerge (builtins.map (conf: conf.config) configs);
    };

  commoncfg = user_cfg:
    let
      # Default arguments
      arg_config = {
        default_enabled = false;
        parents = [];
        add_opts = {};
        home_cfg = user: hconfig: {};
        activation_script = '''';
        add_pkgs = [];
        cfg = {};
      } // user_cfg;

      opt_path = ["commonconf"] ++ arg_config.parents ++ [ arg_config.name ];
      cfg = utils.mergeall [
        arg_config.cfg
        { environment.systemPackages = arg_config.add_pkgs; }
      ];
      enable_condition = lib.attrsets.getAttrFromPath (opt_path ++ [ "enable" ]) config;
    in
    with arg_config;
    {
      options = lib.attrsets.setAttrByPath opt_path ({

        enable = lib.mkOption {
          default = default_enabled;
          description = "${builtins.toString opt_path}' common behavior";
          type = lib.types.bool;
        };

        home_conf = lib.mkOption {
          type = with lib.types; anything;
          default = lib.mkIf enable_condition arg_config.home_cfg;
          description = "Additional configuration to add to home-manager.";
        };
      } // add_opts);

      config = lib.mkIf enable_condition cfg;
    };
in
{
  create_common_confs = configs: merge_all_configs (builtins.map commoncfg configs);
}

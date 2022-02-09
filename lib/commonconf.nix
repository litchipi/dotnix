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
        parents = [];
        add_opts = {};
        home_cfg = user: hconfig: {};
        activation_script = '''';
        add_pkgs = [];
        cfg = {};
      } // user_cfg;

      cfg = lib.attrsets.recursiveUpdate arg_config.cfg {
        environment.systemPackages = arg_config.add_pkgs;
      };
      opt_path = ["commonconf"] ++ arg_config.parents ++ [ arg_config.name ];
    in
    with arg_config;
    {
      options = lib.attrsets.setAttrByPath opt_path ({
          enable = lib.mkEnableOption "'${builtins.toString opt_path}' common behavior";
          home_conf = lib.mkOption {
            type = with lib.types; functionTo (functionTo (either (attrsOf anything) lines));
            default = home_cfg;
            description = "Additional configuration to add to home-manager.";
          };
        } // add_opts);
      config = lib.mkIf (lib.attrsets.getAttrFromPath (opt_path ++ [ "enable" ]) config) cfg;
    };
in
{
  create_common_confs = configs: merge_all_configs (builtins.map commoncfg configs);
}

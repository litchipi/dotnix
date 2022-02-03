{ config, lib, pkgs, ... }:
let 
  mergeall = setlist: lib.lists.fold (set: acc: lib.attrsets.recursiveUpdate acc set) {} setlist;
  merge_all_configs = configs:
    {
      options = mergeall (builtins.map (conf: conf.options) configs);
      config = lib.mkMerge (builtins.map (conf: conf.config) configs);
    };

  commoncfg = user_cfg:
    let
      arg_config = { parents = []; add_opts = {}; home_cfg = user: {};} // user_cfg;
      name = arg_config.name;
      cfg = arg_config.cfg;
      parents = arg_config.parents;
      home_cfg = arg_config.home_cfg;
      add_opts = arg_config.add_opts;
      opt_path = ["commonconf"] ++ parents ++ [ name ];
    in
    {
      options = lib.attrsets.setAttrByPath opt_path {
          enable = lib.mkEnableOption "'${builtins.toString opt_path}' common behavior";
          home_conf = lib.mkOption {
            type = with lib.types; types.functionTo (types.either (types.attrsOf types.anything) types.lines);
            default = home_cfg;
            description = "Additional configuration to add to home-manager.";
          };
        };
      config = lib.mkIf (lib.attrsets.getAttrFromPath (opt_path ++ [ "enable" ]) config) cfg;
    };
in
{
  create_common_confs = configs: merge_all_configs (builtins.map commoncfg configs);
}

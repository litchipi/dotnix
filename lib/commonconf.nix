{ config, lib, pkgs, ... }:
let
  utils = import ./utils.nix {inherit config lib pkgs;};
  merge_all_configs = configs:
    {
      options = utils.mergeall (builtins.map (conf: conf.options) configs);
      config = lib.mkMerge (builtins.map (conf: conf.config) configs);
    };

  generate_enable_chains_opts = chains: lib.attrsets.mapAttrs (name: _:
    lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the chained config \"${name}\"";
    }
    ) chains;

  generate_tag_cfg = basepath: tag: lib.mkIf
    (lib.attrsets.getAttrFromPath (basepath ++ [tag]) config)
    { enable = true;};


  generate_chain_cfg = basepath: tag: opts: lib.lists.foldl (acc: opt:
    lib.attrsets.recursiveUpdate acc (lib.setAttrByPath (basepath ++ [opt]) (generate_tag_cfg basepath tag))
  ) {} opts;

  generate_enable_chains_cfgs = basepath: chains: lib.mkMerge (
    lib.attrsets.mapAttrsToList (generate_chain_cfg basepath) chains
  );

  commoncfg = user_cfg:
    let
      # Default arguments
      arg_config = {
        default_enabled = false;
        chain_enable_opts = {};
        parents = [];
        add_opts = {};
        assertions = [];
        home_cfg = {};
        activation_script = '''';
        add_pkgs = [];
        cfg = {};
      } // user_cfg;

      opt_path = ["cmn"] ++ arg_config.parents ++ [ arg_config.name ];
      cfg = lib.mkMerge [
        arg_config.cfg
        { environment.systemPackages = arg_config.add_pkgs; }
        { assertions = arg_config.assertions; }
        (generate_enable_chains_cfgs opt_path arg_config.chain_enable_opts)
      ];
      enable_condition = lib.attrsets.getAttrFromPath (opt_path ++ [ "enable" ]) config;
    in
    with arg_config;
    {
      options = lib.attrsets.setAttrByPath opt_path (libutils.mergeall [
        {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = default_enabled;
            description = "${builtins.toString opt_path}' common behavior";
          };

          home_conf = lib.mkOption {
            type = with lib.types; anything;
            default = lib.mkIf enable_condition arg_config.home_cfg;
            description = "Additional configuration to add to home-manager.";
          };
        }
        (generate_enable_chains_opts chain_enable_opts)
        add_opts
      ]);

      config = lib.mkIf enable_condition cfg;
    };
in
{
  create_common_confs = configs: merge_all_configs (builtins.map commoncfg configs);
}

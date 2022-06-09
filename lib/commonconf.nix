{ config, lib, pkgs, ... }:
let
  libutils = import ./utils.nix {inherit config lib pkgs;};
  merge_all_configs = configs:
    {
      options = libutils.mergeall (builtins.map (conf: conf.options) configs);
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

  commoncfg = {
    name,
    parents ? [],
    default_enabled ? false,
    minimal ? { cli = false; gui = false; },
    chain_enable_opts ? {},
    assertions ? [],
    imports ? [],
    add_opts ? {},
    add_pkgs ? [],
    home_cfg ? {},
    virtualisation_cfg ? {},
    cfg ? {}
  }:
    let
      minimal_cfg = { cli = false; gui = false; } // minimal;
      opt_path = ["cmn"] ++ parents ++ [ name ];

      enable_condition = builtins.foldl' (acc: val: acc && val) true [
        (if config.base.minimal.cli then minimal_cfg.cli else true)
        (if config.base.minimal.gui then (minimal_cfg.gui || minimal_cfg.cli) else true)
        (lib.attrsets.getAttrFromPath (opt_path ++ [ "enable" ]) config)
      ];

      total_cfg = lib.mkMerge [
        cfg
        {
          environment.systemPackages = add_pkgs;
          home-manager.users."${config.base.user}" = home_cfg;
          virtualisation = lib.mkIf config.setup.is_vm virtualisation_cfg;
          inherit assertions;
        }
        (generate_enable_chains_cfgs opt_path chain_enable_opts)
      ];
    in
    {
      options = lib.attrsets.setAttrByPath opt_path (libutils.mergeall [
        {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = default_enabled;
            description = "${builtins.toString opt_path}' common behavior";
          };
        }
        (generate_enable_chains_opts chain_enable_opts)
        add_opts
      ]);

      config = lib.mkIf enable_condition total_cfg;

      inherit imports;
    };
in
{
  create_common_confs = configs: merge_all_configs (builtins.map commoncfg configs);
}

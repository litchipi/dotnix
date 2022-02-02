{ config, lib, pkgs, ... }:
let
  # Libraries to import
  libdata = import ./manage_data.nix {inherit config lib pkgs;};
  libssh = import ./ssh.nix {inherit config lib pkgs;};

  generate_add_opts = all_opts: builtins.listToAttrs (
    builtins.map
      (addopt: {
        name = "${addopt.name}";
        value = lib.mkOption addopt.option;
      })
    all_opts);

  generate_enable_opts = flags: builtins.listToAttrs (
    builtins.map
      (flag: {
        name = "${flag}";
        value = { enable = lib.mkEnableOption "Enable '${flag}' option"; };
      })
    flags);

  # Create a common configuration to be enabled with a `enable` flag set to True
  generate_config = catname: user_config:
  let
    c = { enable_flags = []; add_options = []; } // user_config;
  in
    {
      options = {
        commonconf."${catname}"."${c.name}" = lib.attrsets.recursiveUpdate {
          enable = lib.mkEnableOption "'${catname}.${c.name}' common behavior";
        } (lib.attrsets.recursiveUpdate (generate_add_opts c.add_options) (generate_enable_opts c.enable_flags));
      };
      config = lib.mkIf config.commonconf."${catname}"."${c.name}".enable c.cfg;
    };

in
  {
  # Pass a list of common confs to generate, using recursiveUpdate to merge all in
  # on big configuration set.
  create_common_confs = name: configs:
    (lib.lists.fold (cfg: acc: lib.attrsets.recursiveUpdate acc (generate_config name cfg)) {} configs);
}

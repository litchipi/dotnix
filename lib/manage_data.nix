{ config, lib, pkgs, ... }:
let
  data_dir_root = ../data;
in
  rec {
  get_data_path = pathlist:
    lib.lists.foldl (p: d: p + "/${d}") data_dir_root pathlist;
  read_data = pathlist: builtins.readFile (get_data_path pathlist);
  read_data_else_empty = pathlist:
  let
    path = get_data_path pathlist;
  in
    if builtins.pathExists path
    then builtins.readFile path
    else "";

  copy_files_in_home = assets:
    builtins.listToAttrs (
      builtins.map ({home_path, asset_path}:
        { name = home_path; value = { source = get_data_path asset_path; }; }
      ) assets
    );

  pkg_patch = package: patchname: get_data_path ["patches" package "${patchname}.patch"];

  get_wallpaper = name: get_data_path ["assets" "desktop" "wallpapers" name ];

  set_common_secret_config = conf: tree: builtins.mapAttrs (name: value:
    if builtins.hasAttr "__is_leaf" value
      then conf
      else (set_common_secret_config conf value)
    ) tree;
}

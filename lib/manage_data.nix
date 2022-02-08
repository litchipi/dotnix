{ config, lib, pkgs, ... }:
let
  mergeall = setlist: lib.lists.fold (set: acc: lib.attrsets.recursiveUpdate acc set) {} setlist;
  list_elements = dir: type: map (f: dir + "/${f}") (
    lib.attrNames (
      lib.filterAttrs
        (_: entryType: entryType == type)
        (builtins.readDir  dir)
      )
    );

  find_all_files = dir: lib.lists.flatten (
    (builtins.map find_all_files (list_elements dir "directory"))
    ++ (list_elements dir "regular")
  );
in
rec {
  get_data_path = pathlist:
    builtins.foldl' (p: d: p + "/${d}") ../data pathlist;
  read_data = pathlist: builtins.readFile (get_data_path pathlist);

  read_data_else_empty = pathlist:
  let
    path = get_data_path pathlist;
  in
    if builtins.pathExists path
    then builtins.readFile path
    else "";

  # FIXME   Load aliases only once, even if specified several times
  load_aliases = aliases_list: lib.lists.fold
    (name: acc: acc + "\n" + (
      read_data [ "aliases" (name + ".sh") ])
    ) "" aliases_list;

  pwds = lib.importTOML ../data/secrets/passwords.toml;
  try_get_password = user: pwds.machine_login."${user}" or null;
  load_wifi_cfg = ssid: pwds.wifi_keys."${ssid}" or null;

  get_asset_path = ident: get_data_path [ "asset" ident ];

  copy_files_in_home = assets:
    builtins.listToAttrs (
      builtins.map (asset:
        { name = asset.home_path; value = { source = get_data_path asset.asset_path; }; }
      ) assets
    );

  copy_dir_to_home = home_path_dir: dir_path: let
    data_dir_path = get_data_path dir_path;
    all_dirs = list_elements data_dir_path "directory";
    all_files = list_elements data_dir_path "regular";
  in
    copy_files_in_home (
      builtins.map (f: {
        home_path = home_path_dir + "/${builtins.baseNameOf f}";
        asset_path = dir_path ++ [ (builtins.baseNameOf f) ];
      }) all_files
    ) // copy_dirs_to_home (
      builtins.map (d: {
        home_path_dir = home_path_dir + "/${builtins.baseNameOf d}";
        asset_path_dir = dir_path ++ [ (builtins.baseNameOf d) ];
      }) all_dirs
    );

  copy_dirs_to_home = dirs:
    mergeall (lib.lists.flatten (
      builtins.map (d: copy_dir_to_home d.home_path_dir d.asset_path_dir) dirs
    ));
}

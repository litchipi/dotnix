{ config, lib, pkgs, ... }:
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
}

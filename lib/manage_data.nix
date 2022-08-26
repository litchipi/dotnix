{ config, lib, pkgs, ... }:
let
  libutils = import ./utils.nix {inherit config lib pkgs;};

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

  plain_secrets = (lib.modules.importTOML "${data_dir_root}/secrets/plain_secrets.toml").config;
  load_wifi_cfg = ssid: { inherit ssid; passwd = plain_secrets.wifi_keys."${ssid}" or null; };

  load_token = type: indent: lib.attrsets.getAttrFromPath [ type indent ] (
    lib.importTOML "${data_dir_root}/secrets/tokens.toml"
  );

  copy_files_in_home = assets:
    builtins.listToAttrs (
      builtins.map ({home_path, asset_path}:
        { name = home_path; value = { source = get_data_path asset_path; }; }
      ) assets
    );

  set_secret = user: path: { group ? user, permissions ? "0400" }: {
    source = get_data_path (["secrets"] ++ path);
    dest = "/run/nixos-secrets/${builtins.concatStringsSep "/" path}";
    owner = user;
    inherit group permissions;
  };
}

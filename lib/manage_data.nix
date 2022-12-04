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

  plain_secrets = if config.setup.is_ci_run
    then {
      logins.ci_ci = "nopassword";
      irssi = {};
    }
    else (lib.modules.importTOML "${data_dir_root}/secrets/plain_secrets.toml").config;

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

  write_secret_file = {
    user, filename, text,
    group ? user, permissions ? "0400", symlink ? null
  }: {
    source = pkgs.writeText filename text;
    dest = "/run/nixos-secrets/${user}_secret_files/${filename}";
    owner = user;
    inherit group permissions symlink;
  };

  set_secret = { user, path, group ? user, permissions ? "0400", symlink ? null }: {
    source = get_data_path (["secrets"] ++ path);
    dest = "/run/nixos-secrets/${builtins.concatStringsSep "/" path}";
    owner = user;
    inherit group permissions symlink;
  };

  pkg_patch = package: patchname: get_data_path ["patches" package "${patchname}.patch"];

  get_wallpaper = name: get_data_path ["assets" "desktop" "wallpapers" name ];
}

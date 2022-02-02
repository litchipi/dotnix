{ config, lib, pkgs, ... }:
let
  path_from_list = pathlist:
    builtins.foldl' (p: d: p + "/${d}") ../data pathlist;
in
rec {
  read_data = pathlist: builtins.readFile (path_from_list pathlist);

  read_data_else_empty = pathlist:
  let
    path = path_from_list pathlist;
  in
    if builtins.pathExists path
    then builtins.readFile path
    else "";

  load_aliases = aliases_list: lib.lists.fold
    (name: acc: acc + "\n" + (read_data [ "aliases" (name + ".sh") ])) ""
    aliases_list;
}

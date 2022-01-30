{ config, lib, pkgs, ... }:
let
  path_from_list = pathlist:
    builtins.foldl' (p: d: p + "/${d}") ../data pathlist;
in
{
  read_data = pathlist: builtins.readFile (path_from_list pathlist);

  read_data_else_empty = pathlist:
  let
    path = path_from_list pathlist;
  in
    if builtins.pathExists path
    then builtins.readFile path
    else "";
}

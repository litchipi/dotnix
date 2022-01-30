{ config, lib, pkgs, ... }:
let 
  libdata = import ./manage_data.nix {inherit config lib pkgs;};
  read_ssh_data = pathlist: libdata.read_data ([ "ssh" ] ++ pathlist);
  read_ssh_data_else_empty = pathlist: libdata.read_data_else_empty ([ "ssh" ] ++ pathlist);
in
{
  get_authorized_keys = user: ssh_auth_keys:
    (builtins.map (ident: read_ssh_data [ "pubkeys" (ident + ".pub") ]) ssh_auth_keys) ++
    (pkgs.lib.splitString "\n" (read_ssh_data_else_empty [ "authorizedKeys" user ]));
}

{ config, lib, pkgs, ... }:
let
  libdata = import ./manage_data.nix {inherit config lib pkgs;};
in
{
  get_authorized_keys = user: ssh_auth_keys:
    builtins.map (ident: libdata.read_data ["pubkeys" "ssh" (ident + ".pub")]) ssh_auth_keys;
}

{ config, lib, pkgs, ... }:
let
  libdata = import ./manage_data.nix {inherit config lib pkgs;};
in rec
{
  get_authorized_keys = _: ssh_auth_keys:
    builtins.map (ident: libdata.read_data ["pubkeys" "ssh" (ident + ".pub")]) ssh_auth_keys;

  get_remote_builder_privk_path = machine: ["services" "remote_builder" machine];
  get_remote_builder_pubk = machine: libdata.get_data_path
    ["pubkeys" "remote_builder" "${machine}.pub"];
}

{ config, lib, pkgs, ... }: let
  libdata = import ../manage_data.nix { inherit config lib pkgs; };
in rec {
  get_pubkey = fqdn: libdata.get_data_path [ "pubkeys" "cachix" "${fqdn}-pub.pem" ];
  get_privkey_secret_pathlist = fqdn: ["services" "cachix" "${fqdn}-priv.pem" ];

  set_servers = server_list: lib.lists.foldl (acc: el:
    lib.attrsets.recursiveUpdate acc (set_server el)
  ) {} server_list;

  set_server = {fqdn, https ? false, path ? null, remote ? null}: let
    prefix = if https then "https://" else "http://";
    pubkey_file =
      if (!builtins.isNull path) then builtins.readFile path
      else if (!builtins.isNull remote) then let
          src = pkgs.fetchurl { inherit (remote) url sha256; };
        in builtins.readFile "${src}/${src.fname}"
      else builtins.readFile (get_pubkey fqdn);
  in {
    "${prefix}${fqdn}" = pubkey_file;
  };
}

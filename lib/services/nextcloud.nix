{ config, lib, pkgs, ... }:
let
  libdata = import ../manage_data.nix { inherit config lib pkgs;};
in
rec {
  occ = "${config.services.nextcloud.occ}/bin/nextcloud-occ";

  set_theme = args:
  let
    set_element = k: v: if builtins.isNull v then "" else "echo \"${k}\" && ${occ} theming:config ${k} \"${v}\"";
  in 
  lib.strings.concatStringsSep "\n" (lib.attrsets.mapAttrsToList set_element args);

  theme = fname: libdata.get_data_path [ "assets" "nextcloud" config.base.hostname fname ];
}

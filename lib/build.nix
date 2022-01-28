{ config, lib, pkgs, ... }:
let
  data = import ./data.nix;
  base_conf = import ../base/base.nix {config=config; lib=lib; pkgs=pkgs;};
in
  rec {

  # Import a common config from its name
  import_common_conf = confs : (
    builtins.foldl'
      (acc: conf: (acc // (import ( ../common + "/${conf}.nix") {config=config; lib=lib; pkgs=pkgs;})))
      {} confs
    );

  # Bootstrap a machine configuration based on machine name, main user and common configs
  bootstrap_machine = name : user : configs : auths :
  {
      networking.hostName = name;
      users.users."${user}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = (builtins.map (ident: data.ssh_pubkeys."${ident}") auths);
      };
    } // import_common_conf configs // base_conf;
}

{ config, lib, pkgs, pkgs_unstable, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};
in
libconf.create_common_confs [
  {
    name = "displaylink";
    parents = ["hardware"];
    cfg = {
      services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
      base.kernel.overrides = [(self: super: {
        evdi = super.evdi.overrideAttrs (o: rec {
          src = pkgs.fetchFromGitHub {
            owner = "DisplayLink";
            repo = "evdi";
            rev = "bdc258b25df4d00f222fde0e3c5003bf88ef17b5";
            sha256 = "mt+vEp9FFf7smmE2PzuH/3EYl7h89RBN1zTVvv2qJ/o=";
          };
        });
      })];
    };
  }
]

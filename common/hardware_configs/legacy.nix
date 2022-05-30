{ config, lib, pkgs, ... }:
let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "legacy";
    parents = ["hardware"];
    assertions = [
      {
        assertion = config.cmn.hardware.efi.enable or config.cmn.hardware.legacy.enable;
        message = "Define wether EFI or Legacy boot should be used (cmn.hardware.HERE.enable = true)";
      }
    ];
    cfg = {
      # TODO  Legacy boot configuration
    };
  }
]

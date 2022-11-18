{ config, lib, pkgs, ... }:
let
  cfg = config.base.kernel;
in
{
  options.base.kernel = {
    package = lib.mkOption {
      default = pkgs.linuxPackages_zen;
      description = "Linux kernel to use";
    };
    overrides = lib.mkOption {
      default = [];
      description = "Overrides kernel inner config";
    };
  };
  config = {
    boot.kernelPackages = cfg.package.extend (self: super:
      lib.lists.foldl
        (acc: el: lib.attrsets.recursiveUpdate acc (el self super))
        {}
        cfg.overrides
    );
  };
}

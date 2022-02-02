pkgs:
let
  prefix = "litchipi";

  list_dirs = root: pkgs.lib.attrNames (
    pkgs.lib.filterAttrs
      (name: entryType: entryType == "directory")
      (builtins.readDir root)
    );
in
  {
    litchipi = builtins.listToAttrs (builtins.map (package: {
      name = package;
      value = (pkgs.callPackage (./. + "/${package}/default.nix") {});
    }) (list_dirs ./.));
  }

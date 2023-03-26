{ lib, ...}:
{
  mkPackageSetsOptions = sets: builtins.mapAttrs (name: _: lib.mkEnableOption {
    description = "Enable the package set ${name}";
  }) sets;

  mkPackageSetsConfig = cfg: sets: lib.lists.flatten (lib.attrsets.mapAttrsToList (name: packages:
    if cfg.${name} then packages else []
  ) sets);
}

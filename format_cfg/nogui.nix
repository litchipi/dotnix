{ config, lib, ... }: {
  config = let
    set_all_false = tree: builtins.mapAttrs (name: cfg:
    if name == "enable"
      then lib.mkForce false
      else if builtins.isAttrs cfg then set_all_false cfg
      else cfg
    ) tree;
  in {
    # services.xserver.enable = lib.mkForce false; # = set_all_false config.services.xserver;
  };
}

{ config, lib, ... }: let
  libcolors = import ../colors.nix { inherit config lib; };

  isColorOpt = col: (col ? "r") && (col ? "g") && (col ? "b");
  isThemeOpt = val: (val ? "fg") || (val ? "bg") || (val ? "modifiers") || (val ? "style") || (val ? "color");
  isAddThemeAttr = x: !(builtins.elem x ["fg" "bg" "modifiers" "style" "color"]);

  toThemeAttr = val: with builtins;
    if isColorOpt val
      then "\"#${libcolors.toHex val}\""
    else if isString val
      then "\"${val}\""
    else if isList val
      then "[" + (concatStringsSep ", " (map toThemeAttr val)) + "]"
    else toString val;

  mkColorLine = parents: col: let
    key = builtins.concatStringsSep "." parents;
  in "\"${key}\" = \"#${libcolors.toHex col}\"";

  mkThemeAttrs = parents: val: let
    key = builtins.concatStringsSep "." parents;
    attrs = lib.attrsets.mapAttrsToList (name: v: 
      if isAddThemeAttr name
        then null
        else "${name} = ${toThemeAttr v}"
    ) val;
    all_attrs = builtins.concatStringsSep ", " (builtins.filter (x: !isNull x) attrs);
  in 
    "\"${key}\" = { ${all_attrs} }";

  getAddAttrs = parents: opts: lib.lists.flatten (
    builtins.filter (x: !isNull x) (
      lib.attrsets.mapAttrsToList (name: v:
        if isAddThemeAttr name
          then mkThemeLines (parents ++ [name]) v
          else null
      ) (if builtins.isAttrs opts
        then opts
        else builtins.trace (builtins.trace parents (builtins.throw "not attrs: ${opts}")))
    )
  );

  getAddAttrsLine = parents: opts: let
    addAttrs = getAddAttrs parents opts;
  in (
    if (builtins.length addAttrs) > 0
      then "\n" + (builtins.concatStringsSep "\n" addAttrs)
      else ""
  );
  
  mkThemeLines = parents: val:
    if isColorOpt val
      then mkColorLine parents val
    else if isThemeOpt val
      then (mkThemeAttrs parents val) + (getAddAttrsLine parents val)
    else if !(builtins.isAttrs val)
      then builtins.throw (builtins.trace parents "Theme is not attrs")
    else (lib.attrsets.mapAttrsToList (key: v: mkThemeLines (parents ++ [ key ]) v) val);

in {
  mkTheme = theme: builtins.concatStringsSep "\n" (
    lib.lists.flatten (mkThemeLines [] theme)
  );
}

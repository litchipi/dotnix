# Taken from https://github.com/chessai/nix-std
{ lib, ... }: data: with builtins;
  let
    tuple2 = _0: _1: { inherit _0 _1; };
    toList = s: map (k: tuple2 k s.${k}) (attrNames s);
    concatMapSep = sep: f: strs: concatStringsSep sep (map f strs);
    partition = p: xs:
      let bp = builtins.partition p xs;
      in tuple2 bp.right bp.wrong;

    # Escape a TOML key; if it is a string that's a valid identifier, we don't
    # need to add quotes
    tomlEscapeKey = val:
      # Identifier regex taken from https://toml.io/en/v1.0.0-rc.1#keyvalue-pair
      if isString val && match "[A-Za-z0-9_-]+" val != null
        then val
        else toJSON val;

    # Escape a TOML value
    tomlEscapeValue = toJSON;

    # Render a TOML value that appears on the right hand side of an equals
    tomlValue = v:
      if isList v
        then "[${concatMapSep ", " tomlValue v}]"
      else if isAttrs v
        then "{${concatMapSep ", " (kv: tomlKV kv._0 kv._1) (toList v)}}"
      else tomlEscapeValue v;

    # Render an inline TOML "key = value" pair
    tomlKV = k: v: "${tomlEscapeKey k} = ${tomlValue v}";

    # Turn a prefix like [ "foo" "bar" ] into an escaped header value like
    # "foo.bar"
    dots = concatMapSep "." tomlEscapeKey;

    # Render a TOML table with a header
    tomlTable = oldPrefix: k: v:
      let
        prefix = oldPrefix ++ [k];
        rest = go prefix v;
      in "[${dots prefix}]" + lib.strings.optionalString (rest != "") "\n${rest}";

    # Render a TOML array of attrsets using [[]] notation. 'subtables' should
    # be a list of attrsets.
    tomlTableArray = oldPrefix: k: subtables:
      let prefix = oldPrefix ++ [k];
      in concatMapSep "\n\n" (v:
        let rest = go prefix v;
        in "[[${dots prefix}]]" + lib.strings.optionalString (rest != "") "\n${rest}") subtables;

    # Wrap a string in a list, yielding the empty list if the string is empty
    optionalNonempty = str: if (str != "") then [str] else [];

    # Render an attrset into TOML; when nested, 'prefix' will be a list of the
    # keys we're currently in
    go = prefix: attrs:
      let
        attrList = toList attrs;

        # Render values that are objects using tables
        tableSplit = partition ({ _1, ... }: isAttrs _1) attrList;
        tablesToml = concatMapSep "\n\n"
          (kv: tomlTable prefix kv._0 kv._1)
          tableSplit._0;

        # Use [[]] syntax only on arrays of attrsets
        tableArraySplit = partition
          ({ _1, ... }: isList _1 && _1 != [] && lib.lists.all isAttrs _1)
          tableSplit._1;

        tableArraysToml = concatMapSep "\n\n"
          (kv: tomlTableArray prefix kv._0 kv._1)
          tableArraySplit._0;

        # Everything else becomes bare "key = value" pairs
        pairsToml = concatMapSep "\n" (kv: tomlKV kv._0 kv._1) tableArraySplit._1;
      in concatStringsSep "\n\n" (lib.lists.concatMap optionalNonempty [
        pairsToml
        tablesToml
        tableArraysToml
      ]);
  in if isAttrs data
    then go [] data
    else throw "toTOML: input data is not an attribute set, cannot be converted to TOML"

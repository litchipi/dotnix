{ config, lib, pkgs, ... }:
rec {
  mergeall = setlist: lib.lists.fold (set: acc: lib.attrsets.recursiveUpdate acc set) {} setlist;

  capitalizeWord = word: let
    letters = lib.strings.stringToCharacters word;
  in
    (lib.strings.toUpper  (builtins.elemAt letters 0)) + 
    (lib.strings.toLower (lib.strings.removePrefix (builtins.elemAt letters 0) word));

  email_to_name = email: let
    first_part = builtins.elemAt (lib.strings.splitString "@" email) 0;
  in
      lib.strings.concatStringsSep " "
    (builtins.map (w: capitalizeWord w) (lib.strings.splitString "." first_part));
}

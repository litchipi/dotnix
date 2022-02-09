{ config, lib, pkgs, ... }:
{
  mergeall = setlist: lib.lists.fold (set: acc: lib.attrsets.recursiveUpdate acc set) {} setlist;
}

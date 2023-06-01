{ pkgs, ... }: let
  patchGnomeExtension = pkg: version: pkg.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.jq ];
    patchPhase = ''
      FPATH=$(find . -name "metadata.json" | head -n 1)
      if [ -z "$FPATH" ]; then
        echo "metadata.json not found"
        exit 1;
      fi
      set -e
      cat "$FPATH" | jq '."shell-version" = ["${version}"]' > new_metadata.json
      mv new_metadata.json "$FPATH"
    '';
  });
in {
  adaptGnomeExtensions = version: pkglist: builtins.map (pkg: patchGnomeExtension pkg version) pkglist;
}

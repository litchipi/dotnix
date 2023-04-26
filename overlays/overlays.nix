self: super:
let
  prefix = "litchipi";

  list_dirs = root: self.lib.attrNames (
    self.lib.filterAttrs
      (name: entryType: entryType == "directory")
      (builtins.readDir root)
    );
in
  {
    litchipi = builtins.listToAttrs (builtins.map (package: {
      name = package;
      value = (self.callPackage (./. + "/${package}/default.nix") {});
    }) (list_dirs ./.));

    youtube-dl = self.stdenv.mkDerivation {
      name = "youtube-dl";
      src = self.fetchurl {
        url = "https://yt-dl.org/downloads/latest/youtube-dl";
        sha256 = "sha256-eIDgGr4oLH/VlvQpw1GJhRGA1hdzArshW+HN7HjW0G0=";
      };
      phases = "installPhase";
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/youtube-dl
        chmod +x $out/bin/youtube-dl
      '';
    };

    # Triple buffering patch on mutter
    gnome = super.gnome.overrideScope' (gself: gsuper: {
      mutter = super.gnome.mutter.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [
          ../data/patches/gnome.mutter/triple_buffering_43_4.patch
        ];
      });
    });
  }

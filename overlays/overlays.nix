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

    youtube-dl = pkgs.stdenv.mkDerivation {
      name = "youtube-dl";
      src = pkgs.fetchurl {
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
  }

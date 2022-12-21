{ pkgs, ...}: rec {
  all_fonts_extensions = [
    "otf"
    "ttf"
    "woff"
    "woff2"
  ];

  package_font = name: sha256: pkgs.stdenv.mkDerivation {
    name = "font_${name}";

    src = pkgs.fetchurl {
      url = "https://dl.dafont.com/dl/?f=${name}";
      inherit sha256;
    };

    buildInputs = [
      pkgs.unzip
    ];

    phases = "installPhase";
    installPhase = ''
      cp $src ${name}.zip
      mkdir -p $out/share/fonts/${name}
      unzip ${name}.zip
    '' + (builtins.concatStringsSep "\n" (builtins.map (ext: ''
      set -x
      echo "Extensions ${ext}"
      find -name '*.${ext}' -exec mv {} $out/share/fonts/${name} \;
    '') all_fonts_extensions));
  };
}

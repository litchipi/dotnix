{
  stdenv,
  lib,
  unzip,
  ...
}: stdenv.mkDerivation rec {
  pname = "firefly-iii-data-importer";
  version = "1.5.2";
  src = builtins.fetchurl { 
    url = "https://github.com/firefly-iii/data-importer/releases/download/v${version}/DataImporter-v${version}.zip";
    sha256 = "sha256:1ssxhgd6x4lp8ak5zkgj02hvpvdsgxafli9syb9lwrkkr9z8lyyg";
  };

  buildInputs = [ unzip ];

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  patches = [ ./storage_path_fromenv.patch ];
  # patchPhase = ''
  #   find . -name "*.php" -exec sed -E -i "s/= storage_path\((.*)\)/= env('STORAGE_PATH') . \1/g" {} \;
  # '';

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    cp -r . $out
  '';
}

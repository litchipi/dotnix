{ config, lib, pkgs, ... }: let
  cfg = config.freelance;
  docgen = pkgs.rustPlatform.buildRustPackage rec {
    pname = "docgen";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "litchipi";
      repo = "docgen";
      rev = "v${version}";
      sha256 = "sha256-YzvIdlYqcLcOH6nBhLuZu70aCzAeB1VaNs087qV0yz4=";
    };
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "comemo-0.3.1" = "sha256-myXQsrPx4NwIWli8VyKFbjUQaLhPXQA0achLO8g95Sg=";
        "svg2pdf-0.9.1" = "sha256-B54OZ/xuiE3q+kMwrfyDOLP6iEUpQL/aOexRKq1EvI8=";
        "typst-0.10.0" = "sha256-nSvYc/JUhDZGHFot7/WhhRbOBgNT+ZTVtKG71vY7raA=";
      };
    };
    buildInputs = [ pkgs.openssl ];
    nativeBuildInputs = [ pkgs.pkg-config ];

  };
in {
  options.freelance.docgen = {
    rootDir = lib.mkOption {
      type = lib.types.path;
      description = "Root to the document generated";
    };
    outputDir = lib.mkOption {
      type = lib.types.path;
      description = "Where to output generated documents";
    };
  };
  config = {
    setup.directories = [
      {
        path = cfg.docgen.rootDir;
        owner = config.base.user;
      }
      {
        path = cfg.docgen.outputDir;
        owner = config.base.user;
      }
    ];

    environment = {
      systemPackages = [ docgen ];
      variables.DOCGEN_ROOT = "${cfg.docgen.rootDir}";
      shellAliases = {
        facture = "${docgen}/bin/docgen invoice --outdir ${cfg.docgen.outputDir}/factures/";
        devis = "${docgen}/bin/docgen quotation --outdir ${cfg.docgen.outputDir}/devis/";
      };
    };
  };
}

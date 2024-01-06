{lib, rustPlatform, fetchFromGitHub }: rustPlatform.buildRustPackage rec {
  pname = "docgen";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "litchipi";
    repo = "docgen";
    rev = "f957832110b0647a8c7253fac6005ed328c29000";
    sha256 = "sha256-GoFyIAfNbgWDwKzUQRK9psgnCM0Ayc70J75UDBlDt6E=";
  };
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "comemo-0.3.1" = "sha256-myXQsrPx4NwIWli8VyKFbjUQaLhPXQA0achLO8g95Sg=";
      "svg2pdf-0.9.1" = "sha256-B54OZ/xuiE3q+kMwrfyDOLP6iEUpQL/aOexRKq1EvI8=";
      "typst-0.10.0" = "sha256-nSvYc/JUhDZGHFot7/WhhRbOBgNT+ZTVtKG71vY7raA=";
    };
  };
}

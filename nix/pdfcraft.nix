{
  lib,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  src,
}:

let
  craftI18n = fetchFromGitHub rec {
    name = "craft-i18n-${rev}";
    owner = "storytold";
    repo = "craft-i18n";
    rev = lib.fileContents "${src}/craft-i18n.rev";
    hash = "sha256-KTP2u+/3LHry7fOLUpv+UOXDBU7LZI5+1U9605jXtT4=";
  };

  models = builtins.filter (e: (e.kind or "") == "model") (lib.importTOML "${src}/ATTRIBUTION.toml").fetched;

  installModel =
    m:
    let
      model = fetchurl { inherit (m) url sha256; };
      licence = fetchurl {
        url = m.licence_url;
        sha256 = m.licence_sha256;
      };
    in
    ''
      install -Dm644 ${model} $out/share/pdfcraft/models/${m.file}
      install -Dm644 ${licence} $out/share/pdfcraft/models/${m.file}.LICENCE.txt
    '';
in
callPackage ./craft-app.nix { inherit rustPlatform; } {
  app = "pdfcraft";
  inherit src;
  description = "Read, organize, combine, split and secure PDFs";
  updatesFlag = "PDFCRAFT_UPDATES_MANAGED_EXTERNALLY";
  env = {
    CRAFT_I18N_DIR = "${craftI18n}";
    CRAFT_I18N_REQUIRED = "1";
  };
  extraInstall = lib.concatMapStrings installModel models;
}

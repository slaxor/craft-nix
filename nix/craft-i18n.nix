{ lib, fetchFromGitHub }:

src:

let
  hashes = {
    "575cfdef63227b14daf173b8cc87928bfdfa325e" = "sha256-KTP2u+/3LHry7fOLUpv+UOXDBU7LZI5+1U9605jXtT4=";
    "1e515422afdda2f317af430c1f9d68a5f83935b4" = "sha256-Z6Zmj5tqtMk2fCffSrF2mjP8rlRupOZZeAHW2qmYAuE=";
  };
  rev = lib.fileContents "${src}/craft-i18n.rev";
in
fetchFromGitHub {
  name = "craft-i18n-${rev}";
  owner = "storytold";
  repo = "craft-i18n";
  inherit rev;
  hash = hashes.${rev} or (throw "craft-i18n ${rev}: add its hash to nix/craft-i18n.nix (lib.fakeHash, then the one the build reports)");
}

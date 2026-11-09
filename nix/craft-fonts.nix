{ lib, fetchFromGitHub }:

src:

let
  lines = lib.splitString "\n" (builtins.readFile "${src}/.github/workflows/release.yml");
  matches = builtins.filter (m: m != null) (map (builtins.match " *craft-fonts-ref: ([0-9a-f]{40}).*") lines);
  rev =
    if matches == [ ] then
      throw "craft-fonts-ref not found in .github/workflows/release.yml"
    else
      builtins.head (builtins.head matches);
in
fetchFromGitHub {
  name = "craft-fonts-${rev}";
  owner = "storytold";
  repo = "craft-fonts";
  inherit rev;
  hash = "sha256-jZ3VBAJDofB6RvsS7GGV5lLT4xiShIjpz5XHBCD2oUc=";
}

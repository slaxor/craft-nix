{ lib, fetchFromGitHub }:

src:

let
  hashes = {
    b076417b5880bd4154bd22f00695b1d28c6bea83 = "sha256-jZ3VBAJDofB6RvsS7GGV5lLT4xiShIjpz5XHBCD2oUc=";
    "37827adc41fd165f9a9234ac40f94dbad353aa69" = "sha256-BfFMLP2LLrKS246gGpj26ECVRa5/Ggzkesf0OBrfGu8=";
  };

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
  hash = hashes.${rev} or (throw "craft-fonts ${rev}: add its hash to nix/craft-fonts.nix (lib.fakeHash, then the one the build reports)");
}

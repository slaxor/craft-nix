{
  callPackage,
  rustPlatform,
  src,
}:

let
  craftFonts = callPackage ./craft-fonts.nix { } src;
in
callPackage ./craft-app.nix { inherit rustPlatform; } {
  app = "vectorcraft";
  inherit src;
  description = "Draw and edit vector illustrations, SVG and PDF";
  updatesFlag = "VECTORCRAFT_UPDATES_MANAGED_EXTERNALLY";
  env = {
    CRAFT_FONTS_DIR = "${craftFonts}";
    CRAFT_FONTS_REQUIRED = "1";
  };
  extraInstall = ''
    for ofl in ${craftFonts}/fonts/*/OFL.txt; do
      install -Dm644 "$ofl" "$out/share/doc/vectorcraft/OFL-$(basename "$(dirname "$ofl")").txt"
    done
  '';
}

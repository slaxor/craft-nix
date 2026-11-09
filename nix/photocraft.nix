{
  callPackage,
  rustPlatform,
  src,
}:

let
  craftFonts = callPackage ./craft-fonts.nix { } src;
in
callPackage ./craft-app.nix { inherit rustPlatform; } {
  app = "photocraft";
  inherit src;
  description = "Edit photos and layered PSD documents";
  updatesFlag = "PHOTOCRAFT_UPDATES_MANAGED_EXTERNALLY";
  env = {
    CRAFT_FONTS_DIR = "${craftFonts}";
    CRAFT_FONTS_REQUIRED = "1";
  };
  extraInstall = ''
    for ofl in ${craftFonts}/fonts/*/OFL.txt; do
      install -Dm644 "$ofl" "$out/share/doc/photocraft/OFL-$(basename "$(dirname "$ofl")").txt"
    done
  '';
}

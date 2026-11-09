{
  lib,
  callPackage,
  rustPlatform,
}:

{
  app,
  src,
  description,
  fonts ? true,
  buildInputs ? [ ],
  runtimeLibs ? [ ],
  ...
}:

let
  craftFonts = callPackage ./craft-fonts.nix { } src;
in
callPackage ./craft-app.nix { inherit rustPlatform; } {
  inherit
    app
    src
    description
    buildInputs
    runtimeLibs
    ;
  env = lib.optionalAttrs fonts {
    CRAFT_FONTS_DIR = "${craftFonts}";
    CRAFT_FONTS_REQUIRED = "1";
  };
  extraInstall = lib.optionalString fonts ''
    for ofl in ${craftFonts}/fonts/*/OFL.txt; do
      install -Dm644 "$ofl" "$out/share/doc/${app}/OFL-$(basename "$(dirname "$ofl")").txt"
    done
  '';
}

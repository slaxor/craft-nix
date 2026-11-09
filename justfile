update-apps:
    nix flake update pdfcraft-src vectorcraft-src photocraft-src lightcraft-src soundcraft-src designcraft-src figcraft-src filmcraft-src deckcraft-src cadcraft-src wordcraft-src gridcraft-src effectcraft-src materialcraft-src texturecraft-src

update-app app:
    nix flake update {{ app }}-src

update-base:
    nix flake update nixpkgs rust-overlay

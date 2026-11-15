update-apps:
    nix flake update pdfcraft-src vectorcraft-src photocraft-src lightcraft-src soundcraft-src designcraft-src figcraft-src filmcraft-src deckcraft-src cadcraft-src wordcraft-src gridcraft-src effectcraft-src materialcraft-src texturecraft-src
    nix flake check

update-app app:
    nix flake update {{ app }}-src

update-base:
    nix flake update nixpkgs rust-overlay

check:
    nix flake check

# prints the "got:" hash for nix/cargo-vendor-hashes.nix
vendor-hash app:
    nix build --no-link .#{{ app }}.unwrapped.cargoDeps

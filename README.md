# craft-nix

Nix packages and Home Manager modules for the storytold *Craft apps, built from upstream's source
for x86_64-linux and aarch64-linux. Upstream isn't forked: each app is a `flake = false` input, and
the only change is one small patch per app (see [Patches](#patches)).

| App | What it does |
|---|---|
| [pdfcraft](https://github.com/storytold/pdfcraft) | Read, organize, combine, split and secure PDFs |
| [vectorcraft](https://github.com/storytold/vectorcraft) | Draw and edit vector illustrations, SVG and PDF |
| [photocraft](https://github.com/storytold/photocraft) | Edit photos and layered PSD documents |
| [lightcraft](https://github.com/storytold/lightcraft) | Organise photos and develop raw files, non-destructively |
| [soundcraft](https://github.com/storytold/soundcraft) | Record, edit and mix audio and MIDI |
| [designcraft](https://github.com/storytold/designcraft) | Lay out magazines, books and print documents |
| [figcraft](https://github.com/storytold/figcraft) | Design and prototype user interfaces |
| [filmcraft](https://github.com/storytold/filmcraft) | Edit video, color and sound |
| [deckcraft](https://github.com/storytold/deckcraft) | Create and present slide decks |
| [cadcraft](https://github.com/storytold/cadcraft) | Draft, dimension and plot 2D drawings |

What differs per app (fonts, extra libraries) is the table in `nix/apps.nix`; pdfcraft has its own
`nix/pdfcraft.nix` for translations and OCR models, every other app builds with
`nix/generic-app.nix`.

## Use

```sh
nix run github:slaxor/craft-nix#pdfcraft -- some.pdf
nix build github:slaxor/craft-nix#vectorcraft   # ./result/bin/vectorcraft and ./result/bin/vectorcraft-cli
```

With Home Manager on NixOS (`alice` and `./configuration.nix` are yours):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    craft-nix.url = "github:slaxor/craft-nix";
  };

  outputs = { nixpkgs, home-manager, craft-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.sharedModules = [ craft-nix.homeModules.default ];
          home-manager.users.alice.programs = {
            pdfcraft = {
              enable = true;
              defaultFor = [ "application/pdf" ];
            };
            vectorcraft = {
              enable = true;
              defaultFor = [ "image/svg+xml" "application/x-vectorcraft" ];
            };
            photocraft.enable = true;
          };
        }
      ];
    };
  };
}
```

Each `programs.<app>` has:

- `enable`: install the app (desktop entry, MIME types, icons, metainfo, `<app>-cli`).
- `defaultFor`: MIME types it opens by default (`xdg.mimeApps`), empty by default: the apps claim
  many types (PhotoCraft PNG and JPEG, VectorCraft PDF), so nothing is taken over unasked. A type
  the app's desktop entry doesn't list stops the build with
  `programs.<app>.defaultFor: <App> doesn't open <type>`.
- `package`: another build.

`homeModules.default` holds all of them; `homeModules.pdfcraft` etc. one each. Without Home Manager,
add `craft-nix.packages.${pkgs.stdenv.hostPlatform.system}.pdfcraft` to `environment.systemPackages`,
or apply `overlays.default` and use `pkgs.pdfcraft`. Don't set `inputs.nixpkgs.follows` for
craft-nix: the packages build with their own locked Rust toolchain.

## What the builds contain

- **Toolchain:** the official Rust toolchain from [rust-overlay](https://github.com/oxalica/rust-overlay).
  nixpkgs' `rustc` links a newer system LLVM that rejects AVX-512 code in PdfCraft's OCR engine.
- **PdfCraft:** the interface translations (craft-i18n, the revision in `craft-i18n.rev`) and the OCR
  models listed in `ATTRIBUTION.toml`, with their licences.
- **Every other app except SoundCraft:** the fonts from craft-fonts, the revision its `release.yml`
  pins (`craft-fonts-ref`), with the OFL licences. SoundCraft embeds none.
- **Extra libraries:** ALSA for SoundCraft, FilmCraft and DeckCraft (audio through `cpal`),
  fontconfig for FigCraft.
- The `[[patch.unused]]` entries of each `Cargo.lock` are dropped from the `[patch]` sections of
  `Cargo.toml` before the build: Nix vendors only the crates `Cargo.lock` uses, and offline cargo
  rejects a patch pointing at a missing crate.

## Patches

`patches/<app>-updates-managed-externally.patch` adds one build-time switch,
`<APP>_UPDATES_MANAGED_EXTERNALLY`, which the packages set, so the app never checks for updates at
start. Nix delivers updates, and a self-update can't replace a binary in the Nix store anyway.

- **pdfcraft, vectorcraft, photocraft:** **Help › Check for Updates** is off as well (menus,
  command palette, automation) and the preference for the check at start is hidden; the patches
  have tests for both settings.
- **The other seven:** only the check at start is off (one guarded line in `updates_ui.rs`), so
  **Help › Check for Updates** still asks when chosen. These patches are kept to that one line
  because every extra hunk is another place an upstream change breaks them.

For pdfcraft, vectorcraft and photocraft the rest was audited too (per binary: network crates,
sockets, spawned programs, URL opening): apart from the update check none contacts anything on its
own. Their sockets are localhost only and opt-in (`--control`) or local IPC (single instance);
PdfCraft asks before a document opens a link and never submits forms; VectorCraft's plugins run
sandboxed without network. For the other seven a lighter check (the network crates in `Cargo.lock`,
sockets and outgoing connections in the source) found the same: localhost control ports, and
network use only when asked for: LightCraft's remote denoise (`lightcraft-cli denoise-serve` on
another machine), FigCraft's live collaboration sessions, and FilmCraft's speech models, downloaded
only after a confirmation that shows size, source and licence, and checked against their SHA-256.

## Updating

```sh
nix flake update                 # everything
nix flake update pdfcraft-src    # one app
nix flake check --no-build --all-systems
```

`nix flake check` evaluates both systems: per app, the Home Manager module (against a small stub of
Home Manager's options) and the package settings (update switch set, patch carried, translations or
fonts pinned where the app has them). It doesn't build; `nix build .#<app>` does, and is where a stale patch or hash shows.

**A patch no longer applies** (`nix build` fails in `patchPhase`): upstream changed the code around
the update check. Redo the change on upstream's current source and regenerate the patch, inside
this repo's dev shell (`nix develop` or `use flake` with direnv: the Rust toolchain, the build tools
and the libraries the tests load):

```sh
git clone https://github.com/storytold/pdfcraft && cd pdfcraft
git apply --3way ../craft-nix/patches/pdfcraft-updates-managed-externally.patch   # resolve what's left
cargo test -p pdfcraft-ui-egui --test it updates
git diff > ../craft-nix/patches/pdfcraft-updates-managed-externally.patch
```

**A hash mismatch for craft-i18n, or a new craft-fonts revision:** upstream moved the pinned
revision (it is part of the fetch's name, so a stale hash fails instead of reusing old files). For
craft-i18n put the hash from the error into `nix/pdfcraft.nix`; for craft-fonts add the revision to
the table in `nix/craft-fonts.nix` (the error names it), with `lib.fakeHash` first and then the hash
the build reports.

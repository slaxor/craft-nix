# craft-nix

Nix packages and Home Manager modules for the [storytold](https://github.com/storytold) *Craft apps,
built from upstream's source for x86_64-linux and aarch64-linux.

Upstream isn't forked or patched (one line for PhotoCraft aside). Each app is a `flake = false`
input, and the apps never check for updates themselves, because updates come from Nix (see
[Updates](#updates)).

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
| [wordcraft](https://github.com/storytold/wordcraft) | Write and design documents; open and save Word files |
| [gridcraft](https://github.com/storytold/gridcraft) | Calculate, analyse and chart data in workbooks |
| [effectcraft](https://github.com/storytold/effectcraft) | Motion graphics and visual effects compositor |
| [materialcraft](https://github.com/storytold/materialcraft) | Design procedural PBR materials with node graphs |
| [texturecraft](https://github.com/storytold/texturecraft) | Paint PBR textures directly on 3D meshes |

GitHub Actions builds every app for both systems on each push to `master` and puts the results in a
binary cache, so a machine using this flake downloads them instead of compiling (see
[Binary cache](#binary-cache)). Without the cache each app compiles from source, which takes a while.

## Binary cache

```nix
nix.settings = {
  substituters = [ "https://craft-nix.cachix.org" ];
  trusted-public-keys = [ "craft-nix.cachix.org-1:REPLACE-WITH-THE-CACHE-KEY" ];
};
```

The cache holds what CI built from this repository's `flake.lock`, so it only matches when the apps
build against that lock: leave out `inputs.nixpkgs.follows` (below). A `master` commit is in the
cache once its [build](../../actions/workflows/build.yml) is green.

## Try one

```sh
nix run github:slaxor/craft-nix#pdfcraft -- some.pdf
nix shell github:slaxor/craft-nix#gridcraft   # gridcraft and gridcraft-cli on PATH
```

## Install with Home Manager

Add the input to your flake:

```nix
inputs.craft-nix.url = "github:slaxor/craft-nix";
```

Import the module:

```nix
home-manager.sharedModules = [ craft-nix.homeModules.default ];   # Home Manager as a NixOS module
modules = [ craft-nix.homeModules.default ./home.nix ];           # standalone homeConfigurations.<name>
```

Enable apps in your Home Manager configuration:

```nix
programs.pdfcraft = {
  enable = true;
  defaultFor = [ "application/pdf" ];
};
programs.wordcraft.enable = true;
```

A complete flake for a NixOS host with Home Manager (`myhost`, `alice` and `./configuration.nix`
are yours):

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
              defaultFor = [ "image/svg+xml" ];
            };
            photocraft.enable = true;
          };
        }
      ];
    };
  };
}
```

### Options

Every app has the same three under `programs.<app>`:

- `enable`: install the app with its desktop entry, MIME types, icons, metainfo and `<app>-cli`.
- `defaultFor`: MIME types the app opens by default (through `xdg.mimeApps`). Empty unless you set
  it: the apps claim many types (PhotoCraft PNG and JPEG, VectorCraft PDF), so nothing is taken over
  unasked. A type the app's desktop entry doesn't list stops the build with
  `programs.<app>.defaultFor: <App> doesn't open <type>`. EffectCraft lists none.
- `package`: use a different build.

`homeModules.default` contains all apps; `homeModules.pdfcraft` and so on contain one each.

## Install without Home Manager

```nix
environment.systemPackages = [
  craft-nix.packages.${pkgs.stdenv.hostPlatform.system}.pdfcraft
];
```

Or add `craft-nix.overlays.default` to `nixpkgs.overlays` and use `pkgs.pdfcraft`. Default
applications are then set with NixOS's `xdg.mime.defaultApplications`.

### `inputs.nixpkgs.follows`

Best left out. With `follows`, the apps build against your nixpkgs instead of the one locked here,
a combination nobody has tested. Leaving it out costs one more nixpkgs in your store.

## Requirements on the desktop

**File › Open** and **Save As** use the XDG desktop portal's file chooser. Full desktops (GNOME,
KDE) run one already. On Sway, NixOS's `programs.sway.enable` sets up `xdg-desktop-portal-wlr` and
`-gtk`; elsewhere enable `xdg.portal` with a backend that has a file chooser
(`xdg-desktop-portal-gtk`, for example). Without a portal the apps fall back to `zenity` if it is
installed; otherwise the dialog doesn't open.

Printing goes through CUPS; its client tools are on the apps' `PATH`.

## What the builds contain

- **Toolchain:** the official Rust toolchain from [rust-overlay](https://github.com/oxalica/rust-overlay).
  nixpkgs' `rustc` links a newer system LLVM that rejects AVX-512 code in PdfCraft's OCR engine.
- **Release settings:** optimised builds, with the bundled C libraries (aws-lc and others) built as
  upstream's releases build them.
- **PdfCraft and WordCraft:** the interface translations (craft-i18n, the revision in
  `craft-i18n.rev`); PdfCraft also the OCR models listed in `ATTRIBUTION.toml`, with their licences.
- **Every other app except SoundCraft, EffectCraft and MaterialCraft:** the fonts from craft-fonts,
  the revision its `release.yml` pins (`craft-fonts-ref`), with the OFL licences. Those three embed
  none (MaterialCraft's release pins a revision, but its build doesn't read it yet).
- **Extra libraries:** ALSA for SoundCraft, FilmCraft, DeckCraft and EffectCraft (audio through
  `cpal`), fontconfig for FigCraft and WordCraft, D-Bus for the file chooser.
- The `[[patch.unused]]` entries of each `Cargo.lock` are dropped from the `[patch]` sections of
  `Cargo.toml` before the build: Nix vendors only the crates `Cargo.lock` uses, and offline cargo
  rejects a patch pointing at a missing crate.

## Updates

The apps share one updater, craft-update, which reads a small file the ArtCraft launcher writes
when someone keeps an app on a chosen version. An app listed there checks for nothing: neither at
start nor through **Help › Check for Updates**, which then says the app "follows the version chosen
in the launcher". The packages use that: each app's wrapper sets `CRAFT_VERSIONS_FILE` to a file in
the Nix store that pins the app to its own version, `{"apps":{"pdfcraft":{"Pinned":"0.18.1"}}}`.
The source stays as upstream wrote it, so an upstream change can't break a patch.

The wrapper only sets a default: `CRAFT_VERSIONS_FILE` from your environment wins.

**PhotoCraft** is the exception: it asks GitHub through its own service, past the updater, so its
package carries one line (`patches/photocraft-updates-managed-externally.patch`): built with
`PHOTOCRAFT_UPDATES_MANAGED_EXTERNALLY` set, it has no update service at all.

### Network use

For pdfcraft, vectorcraft and photocraft the code was audited too (per binary: network crates,
sockets, spawned programs, URL opening): apart from the update check none contacts anything on its
own. Their sockets are localhost only and opt-in (`--control`) or local IPC (single instance);
PdfCraft asks before a document opens a link and never submits forms; VectorCraft's plugins run
sandboxed without network.

For the other twelve a lighter check (the network crates in `Cargo.lock`, sockets and outgoing
connections in the source) found the same: localhost control ports, and network use only when asked
for: LightCraft's remote denoise (`lightcraft-cli denoise-serve` on another machine), FigCraft's
live collaboration sessions, FilmCraft's speech models and EffectCraft's segmentation models,
downloaded only when asked for and checked against their SHA-256. The `reqwest`/`quinn` in
WordCraft's and GridCraft's `Cargo.lock` come from the Windows printing crate and aren't built on
Linux.

## Not packaged

- **anicraft:** early alpha, no Linux packaging yet.
- **artcraft:** a different stack (Tauri and WebKitGTK).
- **craft-launcher:** installs and updates the apps itself, which is Nix's job here.
- **craft-anything:** built around AI providers and downloads.

The printcraft and drawcraft repositories are the old names of pdfcraft and vectorcraft.

## Maintaining

The recipes in the `justfile` keep updates deliberate, since every updated input means a rebuild:

```sh
just update-apps          # all *-src inputs, then nix flake check
just update-app pdfcraft  # one app
just update-base          # nixpkgs and rust-overlay: rebuilds every app
just check                # nix flake check
```

`nix flake check` evaluates, per app, the Home Manager module (against a small stub of Home
Manager's options) and the package settings (pinned to its own version, patched only where needed,
translations or fonts pinned where the app has them). `nix flake check --no-build --all-systems`
evaluates both systems. Whether an app still builds only `nix build .#<app>` shows.

What differs per app is the table in `nix/apps.nix` (description, fonts, translations, extra
libraries). pdfcraft has its own `nix/pdfcraft.nix` for its OCR models; every other app builds with
`nix/generic-app.nix`. Adding an app takes an input `<app>-src` in `flake.nix`, an entry in
`nix/apps.nix`, and the app's name in `just update-apps`. Check first that its update check goes
through craft-update's `Updater` (as `check_at_start`/`check_now`); one that calls
`check_for_update` directly, like PhotoCraft, needs a patch in `patches/`.

**PhotoCraft's patch no longer applies:** upstream changed the line that sets `check_updates` in
`apps/photocraft/src/services.rs`. Make the same change on the current source and regenerate it:

```sh
git clone https://github.com/storytold/photocraft && cd photocraft
$EDITOR apps/photocraft/src/services.rs   # check_updates: option_env!(…).is_none().then(…)
PHOTOCRAFT_UPDATES_MANAGED_EXTERNALLY=1 cargo check -p photocraft
git diff > ../craft-nix/patches/photocraft-updates-managed-externally.patch
```

**A hash mismatch for craft-i18n, or a new craft-fonts revision:** upstream moved the pinned
revision (it is part of the fetch's name, so a stale hash fails instead of reusing old files). Add
the revision to the table in `nix/craft-i18n.nix` or `nix/craft-fonts.nix` (the error names it),
with `lib.fakeHash` first and then the hash the build reports.

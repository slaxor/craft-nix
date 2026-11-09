{
  description = "Nix packages and Home Manager modules for the storytold *Craft apps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pdfcraft-src = {
      url = "github:storytold/pdfcraft";
      flake = false;
    };
    vectorcraft-src = {
      url = "github:storytold/vectorcraft";
      flake = false;
    };
    photocraft-src = {
      url = "github:storytold/photocraft";
      flake = false;
    };
    lightcraft-src = {
      url = "github:storytold/lightcraft";
      flake = false;
    };
    soundcraft-src = {
      url = "github:storytold/soundcraft";
      flake = false;
    };
    designcraft-src = {
      url = "github:storytold/designcraft";
      flake = false;
    };
    figcraft-src = {
      url = "github:storytold/figcraft";
      flake = false;
    };
    filmcraft-src = {
      url = "github:storytold/filmcraft";
      flake = false;
    };
    deckcraft-src = {
      url = "github:storytold/deckcraft";
      flake = false;
    };
    cadcraft-src = {
      url = "github:storytold/cadcraft";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      appNames = builtins.attrNames (import ./nix/apps.nix null);
      srcs = lib.genAttrs appNames (app: inputs."${app}-src");

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ rust-overlay.overlays.default ];
            }
          )
        );

      packagesFor =
        p:
        let
          toolchain = p.rust-bin.stable.latest.minimal;
          rustPlatform = p.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          };
          build =
            app: spec:
            if app == "pdfcraft" then
              p.callPackage ./nix/pdfcraft.nix {
                inherit rustPlatform;
                src = srcs.${app};
              }
            else
              p.callPackage ./nix/generic-app.nix { inherit rustPlatform; } (
                spec
                // {
                  inherit app;
                  src = srcs.${app};
                }
              );
        in
        builtins.mapAttrs build (import ./nix/apps.nix p);

      moduleFor =
        app:
        import ./nix/hm-module.nix {
          inherit self app;
          displayName = (import ./nix/apps.nix null).${app}.displayName;
          src = srcs.${app};
        };
    in
    {
      packages = forAllSystems packagesFor;

      overlays.default = final: _prev: packagesFor (final.extend rust-overlay.overlays.default);

      homeModules = lib.genAttrs appNames moduleFor // {
        default.imports = map moduleFor appNames;
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            (rust-bin.stable.latest.default.override { extensions = [ "rust-src" ]; })
            cmake
            perl
            pkg-config
            nixfmt
          ];
          buildInputs = with pkgs; [
            alsa-lib
            fontconfig
          ];
          LD_LIBRARY_PATH = lib.makeLibraryPath (
            with pkgs;
            [
              dbus
              fontconfig
              libGL
              libx11
              libxcursor
              libxi
              libxkbcommon
              libxrandr
              vulkan-loader
              wayland
            ]
          );
        };
      });

      checks = forAllSystems (
        pkgs:
        import ./nix/checks.nix {
          inherit pkgs self srcs;
          apps = import ./nix/apps.nix pkgs;
        }
      );
    };
}

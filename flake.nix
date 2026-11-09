{
  description = "Nix packages and Home Manager modules for PdfCraft, VectorCraft and PhotoCraft";

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
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }@inputs:
    let
      apps = {
        pdfcraft = "PdfCraft";
        vectorcraft = "VectorCraft";
        photocraft = "PhotoCraft";
      };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
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
        in
        builtins.mapAttrs (
          app: _:
          p.callPackage ./nix/${app}.nix {
            inherit rustPlatform;
            src = inputs."${app}-src";
          }
        ) apps;

      moduleFor =
        app: displayName:
        import ./nix/hm-module.nix {
          inherit self app displayName;
          src = inputs."${app}-src";
        };
    in
    {
      packages = forAllSystems packagesFor;

      overlays.default = final: _prev: packagesFor (final.extend rust-overlay.overlays.default);

      homeModules = builtins.mapAttrs moduleFor apps // {
        default.imports = builtins.attrValues (builtins.mapAttrs moduleFor apps);
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
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
            with pkgs;
            [
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
          inherit pkgs self apps;
          srcs = builtins.mapAttrs (app: _: inputs."${app}-src") apps;
        }
      );
    };
}

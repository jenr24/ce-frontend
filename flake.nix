{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-21.11";
    naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, naersk, flake-compat }:
    flake-utils.lib.eachDefaultSystem (system:
      let

        pkgs = import nixpkgs {
          inherit system;

          overlays = [ rust-overlay.overlay ];
        };

        rust-build = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
          extensions = ["rust-src"];
          targets = [ "wasm32-unknown-unknown" ];
        });

        naersk-lib = naersk.lib."${system}".override {
          rustc = rust-build;
          cargo = rust-build;
        };

        ce-frontend = naersk-lib.buildPackage {
          pname = "ce-frontend";
          root = ./.;
          cargoBuildOptions = options: options ++ [
            "--target=wasm32-unknown-unknown"
          ];
        };

      in rec {
        packages = flake-utils.lib.flattenTree {
          ce-frontend = ce-frontend;
        };

        defaultPackage = packages.ce-frontend;

        devShell =
          pkgs.mkShell {
            buildInputs = with pkgs; [
              rust-build trunk wasm-bindgen-cli rls rust-analyzer zlib
            ];
          };
      });
}
{
  description = "Flash blink to an attiny85";

  inputs = {
    # https://nixpkgs-tracker.ocfox.me/?pr=472986
    # nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      name = (fromTOML (builtins.readFile ./Cargo.toml)).package.name;
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem =
        with nixpkgs.lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in
    eachSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        rustPlatform = pkgs.makeRustPlatform {
          rustc = toolchain;
          cargo = toolchain;
        };
      in
      {
        packages = {
          default = self.packages.${system}.${name};
          ${name} = rustPlatform.buildRustPackage (finalAttrs: {
            inherit name;
            version = (fromTOML (builtins.readFile ./Cargo.toml)).package.version;
            src = ./.;
            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes."attiny-hal-0.1.0" = "sha256-dT4ClJC2eysro92JSuLVGRINGzgkxKZQjBad/UxVDd0=";
            };
          });
        };

        apps.default = {
          type = "app";
          program =
            let
              inherit (pkgs)
                lib
                writeShellApplication
                ravedude
                pkgsCross
                ;
              flash = writeShellApplication {
                name = "flash";
                runtimeInputs = [
                  pkgsCross.avr.buildPackages.gcc
                  ravedude
                ];
                text = "ravedude ${self.outputs.packages.${system}.${name}}";
              };
            in
            lib.getExe flash;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            toolchain
          ]
          ++ (with pkgs; [
            avrdude
            pkgsCross.avr.buildPackages.gcc
            ravedude
          ]);
        };
      }
    );
}

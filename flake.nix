{
  description = "Flash blink to an attiny85";

  inputs = {
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
      inherit ((fromTOML (builtins.readFile ./Cargo.toml)).package) name;
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
        rustPlatform =
          let
            pkgsCross = import nixpkgs {
              inherit system;
              crossSystem = {
                inherit system;
                rust.rustcTarget = "avr-none";
              };
            };
          in
          pkgsCross.makeRustPlatform {
            rustc = toolchain;
            cargo = toolchain;
          };
      in
      {
        packages = {
          default = self.packages.${system}.${name};
          ${name} = rustPlatform.buildRustPackage {
            inherit name;
            inherit ((fromTOML (builtins.readFile ./Cargo.toml)).package) version;
            src = pkgs.lib.cleanSource ./.;
            env.RUSTFLAGS =
              let
                inherit (pkgs) lib pkgsCross;
              in
              lib.concatStringsSep " " [
                "-C linker=${lib.getExe pkgsCross.avr.buildPackages.gcc}"
                "-C target-cpu=attiny85"
              ];
            nativeBuildInputs = with pkgs; [ pkgsCross.avr.gcc ];
            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes."attiny-hal-0.1.0" = "sha256-dT4ClJC2eysro92JSuLVGRINGzgkxKZQjBad/UxVDd0=";
            };
            meta.mainProgram = "relay.elf";
          };
        };

        apps = {
          default = self.outputs.apps.${system}.flash;
          flash = {
            type = "app";
            program =
              let
                inherit (pkgs) lib;
                flasher = pkgs.writeShellApplication {
                  name = "ravedude-with-avr-gcc";
                  runtimeInputs = with pkgs; [
                    pkgsCross.avr.buildPackages.gcc
                    ravedude
                  ];
                  text = "ravedude ${lib.getExe self.outputs.packages.${system}.${name}}";
                };
              in
              lib.getExe flasher;
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [
            self.outputs.packages.${system}.${name}
            self.outputs.apps.${system}.default
          ];
        };
      }
    );
}

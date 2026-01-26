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
          # crossSystem = nixpkgs.lib.systems.examples.avr // {
          # system = "avr";
          #   rust.rustcTarget = "avr-none";
          #   };
          crossSystem = {
            inherit system;
            rust.rustcTarget = "avr-none";
          };
          # overlays = [ (import rust-overlay) ];
        };
        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        # toolchain = pkgs.rust-bin.selectLatestNightlyWith (
        #   toolchain:
        #   toolchain.minimal.override {
        #     extensions = [
        #       "rust-src"
        #       "rust-std"
        #     ];
        #     # targets = [ "avr-none" ];
        # }
        # );

        # rustPlatform = pkgs.makeRustPlatform {
        #   rustc = toolchain;
        #   cargo = toolchain;
        # };
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
          ${name} =
            let
              sysroot = pkgs.symlinkJoin {
                name = "rustc_unwrapped_with_libsrc";
                paths = [
                  pkgs.buildPackages.rustc.unwrapped
                ];
                postBuild = ''
                  mkdir -p $out/lib/rustlib/src/rust
                  ln -s ${pkgs.rustPlatform.rustLibSrc} $out/lib/rustlib/src/rust/library
                '';
              };
              rustcWithLibSrc = pkgs.buildPackages.rustc.override { inherit sysroot; };
              buildRustPackage = pkgs.rustPlatform.buildRustPackage.override {
                rustc = rustcWithLibSrc.unwrapped;
                cargo = (pkgs.buildPackages.cargo.override { rustc = rustcWithLibSrc.unwrapped; });
              };
            in
            buildRustPackage (finalAttrs: {
              inherit name;
              version = (fromTOML (builtins.readFile ./Cargo.toml)).package.version;
              # src = ./.;
              src = pkgs.lib.cleanSource ./.;
              # cargoHash = "";
              # cargoHash = "sha256-pTUqFX7f72KB8HFdNRrJEQFgdyZ9a652goFe5PxctcE=";
              # cargoHash = "sha256-XSbZBUKxkX/Ier1VESCWMFiA83njRxGgCmZnZi2+Xr8=";
              # cargoHash = "sha256-yOQ/MKD1w8tE+oeetpFvts2Mxr7UWPgpq3TOcnh8zs4=";
              nativeBuildInputs = with pkgs; [ pkgsCross.avr.buildPackages.gcc ];
              # RUSTFLAGS = pkgs.lib.concatStringsSep " " [
              #   "-A dead_code"
              #   # "-C target-feature="
              #   "-C target-cpu=attiny85"
              #   "-Z build-std=core"
              # ];
              env = {
                RUSTC_BOOTSTRAP = 1;
                RUSTFLAGS = pkgs.lib.concatStringsSep " " [
                  "-A dead_code"
                  # "-C target-feature="
                  "-C target-cpu=attiny85"
                  "-Z build-std=core"
                ];
              };
              cargoLock = {
                lockFile = ./Cargo.lock;
                # lockFileContents = builtins.readFile ./Cargo.lock;
                # lockFileContents = builtins.readFile ./Cargo.lock + ''
                #   [[package]]
                #   name = "wasi"
                #   version = "0.14.7+wasi-0.2.4"
                #   source = "registry+https://github.com/rust-lang/crates.io-index"
                #   checksum = "883478de20367e224c0090af9cf5f9fa85bed63a95c1abf3afc5c083ebc06e8c"
                #   dependencies = [
                #    "wasip2",
                #   ]
                # '';
                outputHashes."attiny-hal-0.1.0" = "sha256-dT4ClJC2eysro92JSuLVGRINGzgkxKZQjBad/UxVDd0=";
              };
              # cargoHash = "";
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
            # toolchain
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

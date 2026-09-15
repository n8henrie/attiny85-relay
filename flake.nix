{
  description = "Flash blink to an attiny85";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      inherit ((fromTOML (builtins.readFile ./Cargo.toml)).package) name;
      systems = [
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
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          default = self.packages.${system}.${name};
          ${name} = pkgs.callPackage ./package.nix {
            avrGcc = pkgs.pkgsCross.avr.buildPackages.gcc;
            rustPlatform = pkgs.callPackage ./rustplatform-with-src.nix { };
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
          packages = [ pkgs.ravedude ];
          env.RUSTC_BOOTSTRAP = "1";
        };
      }
    );
}

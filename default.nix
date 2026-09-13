let
  pkgs = import <nixpkgs> { };
in
pkgs.callPackage ./package.nix {
  avrGcc = pkgs.pkgsCross.avr.buildPackages.gcc;
  rustPlatform = pkgs.callPackage ./rustplatform-with-src.nix { };
}

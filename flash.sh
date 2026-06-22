#!/usr/bin/env bash

set -Eeuf -o pipefail
set -x

main() {
  nix develop --command cargo run --release

  # alternative if using external cargo toolchain
  # nix develop .#ravedude --command cargo run --release
}
main "$@"

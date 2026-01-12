#!/usr/bin/env bash

set -Eeuf -o pipefail
set -x

main() {
  nix develop --command cargo run --releasenixos
}
main "$@"

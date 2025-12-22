#!/usr/bin/env bash

set -Eeuf -o pipefail
set -x

main() {
  nix develop --command cargo build --release
  nix develop --command \
    avrdude \
    --programmer usbasp \
    --part attiny85 \
    --erase \
    --memory flash:w:target/avr-none/release/relay.elf:e
}
main "$@"

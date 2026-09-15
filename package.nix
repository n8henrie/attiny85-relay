{
  lib,
  rustPlatform,
  avrGcc,
}:
let
  inherit ((lib.importTOML ./Cargo.toml).package) name version description;
in
rustPlatform.buildRustPackage {
  pname = name;
  inherit version;
  src = lib.cleanSource ./.;

  env.RUSTC_BOOTSTRAP = "1";

  nativeBuildInputs = [ avrGcc ];
  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes."attiny-hal-0.1.0" = "sha256-dT4ClJC2eysro92JSuLVGRINGzgkxKZQjBad/UxVDd0=";
  };

  doCheck = false;
  # The installed artifact is AVR firmware, not a host executable.
  dontFixup = true;
  auditable = false;

  buildPhase = ''
    runHook preBuild

    cargo build --release \
      --target avr-none \
      --frozen \
      -Zbuild-std=core \
      --jobs "$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755  "target/avr-none/release/${name}.elf" "$out/bin/${name}.elf"

    runHook postInstall
  '';

  meta = {
    inherit description;
    mainProgram = "relay.elf";
    license = lib.licenses.mit;
  };
}

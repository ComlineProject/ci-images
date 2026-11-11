#!/bin/sh
# rustup.sh TOOLCHAIN LINK [OPTION...]: install rustup from /dl/rustup-init
# (already hash-checked), then TOOLCHAIN (minimal profile, plus the OPTIONs,
# e.g. -t wasm32-unknown-unknown), make it the default, and link LINK-<triple>
# to it, so `stable` / `nightly` name the pinned toolchain without a download.
# Everything under RUSTUP_HOME and CARGO_HOME is made open to every uid, in
# this one step so it adds no second copy of the files to the image.
set -eu
. /arch.sh
toolchain=$1 link=$2
shift 2
cp /dl/rustup-init /tmp/rustup-init
chmod +x /tmp/rustup-init
/tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain none
rm /tmp/rustup-init
rustup set profile minimal
rustup set auto-self-update disable
rustup toolchain install "$toolchain" --profile minimal "$@"
rustup default "$toolchain"
ln -s "${toolchain}-${gnu}" "$RUSTUP_HOME/toolchains/${link}-${gnu}"
chmod -R a+rwX "$RUSTUP_HOME" "$CARGO_HOME"

#!/usr/bin/env bash
# Smoke test for the ci-rust image: run inside it, with no network. Prints each
# tool's version and fails if one is missing or does not work.
#   docker run --rm --network none -v "$PWD/rust/smoke.sh:/smoke.sh:ro" IMAGE bash /smoke.sh
set -euo pipefail

run() { echo "+ $*"; "$@"; }
check() { echo "+ $*"; if ! "$@"; then echo "FAILED: $*" >&2; exit 1; fi; }

echo "== Rust"
check rustc --version
[[ "$(rustc --version)" == "rustc $CI_RUST_STABLE "* ]] || { echo "default rustc is not $CI_RUST_STABLE" >&2; exit 1; }
run rustc +stable --version
run cargo --version
run cargo clippy --version
run cargo fmt --version
run rustc "+$CI_RUST_NIGHTLY" --version
run rustc +nightly --version
run cargo +nightly clippy --version
run cargo +nightly fmt --version
run cargo "+$CI_RUST_NIGHTLY" miri --version
run cargo "+$CI_RUST_NIGHTLY" fuzz --version
run rustup show
for t in wasm32-unknown-unknown wasm32-wasip1 "$(uname -m)-unknown-linux-musl"; do
  rustup target list --installed | grep -qx "$t" || { echo "target $t missing" >&2; exit 1; }
done
sysroot=$(rustc --print sysroot)
check test -x "$sysroot/lib/rustlib/$(rustc -vV | sed -n 's/^host: //p')/bin/llvm-profdata"
check test -d "$(rustc +nightly --print sysroot)/lib/rustlib/src/rust/library"

echo "== Tools"
run valgrind --version
[[ "$(valgrind --version)" == valgrind-3.22.* ]] || { echo "valgrind is not 3.22" >&2; exit 1; }
# The runner has no --version: with none it fails, but names its own.
echo "+ iai-callgrind-runner --version"
iai=$(iai-callgrind-runner --version 2>&1 || true)
echo "$iai"
[[ "$iai" == *"iai-callgrind-runner (0.16.1)"* ]] || { echo "iai-callgrind-runner is not 0.16.1" >&2; exit 1; }
run cue version
run wasm-bindgen --version
run wasm-pack --version
run wasm-opt --version
run cbindgen --version
run gh --version
run jq --version
run python3 --version
run git --version
run make --version
run cc --version
run pkg-config --version
run musl-gcc --version
run xz --version
run unzip -v
run zstd --version

echo "== Builds"
work=$(mktemp -d)
cd "$work"
run cargo new --quiet --vcs none hello
cd hello
for t in "" wasm32-unknown-unknown wasm32-wasip1 "$(uname -m)-unknown-linux-musl"; do
  run cargo build --quiet ${t:+--target "$t"}
done
run valgrind --tool=callgrind --callgrind-out-file="$work/callgrind.out" target/debug/hello
echo "smoke test passed"

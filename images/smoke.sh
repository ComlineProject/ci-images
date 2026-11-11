#!/usr/bin/env bash
# Smoke test for the CI images: run inside one, with no network. Prints each
# tool's version and fails if one is missing or does not work.
#   docker run --rm --network none -v "$PWD/images/smoke.sh:/smoke.sh:ro" IMAGE bash /smoke.sh bench|fuzz|wasm|tools
set -euo pipefail

mode=${1:?usage: smoke.sh bench|fuzz|wasm|tools}
host=$(uname -m)-unknown-linux-gnu
musl=$(uname -m)-unknown-linux-musl

run() { echo "+ $*"; "$@"; }
fail() { echo "FAILED: $*" >&2; exit 1; }
installed_target() { rustup target list --installed | grep -qx "$1" || fail "target $1 missing"; }
absent() { for c in "$@"; do ! command -v "$c" > /dev/null || fail "$c is in this image, and should not be"; done; }

# A hello world, built for each target given ("" is the host).
builds() {
  local t
  hello=$(mktemp -d)/hello
  run cargo new --quiet --vcs none "$hello"
  cd "$hello"
  for t in "$@"; do
    run cargo build --quiet ${t:+--target "$t"}
  done
  cd /
}

echo "== Base"
run git --version
run zstd --version
run cc --version
test -s /etc/ssl/certs/ca-certificates.crt || fail "no CA certificates"
# The apt sources are the dated snapshot, not today's archive.
grep -q '^URIs: mirror+file:' /etc/apt/sources.list.d/debian.sources || fail "apt is not pointed at the snapshot"
grep -q 'snapshot.debian.org/archive/debian/[0-9]\{8\}T[0-9]\{6\}Z/' /etc/apt/mirrors/debian.txt || fail "no snapshot date in the apt mirrors"
cat /etc/apt/mirrors/debian.txt
run rustup show

case "$mode" in
bench)
  echo "== bench"
  [[ "$(rustc --version)" == "rustc $CI_RUST_STABLE "* ]] || fail "default rustc is not $CI_RUST_STABLE"
  run rustc +stable --version
  run cargo --version
  run valgrind --version
  # The runner has no --version: with none it fails, but names its own.
  echo "+ iai-callgrind-runner --version"
  iai=$(iai-callgrind-runner --version 2>&1 || true)
  echo "$iai"
  [[ "$iai" == *"iai-callgrind-runner (0.16.1)"* ]] || fail "iai-callgrind-runner is not 0.16.1"
  run gh --version
  run python3 --version
  absent wasm-pack cargo-fuzz cue cbindgen
  builds ""
  run valgrind --tool=callgrind --callgrind-out-file="$hello/callgrind.out" "$hello/target/debug/hello"
  ;;
fuzz)
  echo "== fuzz"
  [[ "$(rustc --version)" == *-nightly* ]] || fail "default rustc is not a nightly"
  run rustc "+$CI_RUST_NIGHTLY" --version
  run rustc +nightly --version
  run cargo "+$CI_RUST_NIGHTLY" fuzz --version
  run cargo fuzz --version
  run gh --version
  run python3 --version
  absent valgrind wasm-pack cue cbindgen
  # What cargo-fuzz asks of the compiler: a sanitizer runtime in the toolchain.
  work=$(mktemp -d); cd "$work"
  run cargo new --quiet --vcs none hello
  cd hello
  RUSTFLAGS="-Zsanitizer=address" run cargo build --quiet --target "$host"
  ;;
wasm)
  echo "== wasm"
  [[ "$(rustc --version)" == "rustc $CI_RUST_STABLE "* ]] || fail "default rustc is not $CI_RUST_STABLE"
  installed_target wasm32-unknown-unknown
  installed_target wasm32-wasip1
  run wasm-bindgen --version
  run wasm-pack --version
  run wasm-opt --version
  command -v wasm-bindgen-test-runner wasm2es6js
  run jq --version
  absent valgrind cargo-fuzz cue cbindgen gh
  builds "" wasm32-unknown-unknown wasm32-wasip1
  ;;
tools)
  echo "== tools"
  [[ "$(rustc --version)" == "rustc $CI_RUST_STABLE "* ]] || fail "default rustc is not $CI_RUST_STABLE"
  installed_target "$musl"
  run cue version
  run cbindgen --version
  run musl-gcc --version
  run make --version
  run jq --version
  absent valgrind cargo-fuzz wasm-pack gh
  builds "" "$musl"
  ;;
*)
  fail "unknown mode: $mode"
  ;;
esac
echo "smoke test passed ($mode)"

# ci-rust: what is in the image, and why that version

Every version is an `ARG` at the top of [`Dockerfile`](Dockerfile). A downloaded
binary is checked against a SHA-256 hash, per architecture, kept beside its
version; bump the version and both hashes together. Surveyed from the
workflows of core, runtime, comline-typescript, simulator, playground and
specification.

## Rust

| Tool | Version | Why |
|---|---|---|
| rustup | 1.29.3 | Current. `rustup-init` is checked against its published hash. |
| stable toolchain | 1.99.1 | Current stable when the image was built (2026-11-12). The default toolchain, also reachable as `stable`. Components `clippy`, `rustfmt`, `llvm-tools-preview`; targets `wasm32-unknown-unknown`, `wasm32-wasip1`, and `x86_64-unknown-linux-musl` (`aarch64-unknown-linux-musl` on arm64). runtime's `rust-toolchain.toml` pins 1.98.0 and core's says `stable`: bump runtime's to match, or it downloads 1.98.0 at job time. |
| nightly toolchain | nightly-2026-11-10 | cargo-fuzz and miri need nightly (core and runtime `fuzz.yml`, runtime's `ffi_miri` job). Dated, so the image does not move under the jobs; also reachable as `nightly`. Components `clippy`, `rustfmt`, `llvm-tools-preview`, `rust-src`, `miri`. |
| beta | not included | The `beta` leg of core's and runtime's toolchain matrix is a moving channel; it is installed by the job (`rustup toolchain install beta --profile minimal`). |
| 1.82.0 | not included | specification's clippy MSRV check installs it by the job. |

## Tools

| Tool | Version | Source | Why |
|---|---|---|---|
| iai-callgrind-runner | 0.16.1 | release binary | Must equal the `iai-callgrind` library: `=0.16.1` in core's `core/Cargo.toml` and runtime's `runtime/core/Cargo.toml`, `runtime/ffi/bench/Cargo.toml`, and 0.16.1 in runtime's `Cargo.lock` (core's `Cargo.lock` is not committed). Core and runtime agree. Both bench workflows set `IAI_CALLGRIND_RUNNER_VERSION: 0.16.1`. |
| valgrind | Ubuntu 24.04's, 3.22.0 | apt | Kept at 3.22 so instruction-count baselines stay comparable with the hosted `ubuntu-24.04` runner. The smoke test fails if it is not 3.22. `libc6-dbg` comes with it. |
| cargo-fuzz | 0.13.2 | `cargo install --locked` | `CARGO_FUZZ_VERSION` in core's and runtime's `fuzz.yml`. Only an amd64 binary is released, so it is built for both architectures. |
| cbindgen | 0.29.2 | `cargo install --locked` | `CBINDGEN_VERSION` in runtime's `build_test.yml`, and `runtime/ffi/cbindgen.toml`: `comline.h` is generated with exactly this one. No release binaries. |
| wasm-bindgen-cli | 0.2.127 | release binary (musl) | Must equal `wasm-bindgen` in simulator's `Cargo.lock` (0.2.127). playground has no `Cargo.lock` (`wasm-bindgen = "0.2"` in `wasm/Cargo.toml`), and builds the simulator at the commit its `app/yarn.lock` pins; wasm-pack fetches its own matching wasm-bindgen if the one on `PATH` differs. Bump with simulator's lockfile. |
| wasm-pack | 0.15.1 | release binary (musl) | Current. playground's `deploy.yml` installs the latest at job time. |
| cue | v0.17.1 | release binary | `CUE_VERSION` in runtime's `build_test.yml` and specification's `check.yml`; runtime's `conformance/spec/cue.mod/module.cue` is kept in step with it. |
| binaryen (`wasm-opt`) | Ubuntu 24.04's (version 108) | apt | simulator's `ci.yml` and `reports.yml`, playground's `deploy.yml`. |
| musl-tools (`musl-gcc`) | Ubuntu 24.04's | apt | For the musl target. |
| gh | 2.103.3 | release binary | The fuzz, nightly and CI workflows use `gh issue` and `gh api`, which a job container does not have. |
| python3 | Ubuntu 24.04's | apt | `.github/scripts/bench-report.py` in the bench workflows. |
| git, curl, ca-certificates, jq, make, xz-utils, unzip, zstd, pkg-config, build-essential | Ubuntu 24.04's | apt | Checkout, the build, simulator's wasm-bindgen version check (`jq`), `actions/cache` (`zstd`). |

Not in the image: Node. GitHub mounts its own into a job container for actions;
a job that runs `node` in a step uses `actions/setup-node`.

## Base

| | Version | Why |
|---|---|---|
| ubuntu | 24.04 at `sha256:fe81560990fa...` | The multi-arch index digest, matching the hosted runners' release. Renovate bumps it. |

## Size

About 2.9 GB uncompressed on amd64 and 2.5 GB on arm64 (the two toolchains with
their components and targets are most of it). A job pulls the compressed
layers once per runner.

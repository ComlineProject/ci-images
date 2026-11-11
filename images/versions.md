# The CI images: what is in each, and why that version

Every version is an `ARG` at the top of [`Dockerfile`](Dockerfile). A downloaded
binary is checked against a SHA-256 hash, per architecture, kept beside its
version; bump the version and both hashes together. Surveyed from the
workflows of core, runtime, comline-typescript, simulator, playground and
specification. Why Debian: [`../docs/base-choice.md`](../docs/base-choice.md).

| Image | Jobs | Rust | Also in it |
|---|---|---|---|
| `ci-bench` | the instruction-count benchmarks (core, runtime) | stable 1.99.1, minimal | valgrind, iai-callgrind-runner 0.16.1, python3, gh |
| `ci-fuzz` | the cargo-fuzz jobs (core, runtime) | nightly-2026-11-10, minimal | cargo-fuzz 0.13.2, gh |
| `ci-wasm` | the WebAssembly build (simulator, playground), core's `ir_only` job | stable 1.99.1, minimal, `wasm32-unknown-unknown`, `wasm32-wasip1` | wasm-bindgen 0.2.127, wasm-pack 0.15.1, binaryen, jq |
| `ci-tools` | cue, cbindgen and the musl build (runtime, specification) | stable 1.99.1, minimal, the musl target | cue v0.17.1, cbindgen 0.29.2, musl-tools, make, jq |

All four have, from the base: git, ca-certificates, zstd (for `actions/cache`),
and `build-essential` (rustc links with `cc`).

## Base

| | Version | Why |
|---|---|---|
| debian trixie-slim | `sha256:a72b4433de1c...` | Debian 13, the stable release; the multi-arch index digest. Renovate bumps it. |
| apt snapshot | `20261112T000000Z` | `DEBIAN_SNAPSHOT` in the Dockerfile: the one date every apt package is pinned to (snapshot.debian.org, which also serves `trixie-updates` and `trixie-security` for that timestamp). A rebuild gives the same package set. Bump it together with the base digest, never to a date before the base image's. The snapshot is tried on snapshot.debian.org, then its CDN snapshot-cloudflare.debian.org (identical content). There is no deb.debian.org fallback: it holds today's archive, not the snapshot's. |

On that date the apt packages are Debian's: valgrind 3.24.0, glibc 2.41,
python3 3.13.5, git 2.47.3. The smoke test prints the rest.

## Rust

| Tool | Version | Why |
|---|---|---|
| rustup | 1.29.3 | Current. `rustup-init` is checked against its published hash. |
| stable toolchain | 1.99.1 | Current stable when the images were built (2026-11-12). Default toolchain, also reachable as `stable`, in `ci-bench`, `ci-wasm`, `ci-tools`. No components: `clippy`, `rustfmt`, `llvm-tools-preview` are not in these images (a job that needs one runs `rustup component add`, or a `rust-toolchain.toml` that names it does). runtime's `rust-toolchain.toml` pins 1.98.0 and core's says `stable`: bump runtime's to match, or it downloads 1.98.0 at job time. |
| nightly toolchain | nightly-2026-11-10 | cargo-fuzz needs nightly (core and runtime `fuzz.yml`). Dated, so the image does not move under the jobs; default in `ci-fuzz`, also reachable as `nightly`. No components: `cargo fuzz build` and `run` need only the sanitizer runtime that comes with the toolchain's `rust-std`, not `rust-src` or `llvm-tools-preview` (those are for `cargo fuzz coverage` and `--build-std`). `stable` is not in `ci-fuzz`. |
| beta, 1.82.0, miri | not included | Moving or one-off toolchains (the `beta` leg of the toolchain matrix, specification's MSRV check, runtime's `ffi_miri` job) are installed by the job: `rustup toolchain install beta --profile minimal`. |
| targets | `wasm32-unknown-unknown` and `wasm32-wasip1` in `ci-wasm`; `x86_64-unknown-linux-musl` (`aarch64-...` on arm64) in `ci-tools` | `wasm32-unknown-unknown` is the browser build (simulator, playground). `wasm32-wasip1` is for core's `ir_only` job (`build_test.yml`), which runs `cargo build -p comline-core --no-default-features --target wasm32-wasip1` (and the same for `wasm32-unknown-unknown`): the IR without a parser must compile for WASI. Both are `rust-std` only, no runtime (wasmtime, wasmer) is in the image, so it builds for WASI but cannot run the result. |

## Tools

| Tool | Image | Version | Source | Why |
|---|---|---|---|---|
| iai-callgrind-runner | bench | 0.16.1 | release binary | Must equal the `iai-callgrind` library: `=0.16.1` in core's `core/Cargo.toml` and runtime's `runtime/core/Cargo.toml`, `runtime/ffi/bench/Cargo.toml`, and 0.16.1 in runtime's `Cargo.lock`. Both bench workflows set `IAI_CALLGRIND_RUNNER_VERSION: 0.16.1`. |
| valgrind | bench | Debian's, 3.24.0 | apt (snapshot) | Ubuntu 24.04's was 3.22, so instruction counts differ from the hosted runners' by up to 0.44% (see base-choice.md): the baselines are re-recorded on this image. Needs a container started with `--security-opt seccomp=unconfined`. |
| python3 | bench | Debian's | apt (snapshot) | `.github/scripts/bench-report.py` in the bench workflows. |
| cargo-fuzz | fuzz | 0.13.2 | `cargo install --locked` | `CARGO_FUZZ_VERSION` in core's and runtime's `fuzz.yml`. Only an amd64 binary is released, so it is built for both architectures. |
| cbindgen | tools | 0.29.2 | `cargo install --locked` | `CBINDGEN_VERSION` in runtime's `build_test.yml`, and `runtime/ffi/cbindgen.toml`: `comline.h` is generated with exactly this one. No release binaries. |
| cue | tools | v0.17.1 | release binary | `CUE_VERSION` in runtime's `build_test.yml` and specification's `check.yml`; runtime's `conformance/spec/cue.mod/module.cue` is kept in step with it. |
| musl-tools (`musl-gcc`), make, jq | tools | Debian's | apt (snapshot) | The musl target; the generated-code Makefiles; JSON in the checks. |
| wasm-bindgen-cli | wasm | 0.2.127 | release binary (musl) | Must equal `wasm-bindgen` in simulator's `Cargo.lock` (0.2.127). playground has no `Cargo.lock` (`wasm-bindgen = "0.2"` in `wasm/Cargo.toml`), and builds the simulator at the commit its `app/yarn.lock` pins; wasm-pack fetches its own matching wasm-bindgen if the one on `PATH` differs. Bump with simulator's lockfile. |
| wasm-pack | wasm | 0.15.1 | release binary (musl) | Current. playground's `deploy.yml` installs the latest at job time. |
| binaryen (`wasm-opt`) | wasm | Debian's (the snapshot's) | apt (snapshot) | simulator's `ci.yml` and `reports.yml`, playground's `deploy.yml`. Ubuntu 24.04's was version 108; Debian trixie's is newer. |
| jq | wasm | Debian's | apt (snapshot) | simulator's wasm-bindgen version check. |
| gh | bench, fuzz | 2.103.3 | release binary | The fuzz, nightly and CI workflows use `gh issue` and `gh api`, which a job container does not have. |

Not in any image: Node (GitHub mounts its own into a job container for
actions; a job that runs `node` in a step uses `actions/setup-node`), curl and
unzip (only a build stage has curl), `pkg-config`, xz-utils.

## Size

From the first build (pull request #3, `Image size` step of each build job). The
compressed size is the sum of the image's layers as `docker buildx` exports
them (gzip), which is what a pull transfers; the `merge and attest` job of a
publish run prints the registry's own figure.

| Image | amd64 compressed | amd64 uncompressed | arm64 compressed | arm64 uncompressed |
|---|---:|---:|---:|---:|
| `ci-bench` | 449.7 MB | 1260 MB | 389.7 MB | 1129 MB |
| `ci-fuzz` | 402.6 MB | 1115 MB | 359.0 MB | 1020 MB |
| `ci-wasm` | 442.5 MB | 1253 MB | 400.1 MB | 1161 MB |
| `ci-tools` | 467.5 MB | 1354 MB | 402.3 MB | 1183 MB |

(For comparison, the ci-rust image was about 2.9 GB uncompressed on amd64.)

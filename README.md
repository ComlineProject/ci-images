# ci-images

Pinned container images for ComlineProject's CI. Workflows run their jobs in an
image from here (`container:`) instead of installing tools on a floating
`ubuntu-latest` runner at run time, so a mirror outage or a new tool release
cannot break a job that did not change.

One image per kind of job, each carrying only what those jobs use:

| Image | For | Has |
|---|---|---|
| `ghcr.io/comlineproject/ci-bench` | the instruction-count benchmarks | Rust stable, valgrind, iai-callgrind-runner, python3, gh |
| `ghcr.io/comlineproject/ci-fuzz` | the cargo-fuzz jobs | Rust nightly, cargo-fuzz, gh |
| `ghcr.io/comlineproject/ci-wasm` | the WebAssembly build | Rust stable with wasm32, wasm-bindgen, wasm-pack, binaryen |
| `ghcr.io/comlineproject/ci-tools` | cue, cbindgen and the musl build | Rust stable with musl, cue, cbindgen, musl-tools, make, jq |

All are Debian 13 (trixie) slim, by digest, with every apt package pinned to
one snapshot.debian.org date, for `linux/amd64` and `linux/arm64`. They all
have git and a C toolchain. [`images/versions.md`](images/versions.md) lists
every version and why it is that one; [`docs/base-choice.md`](docs/base-choice.md)
says why Debian.

## Use it

Pin the image by digest, never by tag. The digest of each build is in its
[workflow run](../../actions/workflows/build.yml)'s summary. The builds are
reproducible ([`images/versions.md`](images/versions.md#reproducible-builds)): a
digest changes only when an input of the image does.

```yaml
jobs:
  test:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/comlineproject/ci-tools@sha256:<digest>
    steps:
      - uses: actions/checkout@...
      - run: cargo build
```

The bench job's container needs `--security-opt seccomp=unconfined`:
iai-callgrind's runner switches ASLR off with `setarch -R`, which Docker's
default seccomp profile refuses.

```yaml
    container:
      image: ghcr.io/comlineproject/ci-bench@sha256:<digest>
      options: --security-opt seccomp=unconfined
```

Renovate bumps the digest: the tags (`latest`, `sha-<short>`) exist for it to
follow. A bump is a pull request in the consuming repository, so it runs that
repository's CI against the new image before it merges.

Notes for jobs in the container:

- `stable` (or `nightly`, in `ci-fuzz`) names the pinned toolchain, so a
  `rust-toolchain.toml` with `channel = "stable"` and `cargo +nightly fuzz` need
  no download. `$CI_RUST_STABLE` or `$CI_RUST_NIGHTLY` holds its exact name. Do
  not run `rustup update`.
- The toolchains are minimal: no `clippy`, `rustfmt` or `llvm-tools-preview`.
  A toolchain or component not in the image (`beta`, miri, a version a
  `rust-toolchain.toml` pins that the image does not have) is installed by the
  job. `CARGO_HOME` and `RUSTUP_HOME` (`/usr/local/cargo`, `/usr/local/rustup`)
  are writable by any uid.
- Node is not in the images; use `actions/setup-node`.

## Verify where it came from

Each published digest has a build provenance attestation:

```sh
gh attestation verify oci://ghcr.io/comlineproject/ci-bench@sha256:<digest> --owner ComlineProject
```

## How it is built

[`images/Dockerfile`](images/Dockerfile) is one file with a `base` stage and a
build target per image (`docker build --target bench images`).
[`build.yml`](.github/workflows/build.yml) builds the four images for both
architectures natively (`ubuntu-24.04` and `ubuntu-24.04-arm`). Every build
smoke-tests the image ([`images/smoke.sh`](images/smoke.sh), one mode per image:
each tool's version, a build for each target, with no network, as root and as
another uid), prints its compressed size, and `ci-bench` runs core's bench at a
fixed commit. Pull requests stop there. Pushes to `main` and manual runs on
`main` push each architecture by digest, smoke-test what was pushed, join the
two into one manifest tagged `sha-<short>` and `latest`, attest it, and run
core's bench in the published `ci-bench` as a real `container:` job.

There is no scheduled rebuild: the apt packages are fixed by date, so a rebuild
would change nothing. To update them, move `DEBIAN_SNAPSHOT` (and the base
digest) in the Dockerfile. To update a tool, change the `ARG` and its hashes in
[`images/Dockerfile`](images/Dockerfile), and its row in
[`images/versions.md`](images/versions.md).

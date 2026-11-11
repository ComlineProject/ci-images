# ci-images

Pinned container images for ComlineProject's CI. Workflows run their jobs in an
image from here (`container:`) instead of installing tools on a floating
`ubuntu-latest` runner at run time, so a mirror outage or a new tool release
cannot break a job that did not change.

| Image | Directory | Purpose |
|---|---|---|
| `ghcr.io/comlineproject/ci-rust` | [`rust/`](rust/) | Rust toolchains and the tools the Rust repositories' CI uses |

## ci-rust

Ubuntu 24.04 with Rust (an exact stable and a dated nightly, with the wasm and
musl targets), valgrind, `iai-callgrind-runner`, `cargo-fuzz`, `cbindgen`,
`wasm-bindgen`, `wasm-pack`, `wasm-opt`, `cue`, `gh` and `python3`.
[`rust/versions.md`](rust/versions.md) lists every version and why it is that
one. For `linux/amd64` and `linux/arm64`.

### Use it

Pin the image by digest, never by tag. The digest of each build is in its
[workflow run](../../actions/workflows/build.yml)'s summary.

```yaml
jobs:
  test:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/comlineproject/ci-rust@sha256:<digest>
    steps:
      - uses: actions/checkout@...
      - run: cargo test
```

Renovate bumps the digest: the tags (`latest`, `sha-<short>`) exist for it to
follow, and the weekly rebuild picks up Ubuntu's package updates. A bump is a
pull request in the consuming repository, so it runs that repository's CI
against the new image before it merges.

Notes for jobs in the container:

- `stable` and `nightly` name the pinned toolchains, so a
  `rust-toolchain.toml` with `channel = "stable"`, `RUSTUP_TOOLCHAIN=nightly` and
  `cargo +nightly fuzz` need no download. `$CI_RUST_STABLE` and
  `$CI_RUST_NIGHTLY` hold their exact names. Do not run `rustup update`.
- A toolchain not in the image (`beta`, or a version a `rust-toolchain.toml`
  pins that the image does not have) is installed by the job. `CARGO_HOME` and
  `RUSTUP_HOME` (`/usr/local/cargo`, `/usr/local/rustup`) are writable by any uid.
- Node is not in the image; use `actions/setup-node`.

### Verify where it came from

Each published digest has a build provenance attestation:

```sh
gh attestation verify oci://ghcr.io/comlineproject/ci-rust@sha256:<digest> --owner ComlineProject
```

### How it is built

[`build.yml`](.github/workflows/build.yml) builds both architectures natively
(`ubuntu-24.04` and `ubuntu-24.04-arm`). Every build smoke-tests the image
([`rust/smoke.sh`](rust/smoke.sh): each tool's version, a build for each
target, callgrind, with no network, as root and as another uid). Pull requests
stop there. Pushes to `main`, a weekly schedule and manual runs push each
architecture by digest, smoke-test what was pushed, join the two into one
manifest tagged `sha-<short>` and `latest`, and attest it.

Updating a version: change the `ARG` and its hashes in
[`rust/Dockerfile`](rust/Dockerfile), and its row in
[`rust/versions.md`](rust/versions.md).

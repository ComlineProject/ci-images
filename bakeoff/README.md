# Base-image bake-off

Is a different base faster or smaller than Ubuntu 24.04 for the bench image?
Four variants with the same tools, measured on GitHub-hosted runners (nothing
is built or measured locally). [`RESULTS.md`](RESULTS.md) holds the numbers of
the last run; the workflow is
[`bakeoff.yml`](../.github/workflows/bakeoff.yml).

## The variants

| Variant | Base, by multi-arch index digest | Packages |
|---|---|---|
| [`ubuntu`](ubuntu/Dockerfile) | `ubuntu:24.04@sha256:fe8156...` (what `ci-rust` uses) | apt |
| [`debian`](debian/Dockerfile) | `debian:trixie-slim@sha256:a72b44...` | apt |
| [`wolfi`](wolfi/Dockerfile) | `cgr.dev/chainguard/wolfi-base@sha256:94fa13...` (`latest` on 2026-11-12) | apk (Wolfi, glibc) |
| [`nix`](nix/flake.nix) | no base image: the image is only the closure of its packages (`nixos-26.05`, pinned in [`flake.lock`](nix/flake.lock)) | Nix (nixpkgs; Rust from rust-overlay) |

Each Dockerfile variant has: Rust stable 1.99.1, minimal profile, no extra components, no nightly
(rustup 1.29.3, hash-checked, as in `rust/Dockerfile`; `stable` is linked to it
so core's `rust-toolchain.toml` needs no download); `valgrind`; `iai-callgrind-runner`
0.16.1 (the release binary, hash-checked); `python3`; `git`; `gh` 2.103.3
(the release binary, hash-checked; on Wolfi, Wolfi's own package of the same
version); `ca-certificates`; `setarch` (Wolfi only, see below); a C toolchain (`build-essential`, or `build-base`);
`zstd`. Not in them: curl (a build stage downloads, only the files leave it),
`jq`, `make` beyond the C toolchain, musl, wasm tools, nightly, cargo-fuzz,
cbindgen, cue. amd64 only. Each Dockerfile ends with a smoke `RUN`
(`valgrind --version`, `iai-callgrind-runner --version`, `cargo --version`,
`gh --version`, and a few more).

### The nix variant

[`nix/flake.nix`](nix/flake.nix) and [`nix/flake.lock`](nix/flake.lock) (nixpkgs
`nixos-26.05`, `oxalica/rust-overlay` and `nlewo/nix2container`, each locked by rev
and narHash; the lock was generated in Actions, nothing is built locally).
It has the same tools: Rust 1.99.1, minimal profile (rust-overlay, no rustup:
`cargo` and `rustc` are the toolchain, so `rust-toolchain.toml` is not
consulted), `valgrind`, `python3`, `git`, `gh`, `cc` (nixpkgs' gcc wrapper),
`make`, `zstd`, `setarch` (util-linux), `ca-certificates`, glibc. The versions
are nixpkgs' (`RESULTS.md` has them), not the Dockerfile variants' pins;
`iai-callgrind-runner` 0.16.1 is built from the crates.io source with
`rustPlatform.buildRustPackage` (nixpkgs does not package it; the source hash
and the vendored-dependencies hash are in the flake). Beyond the others' tool
set it has a shell and the usual text tools (`bash`, coreutils, `tar`, `gzip`,
grep, sed, awk, find), which a job container needs.

The image is built with `nix2container` (layers are streamed, no tarball in the
store; up to 100 layers, one per popular store path) and pushed with its skopeo.
As a job container it has `/bin/sh`, `/usr/bin/env`, `PATH`, `SSL_CERT_FILE`,
a world-writable `/tmp`, `HOME=/home/ci` and `CARGO_HOME=/cargo`, and
`/lib64/ld-linux-x86-64.so.2` provided by [nix-ld](https://github.com/nix-community/nix-ld)
(`NIX_LD` is Nix's glibc, `NIX_LD_LIBRARY_PATH` has libstdc++ and libgcc_s), so GitHub's
mounted node, a plain glibc binary that wants a libstdc++ the image does not otherwise put on
a search path, can run (the `container-smoke` job runs the image as a real `container:` job;
programs built by Nix do not go through nix-ld, so the bench is unaffected). `/lib64/libc.so.6`
is there for `envinfo.sh`, which reports the glibc version the same way as in
the others. `nix develop` in `bakeoff/nix` gives the same tools locally.

- **Build time** is `nix build .#bench-image` alone, on a fresh runner with an
  empty Nix store and no build cache of ours (no `magic-nix-cache`, no
  `actions/cache`). Nix still substitutes the packages nixpkgs publishes from
  `cache.nixos.org`; only the iai-callgrind-runner (a cargo build), the layer
  metadata and the image are built on the runner. The tool that pushes
  (`skopeo-nix2container`) is built apart and timed apart, as `docker push` is
  not in the Dockerfile builds' time. `RESULTS.md` quotes Nix's own "will be
  built / will be fetched" line.
- **Reproducibility.** `nix-store --realise --check` builds each derivation that
  the runner builds (the layer metadata, the image's JSON, the environment, the
  skeleton, the iai-callgrind-runner) again and fails if the output differs. The
  image is exported (`skopeo copy` to a directory, layers compressed) before and
  after, and the two manifest digests and layer digests are compared. Only the
  Nix-built parts can be rebuilt here: the packages substituted from
  `cache.nixos.org` are trusted as built there. The Dockerfile variants were
  not checked (they pull packages and write timestamps, so they are not expected
  to be bit-identical).
- **CVEs.** Trivy runs on the image as on the others, but it reads package
  databases (dpkg, apk) and language lockfiles, not Nix store paths, so its result
  is recorded and marked not meaningful. The number that counts is
  [`vulnix`](https://github.com/nix-community/vulnix) over the runtime closure of
  the image's environment: one finding per (package, CVE) pair, HIGH+CRITICAL being
  CVSS v3 >= 7.0. vulnix matches package names and versions against the NVD, so it
  has no fix information and its numbers are not comparable with Trivy's
  distribution advisories; both over- and under-report.

Wolfi's packages are a rolling repository: the base digest pins the base image,
but rebuilding the Dockerfile later floats to the packages of that day. The
versions of the ones that matter are in `RESULTS.md`. Each needed package
(`valgrind`, `python3`, `git`, `gh`, `build-base`, `glibc`, `zstd`) exists in
Wolfi.

## What is measured

- **Sizes.** Uncompressed: `docker image inspect` `.Size` before the push.
  Compressed: the sum of the layer sizes in the pushed image manifest
  (`docker buildx imagetools inspect --raw`). Build time: the
  `docker/build-push-action` step alone, with no layer cache, on a fresh runner.
- **Pull time.** Each `measure` leg runs on its own fresh runner, so nothing is
  cached. The pull is its own step, `docker pull <image>@<digest>`, timed with
  `date`; the bench then runs in `docker run` on the pulled image. That is why
  the legs do not use `container:`: with it the runner pulls the image in a
  setup step that cannot be timed apart from the job's setup. Because the
  bench runs in `docker run`, core is mounted at `/work` and the build and
  iai-callgrind's output go to `/tmp/target` and `/tmp/iai` in every variant,
  the VM leg too (bind mounts), so a bench binary's path, which can move
  counts, is the same everywhere.
- **Seccomp.** iai-callgrind's runner runs the bench under `setarch -R` (ASLR
  off). Docker's default seccomp profile refuses that `personality()` call, so
  the bench fails in a container ("setarch: failed to set personality ...:
  Operation not permitted"); `docker run` here uses
  `--security-opt seccomp=unconfined`, and a job with `container:` needs
  `options: --security-opt seccomp=unconfined` too. The first run of this workflow
  passed on wolfi without the flag, which suggests `wolfi-base` has no `setarch`
  and the runner then goes on with ASLR on, silently (inferred from the
  absence of the error, not confirmed). So the wolfi variant installs Wolfi's
  `setarch` package (on the other two it is util-linux's), and `RESULTS.md`
  shows the path of `setarch` in each environment.
- **Bench.** core at a fixed commit (`CORE_SHA` in the workflow). The command is
  the one of core's `bench.yml`, in its `master` job:
  `cargo bench -p comline-core --bench parser_instructions -- --save-summary=json`.
  It is run after `cargo bench ... --no-run`, so the compile (with the
  dependency downloads) and the run are timed apart. core commits no
  `Cargo.lock`; a `lock` job generates one for the fixed commit, which every
  leg uses, so no crate publish can move a count between legs.
  The counts are the `Ir` of every `summary.json` (the files are in each
  `measure-*` artifact).
- **Job time.** From the first step of the `measure` job (before the
  checkouts) to the end of the bench: checkouts, artifact downloads, login,
  pull or VM setup, compile and run. Not the runner's own start-up, and not the
  Trivy scan.
- **`vm`.** Today's setup: no container, `apt-get install valgrind` and
  `cargo install iai-callgrind-runner@0.16.1 --locked` on the runner. The
  runner's own preinstalled stable Rust runs the bench, so its `rustc` may differ
  from 1.99.1 (`RESULTS.md` says which). Its "pull time" column is that setup.
  The real workflow caches the runner binary between runs; this leg does not.
- **CVEs.** Trivy (`aquasecurity/trivy-action`) scans each pulled image once,
  all severities; HIGH and CRITICAL are counted, with and without a fix
  available. The Trivy database is that day's.
- **Runs.** 3 per variant, each on its own runner, started at the same time.

Instruction counts are compared per benchmark: across the 3 runs of one variant
(identical or not, and the largest relative difference), and against the ubuntu
variant's median (the largest relative difference).

## Caveats

amd64 only. Three runs per variant: medians of three are not a distribution.
GitHub-hosted runners are shared machines, and the registry's speed varies, so
pull and compile times carry runner noise; instruction counts do not. The
legs start together, so they compete for the same registry and mirrors. A
different base also means a different valgrind (and glibc) version, so a count
difference between variants is a difference in the bench's environment, not
only in the image.

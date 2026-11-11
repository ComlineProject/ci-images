# Base-image bake-off

Is a different base faster or smaller than Ubuntu 24.04 for the bench image?
Three variants with the same tools, measured on GitHub-hosted runners (nothing
is built or measured locally). [`RESULTS.md`](RESULTS.md) holds the numbers of
the last run; the workflow is
[`bakeoff.yml`](../.github/workflows/bakeoff.yml).

## The variants

| Variant | Base, by multi-arch index digest | Packages |
|---|---|---|
| [`ubuntu`](ubuntu/Dockerfile) | `ubuntu:24.04@sha256:fe8156...` (what `ci-rust` uses) | apt |
| [`debian`](debian/Dockerfile) | `debian:trixie-slim@sha256:a72b44...` | apt |
| [`wolfi`](wolfi/Dockerfile) | `cgr.dev/chainguard/wolfi-base@sha256:94fa13...` (`latest` on 2026-11-12) | apk (Wolfi, glibc) |

Each has: Rust stable 1.99.1, minimal profile, no extra components, no nightly
(rustup 1.29.3, hash-checked, as in `rust/Dockerfile`; `stable` is linked to it
so core's `rust-toolchain.toml` needs no download); `valgrind`; `iai-callgrind-runner`
0.16.1 (the release binary, hash-checked); `python3`; `git`; `gh` 2.103.3
(the release binary, hash-checked; on Wolfi, Wolfi's own package of the same
version); `ca-certificates`; a C toolchain (`build-essential`, or `build-base`);
`zstd`. Not in them: curl (a build stage downloads, only the files leave it),
`jq`, `make` beyond the C toolchain, musl, wasm tools, nightly, cargo-fuzz,
cbindgen, cue. amd64 only. Each Dockerfile ends with a smoke `RUN`
(`valgrind --version`, `iai-callgrind-runner --version`, `cargo --version`,
`gh --version`, and a few more).

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

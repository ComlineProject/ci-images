# syntax=docker/dockerfile:1
#
# The CI images of ComlineProject, one Dockerfile, one build target each:
#
#   bench  Rust stable, valgrind, iai-callgrind-runner, python3, gh
#   fuzz   Rust nightly, cargo-fuzz, gh
#   wasm   Rust stable + wasm32 (browser and WASI), wasm-bindgen, wasm-pack, binaryen
#   tools  Rust stable + musl, cue, cbindgen, musl-tools, make, jq
#
#   docker build --target bench images
#
# All four start from the `base` stage: Debian 13 (trixie) slim, by digest, with
# apt pointed at a dated snapshot of the archive. images/versions.md says what
# each version is for. Every downloaded binary is checked against the SHA-256
# hash below, per architecture, before it is used; a version bump changes the
# version and both hashes together.

# Debian 13 (trixie) slim, the multi-arch index digest.
ARG BASE_IMAGE=debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

# The one date every apt package is pinned to: a snapshot.debian.org timestamp
# (YYYYMMDDTHHMMSSZ). Keep it at or after the day of the base image above (the
# base's own packages must not be newer than the archive), and move it with
# the base. Changing it is how the packages are updated.
ARG DEBIAN_SNAPSHOT=20261112T000000Z

# Rust. Exact toolchains, never a moving channel. bench, wasm and tools use
# RUST_STABLE, fuzz uses RUST_NIGHTLY.
ARG RUST_STABLE=1.99.1
ARG RUST_NIGHTLY=nightly-2026-11-10
ARG RUSTUP_VERSION=1.29.3
ARG RUSTUP_SHA256_AMD64=b1c8cb14e30889e7e2999e6b69e62d9e9b9ffc0f4df8180564d306d9680e6c55
ARG RUSTUP_SHA256_ARM64=9f608c142e0e38a78957d0661ba1dfaf0b6fb37184cfaa4b9a0aa57af6184282

# Prebuilt tools.
ARG CUE_VERSION=v0.17.1
ARG CUE_SHA256_AMD64=a39b0c97695069d95d276d99be0f5dbabb081d801bfdc9ba49b76efaf94e2369
ARG CUE_SHA256_ARM64=0d729be30d52c952ca38fc9dcb692caa09d8463fa0b64df5781312779183fbcd
ARG WASM_PACK_VERSION=0.15.1
ARG WASM_PACK_SHA256_AMD64=410101009739b9d01c7d5affaaad6e9c9a24b4cba6791a4805db8e89b9bf7af2
ARG WASM_PACK_SHA256_ARM64=7004853c7925ae1984033b5f25866ec604bbc921ef956d5e6c5595bc5af6d30c
ARG WASM_BINDGEN_VERSION=0.2.127
ARG WASM_BINDGEN_SHA256_AMD64=61d4a7dc85acfa0d2354ccc0b8361928c7e52a746d17f28ebaa795ed3dc1614a
ARG WASM_BINDGEN_SHA256_ARM64=699ddbb724ece16f912b73a98b5341a75f4b8c7886ce152d40dbe09f694e46c7
ARG IAI_CALLGRIND_RUNNER_VERSION=0.16.1
ARG IAI_CALLGRIND_RUNNER_SHA256_AMD64=436feddb83ec916ddaf401dd1cea45aa329745067e8136a774b2fc581de6b448
ARG IAI_CALLGRIND_RUNNER_SHA256_ARM64=046c854014745a7d26ecc58cd8b8ca99ef39d856a3ab6b933f34503845d5bfe4
ARG GH_VERSION=2.103.3
ARG GH_SHA256_AMD64=4c806978ffce1cec70853302a56d70ac6da4f19bae7adca4e1a8ab00633dd91d
ARG GH_SHA256_ARM64=ee32df2323c8847f5fac6cb6b4b69ca75828e9329a8f22f677021f7b3306ce63

# Built from source (no prebuilt binary for both architectures), --locked.
ARG CARGO_FUZZ_VERSION=0.13.2
ARG CBINDGEN_VERSION=0.29.2


# ---------------------------------------------------------------------------
# base: Debian slim, apt on the snapshot, and what every image has (git for
# checkout, ca-certificates, zstd for actions/cache).
#
# The sources name the snapshot of ${DEBIAN_SNAPSHOT}, so every package is the
# one the archive held at that moment, whenever the image is built; the archive
# stops being a moving target. snapshot.debian.org has two hosts serving
# identical content (the second is its CDN): apt falls back to the second when
# the first cannot be reached, as ci-rust did between Ubuntu mirrors. There is
# no fallback to deb.debian.org on purpose: it holds today's archive, not the
# snapshot's, and apt cannot mix the two. Packages and Release files are
# signed, so a mirror is not trusted. A snapshot's Release files expire, so the
# validity check is off (Check-Valid-Until).
FROM ${BASE_IMAGE} AS base
ARG DEBIAN_SNAPSHOT
ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    set -eu; \
    mkdir -p /etc/apt/mirrors; \
    for host in snapshot.debian.org snapshot-cloudflare.debian.org; do \
      echo "http://${host}/archive/debian/${DEBIAN_SNAPSHOT}/"          >> /etc/apt/mirrors/debian.txt; \
      echo "http://${host}/archive/debian-security/${DEBIAN_SNAPSHOT}/" >> /etc/apt/mirrors/debian-security.txt; \
    done; \
    awk '/^URIs:/ { n++; print "URIs: mirror+file:/etc/apt/mirrors/" (n == 1 ? "debian" : "debian-security") ".txt"; next } { print }' \
      /etc/apt/sources.list.d/debian.sources > /tmp/debian.sources; \
    mv /tmp/debian.sources /etc/apt/sources.list.d/debian.sources; \
    grep -c '^URIs: mirror+file:' /etc/apt/sources.list.d/debian.sources | grep -qx 2; \
    printf '%s\n' 'Acquire::Retries "5";' 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/80snapshot; \
    sh /apt-install.sh ca-certificates git zstd


# ---------------------------------------------------------------------------
# Downloads, hash-checked. curl stays in these stages; only the files leave.
FROM base AS dl-base
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    sh /apt-install.sh curl

FROM dl-base AS dl-rustup
ARG TARGETARCH
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256_AMD64
ARG RUSTUP_SHA256_ARM64
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    --mount=type=bind,source=arch.sh,target=/arch.sh \
    set -eu; . /arch.sh; mkdir -p /out; \
    sh /fetch.sh "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${gnu}/rustup-init" "$(sha256_of RUSTUP)" /out/rustup-init

FROM dl-base AS dl-gh
ARG TARGETARCH
ARG GH_VERSION
ARG GH_SHA256_AMD64
ARG GH_SHA256_ARM64
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    --mount=type=bind,source=arch.sh,target=/arch.sh \
    set -eu; . /arch.sh; mkdir -p /out /tmp/dl; cd /tmp/dl; \
    sh /fetch.sh "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${go}.tar.gz" "$(sha256_of GH)" gh.tgz; \
    tar -xzf gh.tgz -C /out --strip-components=2 "gh_${GH_VERSION}_linux_${go}/bin/gh"; \
    chmod 755 /out/*

FROM dl-base AS dl-iai
ARG TARGETARCH
ARG IAI_CALLGRIND_RUNNER_VERSION
ARG IAI_CALLGRIND_RUNNER_SHA256_AMD64
ARG IAI_CALLGRIND_RUNNER_SHA256_ARM64
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    --mount=type=bind,source=arch.sh,target=/arch.sh \
    set -eu; . /arch.sh; mkdir -p /out /tmp/dl; cd /tmp/dl; \
    sh /fetch.sh "https://github.com/iai-callgrind/iai-callgrind/releases/download/v${IAI_CALLGRIND_RUNNER_VERSION}/iai-callgrind-runner-v${IAI_CALLGRIND_RUNNER_VERSION}-${gnu}.tar.gz" "$(sha256_of IAI_CALLGRIND_RUNNER)" iai.tgz; \
    tar -xzf iai.tgz -C /out --strip-components=1 "iai-callgrind-runner-v${IAI_CALLGRIND_RUNNER_VERSION}-${gnu}/iai-callgrind-runner"; \
    chmod 755 /out/*

FROM dl-base AS dl-cue
ARG TARGETARCH
ARG CUE_VERSION
ARG CUE_SHA256_AMD64
ARG CUE_SHA256_ARM64
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    --mount=type=bind,source=arch.sh,target=/arch.sh \
    set -eu; . /arch.sh; mkdir -p /out /tmp/dl; cd /tmp/dl; \
    sh /fetch.sh "https://github.com/cue-lang/cue/releases/download/${CUE_VERSION}/cue_${CUE_VERSION}_linux_${go}.tar.gz" "$(sha256_of CUE)" cue.tgz; \
    tar -xzf cue.tgz -C /out cue; \
    chmod 755 /out/*

FROM dl-base AS dl-wasm
ARG TARGETARCH
ARG WASM_PACK_VERSION
ARG WASM_PACK_SHA256_AMD64
ARG WASM_PACK_SHA256_ARM64
ARG WASM_BINDGEN_VERSION
ARG WASM_BINDGEN_SHA256_AMD64
ARG WASM_BINDGEN_SHA256_ARM64
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    --mount=type=bind,source=arch.sh,target=/arch.sh \
    set -eu; . /arch.sh; mkdir -p /out /tmp/dl; cd /tmp/dl; \
    sh /fetch.sh "https://github.com/wasm-bindgen/wasm-pack/releases/download/v${WASM_PACK_VERSION}/wasm-pack-v${WASM_PACK_VERSION}-${musl}.tar.gz" "$(sha256_of WASM_PACK)" wasm-pack.tgz; \
    tar -xzf wasm-pack.tgz -C /out --strip-components=1 "wasm-pack-v${WASM_PACK_VERSION}-${musl}/wasm-pack"; \
    sh /fetch.sh "https://github.com/wasm-bindgen/wasm-bindgen/releases/download/${WASM_BINDGEN_VERSION}/wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}.tar.gz" "$(sha256_of WASM_BINDGEN)" wasm-bindgen.tgz; \
    tar -xzf wasm-bindgen.tgz -C /out --strip-components=1 \
      "wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}/wasm-bindgen" \
      "wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}/wasm-bindgen-test-runner" \
      "wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}/wasm2es6js"; \
    chmod 755 /out/*


# ---------------------------------------------------------------------------
# rust-base: base plus a C toolchain (rustc links with cc, build scripts and
# cargo-fuzz's libFuzzer build need it). The toolchain itself is installed per
# image, below. CARGO_HOME and RUSTUP_HOME are outside any home directory and
# open to every uid, so a job container started as another user can use (and
# add to) them. Do not `rustup update` the pinned toolchains.
FROM base AS rust-base
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    sh /apt-install.sh build-essential


# ---------------------------------------------------------------------------
# bench: core's and runtime's instruction-count benchmarks. Run its container
# with `--security-opt seccomp=unconfined`: iai-callgrind's runner switches
# ASLR off with `setarch -R`, which Docker's default seccomp profile refuses.
FROM rust-base AS bench
ARG TARGETARCH
ARG RUST_STABLE
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    sh /apt-install.sh python3 valgrind
RUN --mount=type=bind,source=arch.sh,target=/arch.sh \
    --mount=type=bind,source=rustup.sh,target=/rustup.sh \
    --mount=type=bind,from=dl-rustup,source=/out,target=/dl \
    sh /rustup.sh "$RUST_STABLE" stable
COPY --from=dl-iai /out/ /usr/local/bin/
COPY --from=dl-gh /out/ /usr/local/bin/
ENV CI_RUST_STABLE=${RUST_STABLE}
ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/ComlineProject/ci-images" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.description="ComlineProject CI: Rust stable, valgrind and iai-callgrind-runner for the benchmarks (see images/versions.md)"


# ---------------------------------------------------------------------------
# fuzz: cargo-fuzz on a dated nightly.
FROM rust-base AS fuzz-rust
ARG TARGETARCH
ARG RUST_NIGHTLY
RUN --mount=type=bind,source=arch.sh,target=/arch.sh \
    --mount=type=bind,source=rustup.sh,target=/rustup.sh \
    --mount=type=bind,from=dl-rustup,source=/out,target=/dl \
    sh /rustup.sh "$RUST_NIGHTLY" nightly

# Only the binary leaves this stage.
FROM fuzz-rust AS fuzz-cargo
ARG CARGO_FUZZ_VERSION
RUN cargo install --locked --root /out --version "$CARGO_FUZZ_VERSION" cargo-fuzz

FROM fuzz-rust AS fuzz
ARG RUST_NIGHTLY
# python3: the Observatory report-fuzz action, run inside this container.
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    sh /apt-install.sh python3
COPY --from=fuzz-cargo /out/bin/ /usr/local/bin/
COPY --from=dl-gh /out/ /usr/local/bin/
ENV CI_RUST_NIGHTLY=${RUST_NIGHTLY}
ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/ComlineProject/ci-images" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.description="ComlineProject CI: Rust nightly, cargo-fuzz and python3 for the fuzz jobs (see images/versions.md)"


# ---------------------------------------------------------------------------
# wasm: the WebAssembly build (simulator, playground).
FROM rust-base AS wasm
ARG TARGETARCH
ARG RUST_STABLE
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    sh /apt-install.sh binaryen jq
RUN --mount=type=bind,source=arch.sh,target=/arch.sh \
    --mount=type=bind,source=rustup.sh,target=/rustup.sh \
    --mount=type=bind,from=dl-rustup,source=/out,target=/dl \
    sh /rustup.sh "$RUST_STABLE" stable -t wasm32-unknown-unknown -t wasm32-wasip1
COPY --from=dl-wasm /out/ /usr/local/bin/
ENV CI_RUST_STABLE=${RUST_STABLE}
ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/ComlineProject/ci-images" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.description="ComlineProject CI: Rust stable with wasm32 (unknown and wasip1), wasm-bindgen, wasm-pack and binaryen (see images/versions.md)"


# ---------------------------------------------------------------------------
# tools: the generated-code and specification checks (cue, cbindgen, the musl
# target).
FROM rust-base AS tools-rust
ARG TARGETARCH
ARG RUST_STABLE
RUN --mount=type=bind,source=apt-install.sh,target=/apt-install.sh \
    sh /apt-install.sh jq make musl-tools
RUN --mount=type=bind,source=arch.sh,target=/arch.sh \
    --mount=type=bind,source=rustup.sh,target=/rustup.sh \
    --mount=type=bind,from=dl-rustup,source=/out,target=/dl \
    set -eu; . /arch.sh; \
    sh /rustup.sh "$RUST_STABLE" stable -t "$musl"

# Only the binary leaves this stage.
FROM tools-rust AS tools-cargo
ARG CBINDGEN_VERSION
RUN cargo install --locked --root /out --version "$CBINDGEN_VERSION" cbindgen

FROM tools-rust AS tools
ARG RUST_STABLE
COPY --from=tools-cargo /out/bin/ /usr/local/bin/
COPY --from=dl-cue /out/ /usr/local/bin/
ENV CI_RUST_STABLE=${RUST_STABLE}
ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/ComlineProject/ci-images" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.description="ComlineProject CI: Rust stable with musl, cue and cbindgen (see images/versions.md)"

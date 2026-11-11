# syntax=docker/dockerfile:1
#
# ci-rust: Rust toolchains and the tools ComlineProject's Rust CI uses.
# Every version below is pinned; rust/versions.md says why each one is.
# Downloaded binaries are checked against the SHA-256 hashes below, per
# architecture, before they are used. A version bump changes the version and
# both hashes together.

# Ubuntu 24.04 (noble), the multi-arch index digest.
ARG UBUNTU_IMAGE=ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852

# Rust. RUST_STABLE is the default toolchain; RUST_NIGHTLY is the one cargo-fuzz
# and miri run on (use it as `cargo +nightly-YYYY-MM-DD ...`).
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


# Ubuntu's packages. valgrind is Ubuntu 24.04's (3.22), on purpose: the
# instruction-count baselines stay comparable with the hosted runner's.
FROM ${UBUNTU_IMAGE} AS apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      binaryen build-essential ca-certificates curl git jq make musl-tools \
      pkg-config python3 unzip valgrind xz-utils zstd \
 && rm -rf /var/lib/apt/lists/*


# The toolchains, in the final image. CARGO_HOME and RUSTUP_HOME are outside
# any home directory and open to every uid, so a job container started as
# another user can use (and add to) them.
#
# `stable` and `nightly` are made to name the pinned toolchains (links beside
# them), so `channel = "stable"` in a rust-toolchain.toml, RUSTUP_TOOLCHAIN=nightly
# and `cargo +nightly` resolve without a download. Do not `rustup update` them.
FROM apt AS rust
ARG TARGETARCH
ARG RUST_STABLE
ARG RUST_NIGHTLY
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256_AMD64
ARG RUSTUP_SHA256_ARM64
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    set -eu; \
    case "$TARGETARCH" in \
      amd64) triple=x86_64-unknown-linux-gnu;  musl=x86_64-unknown-linux-musl;  sha=$RUSTUP_SHA256_AMD64 ;; \
      arm64) triple=aarch64-unknown-linux-gnu; musl=aarch64-unknown-linux-musl; sha=$RUSTUP_SHA256_ARM64 ;; \
      *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    sh /fetch.sh "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${triple}/rustup-init" "$sha" /tmp/rustup-init; \
    chmod +x /tmp/rustup-init; \
    /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain none; \
    rm /tmp/rustup-init; \
    rustup set profile minimal; \
    rustup set auto-self-update disable; \
    rustup toolchain install "$RUST_STABLE" --profile minimal \
      -c clippy -c rustfmt -c llvm-tools-preview \
      -t wasm32-unknown-unknown -t wasm32-wasip1 -t "$musl"; \
    rustup toolchain install "$RUST_NIGHTLY" --profile minimal \
      -c clippy -c rustfmt -c llvm-tools-preview -c rust-src -c miri; \
    rustup default "$RUST_STABLE"; \
    ln -s "${RUST_STABLE}-${triple}"  "$RUSTUP_HOME/toolchains/stable-${triple}"; \
    ln -s "${RUST_NIGHTLY}-${triple}" "$RUSTUP_HOME/toolchains/nightly-${triple}"; \
    chmod -R a+rwX "$RUSTUP_HOME" "$CARGO_HOME"


# Prebuilt release binaries, hash-checked.
FROM apt AS prebuilt
ARG TARGETARCH
ARG CUE_VERSION
ARG CUE_SHA256_AMD64
ARG CUE_SHA256_ARM64
ARG WASM_PACK_VERSION
ARG WASM_PACK_SHA256_AMD64
ARG WASM_PACK_SHA256_ARM64
ARG WASM_BINDGEN_VERSION
ARG WASM_BINDGEN_SHA256_AMD64
ARG WASM_BINDGEN_SHA256_ARM64
ARG IAI_CALLGRIND_RUNNER_VERSION
ARG IAI_CALLGRIND_RUNNER_SHA256_AMD64
ARG IAI_CALLGRIND_RUNNER_SHA256_ARM64
ARG GH_VERSION
ARG GH_SHA256_AMD64
ARG GH_SHA256_ARM64
RUN --mount=type=bind,source=fetch.sh,target=/fetch.sh \
    set -eu; \
    case "$TARGETARCH" in \
      amd64) go=amd64; gnu=x86_64-unknown-linux-gnu;  musl=x86_64-unknown-linux-musl; \
             cue=$CUE_SHA256_AMD64; wp=$WASM_PACK_SHA256_AMD64; wb=$WASM_BINDGEN_SHA256_AMD64; \
             iai=$IAI_CALLGRIND_RUNNER_SHA256_AMD64; gh=$GH_SHA256_AMD64 ;; \
      arm64) go=arm64; gnu=aarch64-unknown-linux-gnu; musl=aarch64-unknown-linux-musl; \
             cue=$CUE_SHA256_ARM64; wp=$WASM_PACK_SHA256_ARM64; wb=$WASM_BINDGEN_SHA256_ARM64; \
             iai=$IAI_CALLGRIND_RUNNER_SHA256_ARM64; gh=$GH_SHA256_ARM64 ;; \
      *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    mkdir -p /out /tmp/dl; cd /tmp/dl; \
    sh /fetch.sh "https://github.com/cue-lang/cue/releases/download/${CUE_VERSION}/cue_${CUE_VERSION}_linux_${go}.tar.gz" "$cue" cue.tgz; \
    tar -xzf cue.tgz -C /out cue; \
    sh /fetch.sh "https://github.com/wasm-bindgen/wasm-pack/releases/download/v${WASM_PACK_VERSION}/wasm-pack-v${WASM_PACK_VERSION}-${musl}.tar.gz" "$wp" wasm-pack.tgz; \
    tar -xzf wasm-pack.tgz -C /out --strip-components=1 "wasm-pack-v${WASM_PACK_VERSION}-${musl}/wasm-pack"; \
    sh /fetch.sh "https://github.com/wasm-bindgen/wasm-bindgen/releases/download/${WASM_BINDGEN_VERSION}/wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}.tar.gz" "$wb" wasm-bindgen.tgz; \
    tar -xzf wasm-bindgen.tgz -C /out --strip-components=1 \
      "wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}/wasm-bindgen" \
      "wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}/wasm-bindgen-test-runner" \
      "wasm-bindgen-${WASM_BINDGEN_VERSION}-${musl}/wasm2es6js"; \
    sh /fetch.sh "https://github.com/iai-callgrind/iai-callgrind/releases/download/v${IAI_CALLGRIND_RUNNER_VERSION}/iai-callgrind-runner-v${IAI_CALLGRIND_RUNNER_VERSION}-${gnu}.tar.gz" "$iai" iai.tgz; \
    tar -xzf iai.tgz -C /out --strip-components=1 "iai-callgrind-runner-v${IAI_CALLGRIND_RUNNER_VERSION}-${gnu}/iai-callgrind-runner"; \
    sh /fetch.sh "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${go}.tar.gz" "$gh" gh.tgz; \
    tar -xzf gh.tgz -C /out --strip-components=2 "gh_${GH_VERSION}_linux_${go}/bin/gh"; \
    chmod 755 /out/*


# Tools without a prebuilt binary for both architectures. Only the binaries
# leave this stage.
FROM rust AS cargo-tools
ARG CARGO_FUZZ_VERSION
ARG CBINDGEN_VERSION
RUN cargo install --locked --root /out --version "$CARGO_FUZZ_VERSION" cargo-fuzz \
 && cargo install --locked --root /out --version "$CBINDGEN_VERSION" cbindgen


FROM rust AS final
ARG RUST_STABLE
ARG RUST_NIGHTLY
ENV CI_RUST_STABLE=${RUST_STABLE} \
    CI_RUST_NIGHTLY=${RUST_NIGHTLY}
COPY --from=prebuilt /out/ /usr/local/bin/
COPY --from=cargo-tools /out/bin/ /usr/local/bin/
ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/ComlineProject/ci-images" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.description="Rust toolchains and tools for ComlineProject CI (pinned; see rust/versions.md)"

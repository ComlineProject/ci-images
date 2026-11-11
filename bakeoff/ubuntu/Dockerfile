# syntax=docker/dockerfile:1
#
# Bake-off variant "ubuntu": Ubuntu 24.04 (noble), as ci-rust is today.
# The same tool set as the other variants (see bakeoff/README.md), amd64 only.
# Built with the repository root as the context:
#   docker build -f bakeoff/ubuntu/Dockerfile .
# Downloaded binaries are checked against SHA-256 hashes (rust/fetch.sh), as in
# rust/Dockerfile.

# The multi-arch index digest.
ARG BASE_IMAGE=ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852

ARG RUST_STABLE=1.99.1
ARG RUSTUP_VERSION=1.29.3
ARG RUSTUP_SHA256_AMD64=b1c8cb14e30889e7e2999e6b69e62d9e9b9ffc0f4df8180564d306d9680e6c55
ARG IAI_CALLGRIND_RUNNER_VERSION=0.16.1
ARG IAI_CALLGRIND_RUNNER_SHA256_AMD64=436feddb83ec916ddaf401dd1cea45aa329745067e8136a774b2fc581de6b448
ARG GH_VERSION=2.103.3
ARG GH_SHA256_AMD64=4c806978ffce1cec70853302a56d70ac6da4f19bae7adca4e1a8ab00633dd91d


# Downloads, hash-checked. curl stays in this stage; only the files leave it.
FROM ${BASE_IMAGE} AS fetch
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80retries \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256_AMD64
ARG IAI_CALLGRIND_RUNNER_VERSION
ARG IAI_CALLGRIND_RUNNER_SHA256_AMD64
ARG GH_VERSION
ARG GH_SHA256_AMD64
RUN --mount=type=bind,source=rust/fetch.sh,target=/fetch.sh \
    set -eu; \
    gnu=x86_64-unknown-linux-gnu; \
    mkdir -p /out /tmp/dl; cd /tmp/dl; \
    sh /fetch.sh "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${gnu}/rustup-init" "$RUSTUP_SHA256_AMD64" /out/rustup-init; \
    sh /fetch.sh "https://github.com/iai-callgrind/iai-callgrind/releases/download/v${IAI_CALLGRIND_RUNNER_VERSION}/iai-callgrind-runner-v${IAI_CALLGRIND_RUNNER_VERSION}-${gnu}.tar.gz" "$IAI_CALLGRIND_RUNNER_SHA256_AMD64" iai.tgz; \
    tar -xzf iai.tgz -C /out --strip-components=1 "iai-callgrind-runner-v${IAI_CALLGRIND_RUNNER_VERSION}-${gnu}/iai-callgrind-runner"; \
    sh /fetch.sh "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" "$GH_SHA256_AMD64" gh.tgz; \
    tar -xzf gh.tgz -C /out --strip-components=2 "gh_${GH_VERSION}_linux_amd64/bin/gh"; \
    chmod 755 /out/*


FROM ${BASE_IMAGE} AS final
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80retries \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates git python3 valgrind zstd \
 && rm -rf /var/lib/apt/lists/*
COPY --from=fetch /out/iai-callgrind-runner /out/gh /usr/local/bin/

# CARGO_HOME and RUSTUP_HOME are outside any home directory and open to every
# uid. `stable` names the pinned toolchain (a link beside it), so core's
# rust-toolchain.toml (`channel = "stable"`) resolves without a download.
ARG RUST_STABLE
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH} \
    CI_RUST_STABLE=${RUST_STABLE}
RUN --mount=type=bind,from=fetch,source=/out,target=/fetch \
    set -eu; \
    triple=x86_64-unknown-linux-gnu; \
    cp /fetch/rustup-init /tmp/rustup-init; \
    /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain none; \
    rm /tmp/rustup-init; \
    rustup set profile minimal; \
    rustup set auto-self-update disable; \
    rustup toolchain install "$RUST_STABLE" --profile minimal; \
    rustup default "$RUST_STABLE"; \
    ln -s "${RUST_STABLE}-${triple}" "$RUSTUP_HOME/toolchains/stable-${triple}"; \
    chmod -R a+rwX "$RUSTUP_HOME" "$CARGO_HOME"

ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/ComlineProject/ci-images" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.description="Base-image bake-off variant ubuntu (not for use)"

# Smoke: each tool runs. The runner has no --version: with none it fails, but
# names its own version.
RUN set -eu; \
    valgrind --version; \
    iai=$(iai-callgrind-runner --version 2>&1 || true); echo "$iai"; \
    case "$iai" in *"iai-callgrind-runner (0.16.1)"*) ;; *) echo "iai-callgrind-runner is not 0.16.1" >&2; exit 1 ;; esac; \
    cargo --version; \
    gh --version; \
    rustc --version; \
    python3 --version; git --version; cc --version; zstd --version

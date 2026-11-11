# arch.sh: sourced by the build scripts, with TARGETARCH set (by BuildKit).
# Exports the triples and the suffix of the per-architecture hash ARGs, and
# defines sha256_of NAME, which prints $NAME_SHA256_<suffix> (e.g. GH gives
# the value of GH_SHA256_AMD64 on amd64).
case "${TARGETARCH:?TARGETARCH is not set}" in
  amd64) go=amd64; gnu=x86_64-unknown-linux-gnu;  musl=x86_64-unknown-linux-musl;  A=AMD64 ;;
  arm64) go=arm64; gnu=aarch64-unknown-linux-gnu; musl=aarch64-unknown-linux-musl; A=ARM64 ;;
  *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;;
esac
export go gnu musl A
sha256_of() { printenv "$1_SHA256_$A"; }

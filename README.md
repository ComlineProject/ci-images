# ci-images

Pinned container images for ComlineProject's CI. Workflows run their jobs in an
image from here (`container:`) instead of installing tools on a floating
`ubuntu-latest` runner at run time.

| Image | Directory | Purpose |
|---|---|---|
| `ghcr.io/comlineproject/ci-rust` | [`rust/`](rust/) | Rust toolchains and the tools the Rust repositories' CI uses |

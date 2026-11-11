# Why the images are Debian trixie-slim

The CI images used to be one Ubuntu 24.04 image, `ci-rust`. Before splitting it
into four, a [bake-off](https://github.com/ComlineProject/ci-images/pull/2)
(branch `bakeoff`, `bakeoff/RESULTS.md`) built the bench image's tool set on
four bases and ran core's real instruction-count bench (iai-callgrind, 3 runs
each) on GitHub-hosted runners, amd64. The tool set: Rust 1.99.1 minimal,
valgrind, iai-callgrind-runner 0.16.1, python3, git, gh, a C toolchain, zstd.

## The numbers

| | ubuntu 24.04 | debian trixie-slim | wolfi | nix (nixpkgs 26.05) | VM (the old setup) |
|---|---|---|---|---|---|
| Compressed size | 434.7 MB | 450.5 MB | 517.3 MB | 620.2 MB | n/a |
| Uncompressed size | 1217.1 MB | 1259.9 MB | 1426.7 MB | 1675.7 MB | n/a |
| Build time (no cache) | 64.8 s | 66.3 s | 91.5 s | 108.1 s | n/a |
| Pull time (VM: apt + cargo install), median | 14.6 s | 13.7 s | 18.9 s | 29.1 s | 56.2 s |
| Bench compile, median | 98.0 s | 105.0 s | 110.0 s | 84.0 s | 101.0 s |
| Bench run, median | 3.0 s | 3.0 s | 2.0 s | 2.0 s | 3.0 s |
| Job time, median | 122.4 s | 126.6 s | 136.6 s | 121.8 s | 166.1 s |
| Counts identical across the 3 runs | yes | yes | yes | yes | yes |
| Counts vs ubuntu, max relative difference | baseline | 0.4364% | 17.2935% | 17.7877% | 0.0033% |
| valgrind | 3.22.0 | 3.24.0 | 3.28.0 | 3.26.0 | 3.22.0 |
| glibc | 2.39 | 2.41 | 2.44 | 2.42 | 2.39 |
| CVE scanner | Trivy | Trivy | Trivy | vulnix (Trivy cannot see Nix packages) | n/a |
| CVEs HIGH+CRITICAL with a fix | 3 | 3 | 0 | n/a (no fix data) | n/a |
| CVEs HIGH+CRITICAL, all | 185 | 158 | 0 | 23 | n/a |
| CVEs, all severities | 1097 | 1542 | 0 | 45 | n/a |
| Bit-identical rebuild | not checked | not checked | not checked | yes | n/a |

Instruction counts per benchmark, median, relative to ubuntu:

| benchmark | ubuntu 24.04 | debian trixie-slim | wolfi | nix |
|---|---:|---:|---:|---:|
| `parse/complex` | 3,044,093 | 3,034,966 (0.30%) | 3,570,523 (17.29%) | 3,585,566 (17.79%) |
| `parse/large/10` | 3,734,133 | 3,724,254 (0.26%) | 4,305,733 (15.31%) | 4,334,516 (16.08%) |
| `parse/large/100` | 36,800,014 | 36,708,318 (0.25%) | 42,606,393 (15.78%) | 42,688,067 (16.00%) |
| `parse/large/50` | 18,425,179 | 18,379,749 (0.25%) | 21,309,444 (15.65%) | 21,377,211 (16.02%) |
| `parse/simple` | 275,675 | 274,472 (0.44%) | 315,359 (14.40%) | 322,328 (16.92%) |

## Why Debian

- **A stable release.** trixie is Debian 13, a release with a support window,
  not a rolling feed like wolfi or nixpkgs. Its package versions only change
  by security and point updates.
- **The counts closest to today's.** Instruction counts are the bench's output,
  and the committed baselines are in those units. Debian's differ from
  Ubuntu's by at most 0.44% (valgrind 3.24 and glibc 2.41 against 3.22 and
  2.39); wolfi's and nix's differ by 14 to 18%, which would turn every baseline
  and every regression threshold over. Counts were identical across runs in
  every variant, so the difference is the toolchain, not noise.
- **The fastest pull.** 13.7 s median, against 14.6 s for Ubuntu, 18.9 s for
  wolfi, 29.1 s for nix and 56.2 s for the VM's apt and `cargo install`. Compressed size is
  within 4% of Ubuntu's (450.5 MB against 434.7 MB). Splitting the image in
  four makes each pull smaller still.
- **A date pin for the package set.** snapshot.debian.org serves the whole
  archive as it was at any timestamp, so `DEBIAN_SNAPSHOT` in the Dockerfile
  pins every apt package, and a rebuild a year later gives the same packages.
  Nothing else in the bake-off offers that for its package set with the same
  ease: Nix pins by a flake lock, but on a different toolchain.
- **Trivy's CVE counts are not comparable across distro feeds.** The
  table's numbers (Debian 158 HIGH+CRITICAL, Ubuntu 185, wolfi 0) come from
  each distribution's own security data, which counts differently: what a
  distribution lists as affected, and whether it lists an unfixed CVE at
  all, is its own policy. For Nix, Trivy cannot see the packages and vulnix
  reads NVD data without fix information. The one figure that is close to
  comparable is "HIGH+CRITICAL with a fix", and there Debian and Ubuntu are
  equal (3 each). The counts are not a reason to pick a base, and not one to
  reject Debian.

## What it costs

- The baselines are recorded again on the new images: valgrind and glibc
  differ from the hosted runners' (up to 0.44% in the bake-off's benchmarks).
- Package versions differ from Ubuntu's: python3 3.13, binaryen's newer
  `wasm-opt`, git 2.47. `images/versions.md` lists them.
- The snapshot has to be moved by hand (with the base digest) to get security
  updates; there is no weekly rebuild, since a rebuild changes nothing.

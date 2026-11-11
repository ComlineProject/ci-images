# Base-image bake-off: results

## At a glance

| | ubuntu 24.04 | debian trixie-slim | wolfi | nix (nixpkgs 26.05) | VM (today's setup) |
|---|---|---|---|---|---|
| Runs measured | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 |
| Compressed size | 434.7 MB | 450.5 MB | 517.3 MB | 620.2 MB | n/a (no image) |
| Uncompressed size | 1217.1 MB | 1259.9 MB | 1426.7 MB | 1675.7 MB | n/a (no image) |
| Build time (no cache) | 64.8 s | 66.3 s | 91.5 s | 108.1 s (cold Nix store; packages substituted from cache.nixos.org) | n/a |
| Pull time (VM: apt + cargo install), median | 14.6 s | 13.7 s | 18.9 s | 29.1 s | 56.2 s |
| Pull times, runs 1-3 | 16.5 s, 14.6 s, 14.2 s | 15.6 s, 13.0 s, 13.7 s | 18.1 s, 22.9 s, 18.9 s | 32.4 s, 26.0 s, 29.1 s | 47.8 s, 56.2 s, 59.3 s |
| Bench compile, median | 98.0 s | 105.0 s | 110.0 s | 84.0 s | 101.0 s |
| Bench run, median | 3.0 s | 3.0 s | 2.0 s | 2.0 s | 3.0 s |
| Job time, median | 122.4 s | 126.6 s | 136.6 s | 121.8 s | 166.1 s |
| Job times, runs 1-3 | 96.4 s, 122.4 s, 126.6 s | 134.6 s, 124.9 s, 126.6 s | 136.6 s, 117.6 s, 137.2 s | 144.1 s, 109.8 s, 121.8 s | 125.6 s, 167.2 s, 166.1 s |
| Counts identical across the runs | yes (max relative difference 0) | yes (max relative difference 0) | yes (max relative difference 0) | yes (max relative difference 0) | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | baseline | 0.4364% | 17.2935% | 17.7877% | 0.0033% |
| valgrind | valgrind-3.22.0 | valgrind-3.24.0 | valgrind-3.28.0 | valgrind-3.26.0 | valgrind-3.22.0 |
| glibc | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. | GNU C Library (Debian GLIBC 2.41-12+deb13u4) stable release version 2.41. | GNU C Library (glibc-2.44-r16) stable release version 2.44. | GNU C Library (GNU libc) stable release version 2.42. | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch | /usr/bin/setarch | /usr/bin/setarch | /bin/setarch | /usr/bin/setarch |
| CVE scanner used | Trivy | Trivy | Trivy | vulnix; Trivy: not meaningful, it cannot see Nix packages (Trivy ran and reported 4 total, 1 HIGH+CRITICAL) | n/a |
| CVEs HIGH+CRITICAL with a fix | 3 | 3 | 0 | n/a (vulnix has no fix data) | n/a |
| CVEs HIGH+CRITICAL, all | 185 | 158 | 0 | 23 (vulnix, CVSS v3 >= 7.0) | n/a |
| CVEs total, all severities | 1097 | 1542 | 0 | 45 (vulnix) | n/a |
| Reproducible image (bit-identical rebuild) | not checked (a Dockerfile build; no rebuild was compared) | not checked (a Dockerfile build; no rebuild was compared) | not checked (a Dockerfile build; no rebuild was compared) | yes (9 derivations built on the runner re-checked with nix-store --realise --check, 0 differ; image exported again: manifest digest equal, layer digests equal) | n/a (no image) |

## ubuntu 24.04

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 434.7 MB |
| Uncompressed size | 1217.1 MB |
| Build time (no cache) | 64.8 s |
| Pull time (VM: apt + cargo install), median | 14.6 s |
| Pull times, runs 1-3 | 16.5 s, 14.6 s, 14.2 s |
| Bench compile, median | 98.0 s |
| Bench run, median | 3.0 s |
| Job time, median | 122.4 s |
| Job times, runs 1-3 | 96.4 s, 122.4 s, 126.6 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | baseline |
| valgrind | valgrind-3.22.0 |
| glibc | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVE scanner used | Trivy |
| CVEs HIGH+CRITICAL with a fix | 3 |
| CVEs HIGH+CRITICAL, all | 185 |
| CVEs total, all severities | 1097 |
| Reproducible image (bit-identical rebuild) | not checked (a Dockerfile build; no rebuild was compared) |

Packages: `build-essential 12.10ubuntu1`, `ca-certificates 20260816ubuntu0.24.04.2`, `gcc 4:13.2.0-7ubuntu1`, `git 1:2.43.0-1ubuntu7.4`, `libc6 2.39-0ubuntu8.9`, `libc6-dbg 2.39-0ubuntu8.9`, `python3 3.12.3-0ubuntu2.1`, `valgrind 1:3.22.0-0ubuntu3`, `zstd 1.5.5+dfsg2-2build1.1`

## debian trixie-slim

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 450.5 MB |
| Uncompressed size | 1259.9 MB |
| Build time (no cache) | 66.3 s |
| Pull time (VM: apt + cargo install), median | 13.7 s |
| Pull times, runs 1-3 | 15.6 s, 13.0 s, 13.7 s |
| Bench compile, median | 105.0 s |
| Bench run, median | 3.0 s |
| Job time, median | 126.6 s |
| Job times, runs 1-3 | 134.6 s, 124.9 s, 126.6 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 0.4364% |
| valgrind | valgrind-3.24.0 |
| glibc | GNU C Library (Debian GLIBC 2.41-12+deb13u4) stable release version 2.41. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVE scanner used | Trivy |
| CVEs HIGH+CRITICAL with a fix | 3 |
| CVEs HIGH+CRITICAL, all | 158 |
| CVEs total, all severities | 1542 |
| Reproducible image (bit-identical rebuild) | not checked (a Dockerfile build; no rebuild was compared) |

Packages: `build-essential 12.12`, `ca-certificates 20250419+deb13u1`, `gcc 4:14.2.0-1`, `git 1:2.47.3-0+deb13u1`, `libc6 2.41-12+deb13u4`, `libc6-dbg 2.41-12+deb13u4`, `python3 3.13.5-1`, `valgrind 1:3.24.0-3`, `zstd 1.5.7+dfsg-1`

## wolfi

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 517.3 MB |
| Uncompressed size | 1426.7 MB |
| Build time (no cache) | 91.5 s |
| Pull time (VM: apt + cargo install), median | 18.9 s |
| Pull times, runs 1-3 | 18.1 s, 22.9 s, 18.9 s |
| Bench compile, median | 110.0 s |
| Bench run, median | 2.0 s |
| Job time, median | 136.6 s |
| Job times, runs 1-3 | 136.6 s, 117.6 s, 137.2 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 17.2935% |
| valgrind | valgrind-3.28.0 |
| glibc | GNU C Library (glibc-2.44-r16) stable release version 2.44. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVE scanner used | Trivy |
| CVEs HIGH+CRITICAL with a fix | 0 |
| CVEs HIGH+CRITICAL, all | 0 |
| CVEs total, all severities | 0 |
| Reproducible image (bit-identical rebuild) | not checked (a Dockerfile build; no rebuild was compared) |

Packages: `binutils-2.47-r4`, `build-base-1-r10`, `ca-certificates-bundle-20261020-r0`, `gcc-16.2.0-r3`, `gh-2.103.3-r2`, `git-2.56.1-r0`, `glibc-2.44-2.44-r16`, `glibc-2.44-dev-2.44-r16`, `glibc-2.44-locale-posix-2.44-r16`, `make-4.4.1-r15`, `python-3.13-3.13.18_git20261030-r0`, `python-3.13-base-3.13.18_git20261030-r0`, `valgrind-3.28.0-r0`, `zstd-1.5.7-r13`

## nix (nixpkgs 26.05)

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 620.2 MB |
| Uncompressed size | 1675.7 MB |
| Build time (no cache) | 108.1 s (cold Nix store; packages substituted from cache.nixos.org) |
| Pull time (VM: apt + cargo install), median | 29.1 s |
| Pull times, runs 1-3 | 32.4 s, 26.0 s, 29.1 s |
| Bench compile, median | 84.0 s |
| Bench run, median | 2.0 s |
| Job time, median | 121.8 s |
| Job times, runs 1-3 | 144.1 s, 109.8 s, 121.8 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 17.7877% |
| valgrind | valgrind-3.26.0 |
| glibc | GNU C Library (GNU libc) stable release version 2.42. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /bin/setarch |
| CVE scanner used | vulnix; Trivy: not meaningful, it cannot see Nix packages (Trivy ran and reported 4 total, 1 HIGH+CRITICAL) |
| CVEs HIGH+CRITICAL with a fix | n/a (vulnix has no fix data) |
| CVEs HIGH+CRITICAL, all | 23 (vulnix, CVSS v3 >= 7.0) |
| CVEs total, all severities | 45 (vulnix) |
| Reproducible image (bit-identical rebuild) | yes (9 derivations built on the runner re-checked with nix-store --realise --check, 0 differ; image exported again: manifest digest equal, layer digests equal) |
| Build, what Nix did | these 26 derivations will be built: these 182 paths will be fetched (341.2 MiB download, 1.1 GiB unpacked):  |
| Build time of the push tool (skopeo-nix2container), not in the build time | 87.6 s |
| Layers | 100 |
| vulnix version | vulnix 1.12.4 |
| vulnix: distinct CVE ids | 45 |
| vulnix: CRITICAL (CVSS v3 >= 9.0) | 7 |
| vulnix: without a CVSS v3 score | 0 |
| vulnix: packages affected | 10 |
| Re-checked derivations | identical: 0mjw521lh6yb1n6r7pjxxvzc0qz6z5wr-iai-callgrind-runner-0.16.1.drv, identical: gpf5mjpj27c016f86k9n34yfc2i12y02-dir.drv, identical: kpy24znlzqz0a04gcazzs1pp2mzjqqqd-dir.drv, identical: mb9hdzywqz49frb9v9q03max0fp3m4b9-dir.drv, identical: idwjja617aqppqgva75zd4w4sqj3k1h1-skeleton.drv, identical: msi2vkbgdkzlyjwamri2ymnz3ll2brgs-bench-env.drv, identical: 8pg446znzy7l0g8dysffpqsblf4142h2-closure-graph.json.drv, identical: 60rfsfx06c3v2q6ryzqfy6fgbvjbz87g-layers.json.drv, identical: q4brm23f5x96kwppv42sid107194iw7j-image-ci-bakeoff.json.drv |
| Manifest digest, first export | `sha256:6bc07e02a033434cd643b2c8854e3cf8da2b10d5ee692c0e579bed47e8acc356` |
| Manifest digest, export after the re-check | `sha256:6bc07e02a033434cd643b2c8854e3cf8da2b10d5ee692c0e579bed47e8acc356` |
| Manifest digest as pushed | `sha256:6bc07e02a033434cd643b2c8854e3cf8da2b10d5ee692c0e579bed47e8acc356` |

Packages: `rust-minimal-1.99.1`, `iai-callgrind-runner-0.16.1`, `valgrind-3.26.0`, `python3-3.13.17`, `git-2.54.0`, `gh-2.103.3`, `gcc-wrapper-15.3.0`, `gnumake-4.4.1`, `zstd-1.5.7`, `util-linux-2.42.4`, `glibc-2.42-103`, `nss-cacert-3.131.1`, `bash-interactive-5.3p9`, `coreutils-9.11`, `findutils-4.10.0`, `gnugrep-3.12`, `gnused-4.10`, `gawk-5.4.1`, `gnutar-1.35`, `gzip-1.14`

## VM (today's setup)

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | n/a (no image) |
| Uncompressed size | n/a (no image) |
| Build time (no cache) | n/a |
| Pull time (VM: apt + cargo install), median | 56.2 s |
| Pull times, runs 1-3 | 47.8 s, 56.2 s, 59.3 s |
| Bench compile, median | 101.0 s |
| Bench run, median | 3.0 s |
| Job time, median | 166.1 s |
| Job times, runs 1-3 | 125.6 s, 167.2 s, 166.1 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 0.0033% |
| valgrind | valgrind-3.22.0 |
| glibc | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVE scanner used | n/a |
| CVEs HIGH+CRITICAL with a fix | n/a |
| CVEs HIGH+CRITICAL, all | n/a |
| CVEs total, all severities | n/a |
| Reproducible image (bit-identical rebuild) | n/a (no image) |

Packages: `build-essential `, `ca-certificates 20260816ubuntu0.24.04.1`, `gcc 4:13.2.0-7ubuntu1`, `git 1:2.56.0-0ppa1~ubuntu24.04.2`, `libc6 2.39-0ubuntu8.9`, `libc6-dbg 2.39-0ubuntu8.9`, `python3 3.12.3-0ubuntu2.1`, `valgrind 1:3.22.0-0ubuntu3`, `zstd 1.5.5+dfsg2-2build1.1`

## Instruction counts (Ir), per benchmark

Median over the runs.

| benchmark | ubuntu 24.04 | debian trixie-slim | wolfi | nix (nixpkgs 26.05) | VM (today's setup) |
|---|---:|---:|---:|---:|---:|
| `parse/complex` | 3,044,093 | 3,034,966 | 3,570,523 | 3,585,566 | 3,044,093 |
| `parse/large/10` | 3,734,133 | 3,724,254 | 4,305,733 | 4,334,516 | 3,734,232 |
| `parse/large/100` | 36,800,014 | 36,708,318 | 42,606,393 | 42,688,067 | 36,800,923 |
| `parse/large/50` | 18,425,179 | 18,379,749 | 21,309,444 | 21,377,211 | 18,425,638 |
| `parse/simple` | 275,675 | 274,472 | 315,359 | 322,328 | 275,684 |

Max relative difference between the 3 runs of one variant (0 means identical).

| benchmark | ubuntu 24.04 | debian trixie-slim | wolfi | nix (nixpkgs 26.05) | VM (today's setup) |
|---|---:|---:|---:|---:|---:|
| `parse/complex` | 0 | 0 | 0 | 0 | 0 |
| `parse/large/10` | 0 | 0 | 0 | 0 | 0 |
| `parse/large/100` | 0 | 0 | 0 | 0 | 0 |
| `parse/large/50` | 0 | 0 | 0 | 0 | 0 |
| `parse/simple` | 0 | 0 | 0 | 0 | 0 |

Relative difference of the median against ubuntu 24.04.

| benchmark | debian trixie-slim | wolfi | nix (nixpkgs 26.05) | VM (today's setup) |
|---|---:|---:|---:|---:|
| `parse/complex` | 0.2998% | 17.2935% | 17.7877% | 0 |
| `parse/large/10` | 0.2646% | 15.3074% | 16.0782% | 0.0027% |
| `parse/large/100` | 0.2492% | 15.7782% | 16.0001% | 0.0025% |
| `parse/large/50` | 0.2466% | 15.6539% | 16.0217% | 0.0025% |
| `parse/simple` | 0.4364% | 14.3952% | 16.9232% | 0.0033% |


# Base-image bake-off: results

## At a glance

| | ubuntu 24.04 | debian trixie-slim | wolfi | VM (today's setup) |
|---|---|---|---|---|
| Runs measured | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 |
| Compressed size | 434.7 MB | 450.5 MB | 517.3 MB | n/a (no image) |
| Uncompressed size | 1217.1 MB | 1259.9 MB | 1426.7 MB | n/a (no image) |
| Build time (no cache) | 62.9 s | 77.4 s | 84.4 s | n/a |
| Pull time (VM: apt + cargo install), median | 19.7 s | 14.6 s | 18.0 s | 47.4 s |
| Pull times, runs 1-3 | 19.9 s, 12.4 s, 19.7 s | 13.4 s, 14.6 s, 18.2 s | 18.5 s, 18.0 s, 14.5 s | 47.4 s, 56.5 s, 38.2 s |
| Bench compile, median | 84.0 s | 102.0 s | 85.0 s | 75.0 s |
| Bench run, median | 2.0 s | 3.0 s | 2.0 s | 2.0 s |
| Job time, median | 114.4 s | 125.4 s | 110.7 s | 128.7 s |
| Job times, runs 1-3 | 114.4 s, 124.7 s, 98.9 s | 130.4 s, 125.4 s, 110.3 s | 110.7 s, 105.7 s, 128.4 s | 128.7 s, 166.7 s, 114.8 s |
| Counts identical across the runs | yes (max relative difference 0) | yes (max relative difference 0) | yes (max relative difference 0) | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | baseline | 0.4364% | 17.2935% | 0.0033% |
| valgrind | valgrind-3.22.0 | valgrind-3.24.0 | valgrind-3.28.0 | valgrind-3.22.0 |
| glibc | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. | GNU C Library (Debian GLIBC 2.41-12+deb13u4) stable release version 2.41. | GNU C Library (glibc-2.44-r16) stable release version 2.44. | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch | /usr/bin/setarch | /usr/bin/setarch | /usr/bin/setarch |
| CVEs HIGH+CRITICAL with a fix | 3 | 3 | 0 | n/a |
| CVEs HIGH+CRITICAL, all | 185 | 158 | 0 | n/a |
| CVEs total, all severities | 1097 | 1542 | 0 | n/a |

## ubuntu 24.04

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 434.7 MB |
| Uncompressed size | 1217.1 MB |
| Build time (no cache) | 62.9 s |
| Pull time (VM: apt + cargo install), median | 19.7 s |
| Pull times, runs 1-3 | 19.9 s, 12.4 s, 19.7 s |
| Bench compile, median | 84.0 s |
| Bench run, median | 2.0 s |
| Job time, median | 114.4 s |
| Job times, runs 1-3 | 114.4 s, 124.7 s, 98.9 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | baseline |
| valgrind | valgrind-3.22.0 |
| glibc | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVEs HIGH+CRITICAL with a fix | 3 |
| CVEs HIGH+CRITICAL, all | 185 |
| CVEs total, all severities | 1097 |

Packages: `build-essential 12.10ubuntu1`, `ca-certificates 20260816ubuntu0.24.04.2`, `gcc 4:13.2.0-7ubuntu1`, `git 1:2.43.0-1ubuntu7.4`, `libc6 2.39-0ubuntu8.9`, `libc6-dbg 2.39-0ubuntu8.9`, `python3 3.12.3-0ubuntu2.1`, `valgrind 1:3.22.0-0ubuntu3`, `zstd 1.5.5+dfsg2-2build1.1`

## debian trixie-slim

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 450.5 MB |
| Uncompressed size | 1259.9 MB |
| Build time (no cache) | 77.4 s |
| Pull time (VM: apt + cargo install), median | 14.6 s |
| Pull times, runs 1-3 | 13.4 s, 14.6 s, 18.2 s |
| Bench compile, median | 102.0 s |
| Bench run, median | 3.0 s |
| Job time, median | 125.4 s |
| Job times, runs 1-3 | 130.4 s, 125.4 s, 110.3 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 0.4364% |
| valgrind | valgrind-3.24.0 |
| glibc | GNU C Library (Debian GLIBC 2.41-12+deb13u4) stable release version 2.41. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVEs HIGH+CRITICAL with a fix | 3 |
| CVEs HIGH+CRITICAL, all | 158 |
| CVEs total, all severities | 1542 |

Packages: `build-essential 12.12`, `ca-certificates 20250419+deb13u1`, `gcc 4:14.2.0-1`, `git 1:2.47.3-0+deb13u1`, `libc6 2.41-12+deb13u4`, `libc6-dbg 2.41-12+deb13u4`, `python3 3.13.5-1`, `valgrind 1:3.24.0-3`, `zstd 1.5.7+dfsg-1`

## wolfi

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | 517.3 MB |
| Uncompressed size | 1426.7 MB |
| Build time (no cache) | 84.4 s |
| Pull time (VM: apt + cargo install), median | 18.0 s |
| Pull times, runs 1-3 | 18.5 s, 18.0 s, 14.5 s |
| Bench compile, median | 85.0 s |
| Bench run, median | 2.0 s |
| Job time, median | 110.7 s |
| Job times, runs 1-3 | 110.7 s, 105.7 s, 128.4 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 17.2935% |
| valgrind | valgrind-3.28.0 |
| glibc | GNU C Library (glibc-2.44-r16) stable release version 2.44. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVEs HIGH+CRITICAL with a fix | 0 |
| CVEs HIGH+CRITICAL, all | 0 |
| CVEs total, all severities | 0 |

Packages: `binutils-2.47-r4`, `build-base-1-r10`, `ca-certificates-bundle-20261020-r0`, `gcc-16.2.0-r3`, `gh-2.103.3-r2`, `git-2.56.1-r0`, `glibc-2.44-2.44-r16`, `glibc-2.44-dev-2.44-r16`, `glibc-2.44-locale-posix-2.44-r16`, `make-4.4.1-r15`, `python-3.13-3.13.18_git20261030-r0`, `python-3.13-base-3.13.18_git20261030-r0`, `valgrind-3.28.0-r0`, `zstd-1.5.7-r13`

## VM (today's setup)

| | |
|---|---|
| Runs measured | 3 of 3 |
| Compressed size | n/a (no image) |
| Uncompressed size | n/a (no image) |
| Build time (no cache) | n/a |
| Pull time (VM: apt + cargo install), median | 47.4 s |
| Pull times, runs 1-3 | 47.4 s, 56.5 s, 38.2 s |
| Bench compile, median | 75.0 s |
| Bench run, median | 2.0 s |
| Job time, median | 128.7 s |
| Job times, runs 1-3 | 128.7 s, 166.7 s, 114.8 s |
| Counts identical across the runs | yes (max relative difference 0) |
| Counts vs ubuntu, max relative difference | 0.0033% |
| valgrind | valgrind-3.22.0 |
| glibc | GNU C Library (Ubuntu GLIBC 2.39-0ubuntu8.9) stable release version 2.39. |
| rustc | rustc 1.99.1 (58cf8f9c3 2026-10-13) |
| setarch | /usr/bin/setarch |
| CVEs HIGH+CRITICAL with a fix | n/a |
| CVEs HIGH+CRITICAL, all | n/a |
| CVEs total, all severities | n/a |

Packages: `build-essential `, `ca-certificates 20260816ubuntu0.24.04.1`, `gcc 4:13.2.0-7ubuntu1`, `git 1:2.56.0-0ppa1~ubuntu24.04.2`, `libc6 2.39-0ubuntu8.9`, `libc6-dbg 2.39-0ubuntu8.9`, `python3 3.12.3-0ubuntu2.1`, `valgrind 1:3.22.0-0ubuntu3`, `zstd 1.5.5+dfsg2-2build1.1`

## Instruction counts (Ir), per benchmark

Median over the runs.

| benchmark | ubuntu 24.04 | debian trixie-slim | wolfi | VM (today's setup) |
|---|---:|---:|---:|---:|
| `parse/complex` | 3,044,093 | 3,034,966 | 3,570,523 | 3,044,093 |
| `parse/large/10` | 3,734,133 | 3,724,254 | 4,305,733 | 3,734,232 |
| `parse/large/100` | 36,800,014 | 36,708,318 | 42,606,393 | 36,800,923 |
| `parse/large/50` | 18,425,179 | 18,379,749 | 21,309,444 | 18,425,638 |
| `parse/simple` | 275,675 | 274,472 | 315,359 | 275,684 |

Max relative difference between the 3 runs of one variant (0 means identical).

| benchmark | ubuntu 24.04 | debian trixie-slim | wolfi | VM (today's setup) |
|---|---:|---:|---:|---:|
| `parse/complex` | 0 | 0 | 0 | 0 |
| `parse/large/10` | 0 | 0 | 0 | 0 |
| `parse/large/100` | 0 | 0 | 0 | 0 |
| `parse/large/50` | 0 | 0 | 0 | 0 |
| `parse/simple` | 0 | 0 | 0 | 0 |

Relative difference of the median against ubuntu 24.04.

| benchmark | debian trixie-slim | wolfi | VM (today's setup) |
|---|---:|---:|---:|
| `parse/complex` | 0.2998% | 17.2935% | 0 |
| `parse/large/10` | 0.2646% | 15.3074% | 0.0027% |
| `parse/large/100` | 0.2492% | 15.7782% | 0.0025% |
| `parse/large/50` | 0.2466% | 15.6539% | 0.0025% |
| `parse/simple` | 0.4364% | 14.3952% | 0.0033% |


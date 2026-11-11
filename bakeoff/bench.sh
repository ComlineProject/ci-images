#!/bin/sh
# bench.sh: core's instruction-count bench, as the `master` job of core's
# .github/workflows/bench.yml runs it. Run from a checkout of core (the
# workflow mounts it at /work in every variant, the container ones and the VM,
# so the bench binary's path is the same everywhere). Writes phases.env to $OUT.
set -eu
OUT=${OUT:-/out}
mkdir -p "$OUT"

export CARGO_TERM_COLOR=always
# Where iai-callgrind keeps its output and where the bench builds: fixed paths,
# the same in every variant (a path's length can move counts).
export IAI_CALLGRIND_HOME=/tmp/iai
export CARGO_TARGET_DIR=/tmp/target

git config --global --add safe.directory "$PWD" || true

# The tools in use, recorded once, from inside the environment.
sh "$(dirname "$0")/envinfo.sh" > "$OUT/env.txt"

# Compile first, apart, so the run is timed without the dependency downloads
# and the build.
t0=$(date +%s)
cargo bench -p comline-core --bench parser_instructions --no-run
t1=$(date +%s)
# Core's command.
cargo bench -p comline-core --bench parser_instructions -- --save-summary=json
t2=$(date +%s)

printf 'compile_seconds=%s\nbench_seconds=%s\n' "$((t1 - t0))" "$((t2 - t1))" > "$OUT/phases.env"

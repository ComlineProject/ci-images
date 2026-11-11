#!/bin/sh
# bench-check.sh: core's instruction-count bench, as the `master` job of core's
# bench.yml runs it. Run from a checkout of core, inside the ci-bench image
# (with `--security-opt seccomp=unconfined`: iai-callgrind's runner calls
# `setarch -R`, which Docker's default seccomp profile refuses). Fails unless
# every benchmark wrote a summary with an instruction count.
set -eu
export CARGO_TERM_COLOR=always
export IAI_CALLGRIND_HOME=/tmp/iai
export CARGO_TARGET_DIR=/tmp/target
git config --global --add safe.directory "$PWD"

# core commits no Cargo.lock: resolve once, here.
[ -e Cargo.lock ] || cargo generate-lockfile
cargo bench -p comline-core --bench parser_instructions -- --save-summary=json

python3 -I - "$IAI_CALLGRIND_HOME" <<'PY'
import json, pathlib, sys
home = pathlib.Path(sys.argv[1])
paths = sorted(home.glob("comline-core/parser_instructions/**/summary.json"))
if not paths:
    sys.exit(f"no summary.json under {home}")
for p in paths:
    s = json.loads(p.read_text())
    m = s["profiles"][0]["summaries"]["total"]["summary"]["Callgrind"]["Ir"]["metrics"]
    ir = m["Left"]["Int"] if "Left" in m else m["Both"][0]["Int"]
    if ir <= 0:
        sys.exit(f"{p}: no instructions counted")
    print(f"{s['function_name']} {s.get('id') or ''}: {ir} Ir")
print(f"{len(paths)} benchmarks counted")
PY

"""Write the bake-off's results table, as markdown, to stdout.

    python3 -I report.py ARTIFACTS_DIR

ARTIFACTS_DIR holds the downloaded artifacts, one directory each:
  build-<variant>/build.json   (nix's also holds "repro" and "vulnix", see bakeoff.yml)
  measure-<variant>-<run>/{measure.json, counts.json, env.txt}
"""
import json
import pathlib
import statistics
import sys

VARIANTS = ["ubuntu", "debian", "wolfi", "nix", "vm"]
LABEL = {"ubuntu": "ubuntu 24.04", "debian": "debian trixie-slim", "wolfi": "wolfi", "nix": "nix (nixpkgs 26.05)", "vm": "VM (today's setup)"}
BASE = "ubuntu"


def load(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return None


def read_env(path):
    env, pkgs = {}, []
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return env, pkgs
    for line in lines:
        key, _, value = line.partition("=")
        if key == "pkg":
            pkgs.append(value)
        elif key:
            env[key] = value
    return env, pkgs


def median(values):
    values = [v for v in values if v is not None]
    return statistics.median(values) if values else None


def secs(v):
    return "n/a" if v is None else f"{v:.1f} s"


def mb(v):
    return "n/a" if v is None else f"{v / 1e6:.1f} MB"


def pct(v):
    if v is None:
        return "n/a"
    return "0" if v == 0 else f"{v * 100:.4f}%"


def main():
    root = pathlib.Path(sys.argv[1])
    data = {}
    for v in VARIANTS:
        d = {"build": load(root / f"build-{v}" / "build.json"), "runs": []}
        for n in (1, 2, 3):
            m = root / f"measure-{v}-{n}"
            measure = load(m / "measure.json")
            if measure is None:
                continue
            env, pkgs = read_env(m / "env.txt")
            d["runs"].append({"n": n, "m": measure, "counts": load(m / "counts.json") or {}, "env": env, "pkgs": pkgs})
        data[v] = d

    # Instruction counts: per benchmark, the values over the runs.
    bench_ids = sorted({b for d in data.values() for r in d["runs"] for b in r["counts"]})
    values = {v: {b: [r["counts"][b] for r in d["runs"] if b in r["counts"]] for b in bench_ids} for v, d in data.items()}

    def run_diff(v, b):
        vals = values[v][b]
        if len(vals) < 2:
            return None
        return (max(vals) - min(vals)) / min(vals)

    def stable(v):
        diffs = [run_diff(v, b) for b in bench_ids]
        diffs = [x for x in diffs if x is not None]
        if not diffs:
            return None, None
        return all(x == 0 for x in diffs), max(diffs)

    def med(v, b):
        return median(values[v][b])

    def vs_base(v, b):
        a, base = med(v, b), med(BASE, b)
        if a is None or not base:
            return None
        return abs(a - base) / base

    def max_vs_base(v):
        diffs = [vs_base(v, b) for b in bench_ids]
        diffs = [x for x in diffs if x is not None]
        return max(diffs) if diffs else None

    def runs(v, key):
        return [r["m"].get(key) for r in data[v]["runs"]]

    def cve(v, key):
        for r in data[v]["runs"]:
            c = r["m"].get("cve")
            if c:
                return c.get(key)
        return None

    def env(v, key):
        for r in data[v]["runs"]:
            if r["env"].get(key):
                return r["env"][key]
        return "n/a"

    def trivy_note(v):
        t, h = cve(v, "total"), cve(v, "high_critical")
        return "no Trivy result" if t is None else f"Trivy ran and reported {t} total, {h} HIGH+CRITICAL"

    def repro(v):
        b = data[v]["build"] or {}
        if v == "vm":
            return "n/a (no image)"
        r = b.get("repro")
        if r is None:
            return "not checked (a Dockerfile build; no rebuild was compared)" if b else "n/a"
        what = "yes" if r.get("bit_identical") else "no"
        rc = r.get("rebuild_exit", {})
        return (f"{what} (nix build --rebuild of image/env/runner: exit {rc.get('image')}/{rc.get('env')}/{rc.get('iai_callgrind_runner')}; "
                f"re-exported manifest digest {'equal' if r.get('manifest_identical') else 'different'}, "
                f"layer digests {'equal' if r.get('layers_identical') else 'different'})")

    def scanner(v):
        if v == "vm":
            return "n/a"
        if v == "nix":
            x = (data[v]["build"] or {}).get("vulnix") or {}
            used = "vulnix (failed to run)" if x.get("failed") else "vulnix"
            return f"{used}; Trivy: not meaningful, it cannot see Nix packages ({trivy_note(v)})"
        return "Trivy"

    def cve_rows(v):
        if v == "nix":
            x = (data[v]["build"] or {}).get("vulnix") or {}
            if not x or x.get("failed"):
                return [("CVEs HIGH+CRITICAL with a fix", "n/a"), ("CVEs HIGH+CRITICAL, all", "n/a (vulnix failed)"),
                        ("CVEs total, all severities", "n/a (vulnix failed)")]
            return [("CVEs HIGH+CRITICAL with a fix", "n/a (vulnix has no fix data)"),
                    ("CVEs HIGH+CRITICAL, all", f"{x['high_critical']} (vulnix, CVSS v3 >= 7.0)"),
                    ("CVEs total, all severities", f"{x['total']} (vulnix)")]
        return [
            ("CVEs HIGH+CRITICAL with a fix", "n/a" if cve(v, "high_critical_fixed") is None else str(cve(v, "high_critical_fixed"))),
            ("CVEs HIGH+CRITICAL, all", "n/a" if cve(v, "high_critical") is None else str(cve(v, "high_critical"))),
            ("CVEs total, all severities", "n/a" if cve(v, "total") is None else str(cve(v, "total"))),
        ]

    def extra(v):
        # Rows only the nix variant has.
        b = data[v]["build"] or {}
        if v != "nix" or not b:
            return []
        x = b.get("vulnix") or {}
        out = [("Build, what Nix did", b.get("nix_plan") or "n/a"),
               ("Build time of the push tool (skopeo-nix2container), not in the build time", secs(b.get("push_tool_build_seconds"))),
               ("Layers", str(b.get("layers")))]
        if x.get("version"):
            out.append(("vulnix version", x["version"]))
        if x and not x.get("failed"):
            out += [("vulnix: distinct CVE ids", str(x["unique_cves"])), ("vulnix: CRITICAL (CVSS v3 >= 9.0)", str(x["critical"])),
                    ("vulnix: without a CVSS v3 score", str(x["unscored"])), ("vulnix: packages affected", str(x["packages_affected"]))]
        r = b.get("repro") or {}
        if r:
            out += [("First manifest digest", f"`{r.get('first_manifest_digest')}`"), ("Second manifest digest", f"`{r.get('second_manifest_digest')}`")]
        return out

    def rows(v):
        b = data[v]["build"] or {}
        same, worst = stable(v)
        diff = None if v == BASE else max_vs_base(v)
        pull_key = "setup_seconds" if v == "vm" else "pull_seconds"
        return [
            ("Runs measured", f"{len(data[v]['runs'])} of 3"),
            ("Compressed size", mb(b.get("compressed_bytes")) if b else "n/a (no image)"),
            ("Uncompressed size", mb(b.get("uncompressed_bytes")) if b else "n/a (no image)"),
            ("Build time (no cache)", (secs(b.get("build_seconds")) + (" (cold Nix store; packages substituted from cache.nixos.org)" if v == "nix" else "")) if b else "n/a"),
            ("Pull time (VM: apt + cargo install), median", secs(median(runs(v, pull_key)))),
            ("Pull times, runs 1-3", ", ".join(secs(x) for x in runs(v, pull_key)) or "n/a"),
            ("Bench compile, median", secs(median(runs(v, "compile_seconds")))),
            ("Bench run, median", secs(median(runs(v, "bench_seconds")))),
            ("Job time, median", secs(median(runs(v, "job_seconds")))),
            ("Job times, runs 1-3", ", ".join(secs(x) for x in runs(v, "job_seconds")) or "n/a"),
            ("Counts identical across the runs", "n/a" if same is None else ("yes" if same else "no") + f" (max relative difference {pct(worst)})"),
            ("Counts vs ubuntu, max relative difference", "baseline" if v == BASE else pct(diff)),
            ("valgrind", env(v, "valgrind")),
            ("glibc", env(v, "glibc")),
            ("rustc", env(v, "rustc")),
            ("setarch", env(v, "setarch")),
            ("CVE scanner used", scanner(v)),
            *cve_rows(v),
            ("Reproducible image (bit-identical rebuild)", repro(v)),
        ]

    out = ["# Base-image bake-off: results", ""]
    present = [v for v in VARIANTS if data[v]["runs"] or data[v]["build"]]
    labels = [LABEL[v] for v in present]
    table = {v: dict(rows(v)) for v in present}
    names = [k for k, _ in rows(present[0])]
    out += ["## At a glance", "", "| | " + " | ".join(labels) + " |", "|---|" + "---|" * len(present)]
    for name in names:
        out.append(f"| {name} | " + " | ".join(table[v].get(name, "") for v in present) + " |")
    out.append("")

    for v in present:
        out += [f"## {LABEL[v]}", "", "| | |", "|---|---|"]
        out += [f"| {k} | {val} |" for k, val in rows(v) + extra(v)]
        out.append("")
        pkgs = data[v]["runs"][0]["pkgs"] if data[v]["runs"] else []
        if pkgs:
            out += ["Packages: " + ", ".join(f"`{p}`" for p in pkgs), ""]

    out += ["## Instruction counts (Ir), per benchmark", ""]
    if not bench_ids:
        out += ["No counts were recorded.", ""]
    else:
        out += ["Median over the runs.", "", "| benchmark | " + " | ".join(labels) + " |", "|---|" + "---:|" * len(present)]
        for b in bench_ids:
            out.append(f"| `{b}` | " + " | ".join("n/a" if med(v, b) is None else f"{med(v, b):,.0f}" for v in present) + " |")
        out += ["", "Max relative difference between the 3 runs of one variant (0 means identical).", "",
                "| benchmark | " + " | ".join(labels) + " |", "|---|" + "---:|" * len(present)]
        for b in bench_ids:
            out.append(f"| `{b}` | " + " | ".join(pct(run_diff(v, b)) for v in present) + " |")
        others = [v for v in present if v != BASE]
        out += ["", f"Relative difference of the median against {LABEL[BASE]}.", "",
                "| benchmark | " + " | ".join(LABEL[v] for v in others) + " |", "|---|" + "---:|" * len(others)]
        for b in bench_ids:
            out.append(f"| `{b}` | " + " | ".join(pct(vs_base(v, b)) for v in others) + " |")
        out.append("")
    print("\n".join(out))


main()

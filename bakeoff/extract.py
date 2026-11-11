"""Per-benchmark instruction counts from iai-callgrind's summary.json files.

    python3 -I extract.py IAI_HOME > counts.json

Reads every summary.json under IAI_HOME/comline-core/parser_instructions the way
core's .github/scripts/bench-report.py does, and prints {benchmark id: Ir}.
"""
import json
import pathlib
import sys


def bench_id(summary):
    group = summary["module_path"].split("::")[-2]
    function = summary["function_name"]
    case = summary.get("id") or ""
    if case.startswith("n") and case[1:].isdigit():
        case = case[1:]
    return "/".join(p for p in (group, function, case) if p)


def ir(summary):
    metrics = summary["profiles"][0]["summaries"]["total"]["summary"]["Callgrind"]["Ir"]["metrics"]
    if "Left" in metrics:
        return metrics["Left"]["Int"]
    if "Both" in metrics:
        return metrics["Both"][0]["Int"]
    raise ValueError(f"no Ir count in {summary['module_path']}")


def main():
    home = pathlib.Path(sys.argv[1])
    counts = {}
    for path in sorted(home.glob("comline-core/parser_instructions/**/summary.json")):
        summary = json.loads(path.read_text())
        name = bench_id(summary)
        if name in counts:
            sys.exit(f"two benchmarks have the id {name}")
        counts[name] = ir(summary)
    if not counts:
        sys.exit(f"no summary.json under {home}")
    json.dump(counts, sys.stdout, indent=2, sort_keys=True)
    print()


main()

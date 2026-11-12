#!/usr/bin/env python3
"""oci-diff.py A.tar B.tar: say what differs between two OCI archives of one image.

Prints the manifest and config differences, then for every layer whose digest
differs, each file that is only in one of the two, or differs in type, mode,
owner, link target or content hash (at most --max per layer); files that
differ only in mtime are counted, with a few examples. Meant for
the log of a failed reproducibility check; it does not need either image to be
loadable. Run it with `python3 -I`.
"""
import argparse
import hashlib
import json
import tarfile


def read_blob(tar, digest):
    algo, _, hexa = digest.partition(":")
    return tar.extractfile(f"blobs/{algo}/{hexa}").read()


def manifest_of(tar):
    index = json.loads(tar.extractfile("index.json").read())
    desc = index["manifests"][0]
    while True:
        doc = json.loads(read_blob(tar, desc["digest"]))
        if "manifests" not in doc:
            return desc["digest"], doc
        desc = doc["manifests"][0]


def layer_files(tar, digest):
    """path -> (type, mode, uid, gid, mtime, linkname, sha256 of content)"""
    algo, _, hexa = digest.partition(":")
    files = {}
    with tarfile.open(fileobj=tar.extractfile(f"blobs/{algo}/{hexa}"), mode="r|*") as layer:
        for m in layer:
            h = ""
            if m.isreg():
                h = hashlib.sha256(layer.extractfile(m).read()).hexdigest()
            files[m.name] = (chr(m.type[0]) if isinstance(m.type, bytes) else m.type,
                             oct(m.mode), m.uid, m.gid, int(m.mtime), m.linkname, h)
    return files


def diff_json(a, b, path=""):
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            yield from diff_json(a.get(k), b.get(k), f"{path}/{k}")
    elif isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
        for i, (x, y) in enumerate(zip(a, b)):
            yield from diff_json(x, y, f"{path}[{i}]")
    elif a != b:
        yield f"{path}: {a!r} != {b!r}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("a")
    ap.add_argument("b")
    ap.add_argument("--max", type=int, default=60)
    args = ap.parse_args()
    ta, tb = tarfile.open(args.a), tarfile.open(args.b)
    da, ma = manifest_of(ta)
    db, mb = manifest_of(tb)
    print(f"manifest A {da}\nmanifest B {db}")
    if da == db:
        print("identical")
        return
    print("\nconfig differences:")
    ca = json.loads(read_blob(ta, ma["config"]["digest"]))
    cb = json.loads(read_blob(tb, mb["config"]["digest"]))
    for line in diff_json(ca, cb):
        print("  " + line)
    la, lb = ma["layers"], mb["layers"]
    if len(la) != len(lb):
        print(f"\nlayer count differs: {len(la)} != {len(lb)}")
    for i, (x, y) in enumerate(zip(la, lb)):
        if x["digest"] == y["digest"]:
            continue
        print(f"\nlayer {i}: {x['digest']} != {y['digest']} (sizes {x['size']}, {y['size']})")
        fa, fb = layer_files(ta, x["digest"]), layer_files(tb, y["digest"])
        shown = 0
        mtime_only = []
        for name in sorted(set(fa) | set(fb)):
            if fa.get(name) == fb.get(name):
                continue
            if name in fa and name in fb and fa[name][:4] + fa[name][5:] == fb[name][:4] + fb[name][5:]:
                mtime_only.append(name)
                continue
            shown += 1
            if shown > args.max:
                print("  ...")
                break
            if name not in fa:
                print(f"  only in B: {name}")
            elif name not in fb:
                print(f"  only in A: {name}")
            else:
                print(f"  {name}\n    A {fa[name]}\n    B {fb[name]}")
        if mtime_only:
            print(f"  {len(mtime_only)} files differ only in mtime, for example:")
            for name in mtime_only[:5]:
                print(f"    {name}: {fa[name][4]} != {fb[name][4]}")
        if shown == 0 and not mtime_only:
            print("  same files and metadata: the difference is in the layer's encoding (tar or gzip)")


main()

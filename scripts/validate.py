#!/usr/bin/env python
"""Compare a fresh solve against the 2018 reference outputs.

    python scripts/validate.py results/OSeMOSYS_ATX_Baseline_Results.csv

Reports the fraction of numeric cells that agree bit-for-bit, and where the rest sit.
The residual is expected to be concentrated in storage levels and NewCapacity: this
is a degenerate LP, so cost and capacity totals are reproducible but the dispatch
schedule and build timing are not. See README.
"""
import sys, collections
from pathlib import Path

REF = Path(__file__).resolve().parents[1] / "reference-output"


def load(path):
    out = {}
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.split(",")
        if len(parts) > 3:
            key = tuple(p.strip('"') for p in parts[:3])
            try:
                out[key] = [float(p) for p in parts[3:] if p.strip()]
            except ValueError:
                pass
    return out


def main(candidate, reference=None):
    cand_path = Path(candidate)
    if not cand_path.exists():
        print(f"no such file: {candidate}", file=sys.stderr)
        return 2
    ref_path = Path(reference) if reference else REF / cand_path.name
    if not ref_path.exists():
        avail = sorted(p.name for p in REF.glob("*.csv"))
        print(f"no reference for {cand_path.name!r} at {ref_path}", file=sys.stderr)
        print(f"references available: {avail}", file=sys.stderr)
        print("pass one explicitly:  validate.py <candidate> <reference>", file=sys.stderr)
        return 2
    ref = load(ref_path)
    got = load(cand_path)
    shared = [k for k in got if k in ref and len(got[k]) == len(ref[k])]
    if not shared:
        print("no comparable rows - is this the right file?", file=sys.stderr)
        return 2                       # never pass vacuously over an empty set
    per = collections.defaultdict(lambda: [0, 0])
    cells = same = 0
    for k in shared:
        for a, b in zip(ref[k], got[k]):
            cells += 1
            per[k[0]][0] += 1
            if a == b:
                same += 1
            else:
                per[k[0]][1] += 1
    print(f"rows compared : {len(shared)}")
    print(f"numeric cells : {cells:,}")
    print(f"identical     : {same:,}  ({100*same/cells:.2f}%)")
    print("\nby section:")
    for sec, (n, d) in sorted(per.items(), key=lambda x: -x[1][1]):
        if d:
            print(f"  {sec:46s} {d:5d}/{n:<6d} differ  ({100*d/n:5.1f}%)")
    only = len(got) - len(shared)
    if only:
        print(f"\n{only} rows had no counterpart (report-writer year mismatch; see README)")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(1)
    raise SystemExit(main(*sys.argv[1:3]))

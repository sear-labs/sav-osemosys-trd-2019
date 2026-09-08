#!/usr/bin/env python
"""Build the reduced instance and ship it as standard .mps and .sol files.

    python scripts/export_reduced.py

Why these files exist: building the model needs gurobipy, and gurobipy needs a licence
above 2,000 variables - which the reduced instance exceeds by a factor of thirty. Shipping
the built model in a standard exchange format means **anyone can solve it with anything**,
including `highspy`, which is pip-installable and has no size limit and no licence.

So the reduced instance is the artifact that makes the pattern portable, and it does three
jobs at once:

    the example notebook solves it with HiGHS, needing no licence
    the thin notebook verifies the shipped .sol against it, needing no solver
    anyone porting this model to another tool has a reference instance and answer

The FULL model cannot be shipped this way - its .mps is about 3.4 GB against GitHub's
100 MB limit, measured. That is why the full model's published result is verified by
reconstructing the objective from its cost components instead.

The reduction is a set restriction, not a different model: the same formulation code
builds both, which is what makes the small one evidence about the large one.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"

# Six years and eighteen timeslices - six hours in each of the three seasons. Chosen so
# the model keeps its structure (all 51 technologies, both charging paradigms, storage
# cycling over a full day) while staying small enough to ship and to solve in seconds.
REDUCED_YEARS = [str(y) for y in range(2015, 2021)]
REDUCED_HOURS = [1, 5, 9, 13, 17, 21]
REDUCED_TIMESLICES = [f"{p}{h}" for p in ("W", "SF", "S") for h in REDUCED_HOURS]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--scenario", type=int, default=3,
                    help="which Table 2 scenario to export (default 3, the central case)")
    args = ap.parse_args()

    from sav_osemosys import Instance
    from sav_osemosys.licence import find_licence, gurobi_env
    from sav_osemosys.model import build
    from sav_osemosys.parameters import Scenario
    from sav_osemosys.objective import components

    lic = find_licence()
    print(lic)
    if not lic.usable:
        sys.exit(
            "error: building the reduced instance needs a Gurobi licence.\n"
            "       Set GRB_WLSACCESSID / GRB_WLSSECRET / GRB_LICENSEID, or just use\n"
            "       the artifacts/ files already committed to this repository - they\n"
            "       are the output of this script."
        )
    env = gurobi_env()

    import csv as _csv
    text = "\n".join(l for l in (ROOT / "scenarios" / "table2.csv").read_text().splitlines()
                     if not l.startswith("#"))
    row = {int(r["scenario"]): r for r in _csv.DictReader(text.splitlines())}[args.scenario]
    scenario = Scenario(args.scenario, row["sav"], row["tax"], row["charging"],
                        row["dm"] if row["dm"] == "n/a" else float(row["dm"]))

    print(f"building {scenario.label()}")
    print(f"  reduced to {len(REDUCED_YEARS)} years x {len(REDUCED_TIMESLICES)} timeslices")
    b = build(Instance(), scenario, years=REDUCED_YEARS,
              timeslices=REDUCED_TIMESLICES, env=env)
    b.model.Params.OutputFlag = 0
    print(f"  {b.size()}")

    b.model.optimize()
    if b.model.Status != 2:
        print(f"error: reduced instance returned status {b.model.Status}", file=sys.stderr)
        return 1

    ARTIFACTS.mkdir(exist_ok=True)
    stem = f"reduced-scenario-{args.scenario:02d}"
    # Gzipped: Gurobi compresses when the name ends .gz, and it takes the pair from
    # 25.7 MB to 1.7 MB. The notebooks decompress to a temp file, which is three lines
    # and explicit, rather than committing 26 MB of text nobody reads by eye.
    b.model.write(str(ARTIFACTS / f"{stem}.mps.gz"))
    b.model.write(str(ARTIFACTS / f"{stem}.sol.gz"))

    scale = max(abs(b.model.MaxCoeff), 1.0)
    meta = {
        "scenario": args.scenario,
        "levers": {k: row[k] for k in ("sav", "tax", "charging", "dm")},
        "years": REDUCED_YEARS,
        "timeslices": REDUCED_TIMESLICES,
        "variables": b.model.NumVars,
        "constraints": b.model.NumConstrs,
        "nonzeros": b.model.NumNZs,
        "objective": b.model.ObjVal,
        "components": components(b),
        "max_violation_absolute": b.model.MaxVio,
        "max_violation_relative": b.model.MaxVio / scale,
        "built_with": "gurobipy",
        "note": ("A reduced instance, NOT the published result. The published scenarios "
                 "use 36 years and 72 timeslices; see results/clean/."),
    }
    (ARTIFACTS / f"{stem}.json").write_text(json.dumps(meta, indent=2) + "\n",
                                            encoding="utf-8", newline="\n")

    print(f"  objective {b.model.ObjVal:,.6f}")
    print(f"  primal residual {b.model.MaxVio:.2e} absolute, "
          f"{b.model.MaxVio / scale:.2e} relative\n")
    for name in (f"{stem}.mps.gz", f"{stem}.sol.gz", f"{stem}.json"):
        print(f"  {name:<32}{(ARTIFACTS / name).stat().st_size:>12,} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

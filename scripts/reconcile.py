#!/usr/bin/env python
"""Reconcile the gurobipy port against GAMS, scenario by scenario.

    python scripts/reconcile.py             # every scenario with a GAMS result
    python scripts/reconcile.py --only 3

Two independent implementations of one model must agree on the objective. They will NOT
agree on every variable, and that is expected rather than a failure: this LP is
degenerate, so cost and totals are reproducible while dispatch and build timing are not.
The objective is the invariant; that is what this asserts.

GAMS objectives are read from the GDX at full precision. Do NOT read them from the
results CSV - that writer prints two decimals, which is enough to make a real
disagreement invisible and enough to manufacture a fake one.

Needs GAMS results (scripts/run_scenarios.py) and a Gurobi licence.
"""
from __future__ import annotations

import argparse
import csv
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
GRID = ROOT / "scenarios" / "table2.csv"
DEFAULT_GDXDUMP = r"C:\GAMS\42\gdxdump.exe"

# The objective must match to solver tolerance. Both sides solve the same LP to
# optimality, so anything above this is a formulation difference, not arithmetic.
OBJECTIVE_TOLERANCE = 1e-6

# OPTIMAL is a status, not a feasibility guarantee. Gurobi can return status 2 with a
# primal residual far above its own promised tolerance, and the status word will not say
# so - reported by the FEWS session, which found status 2 alongside MaxVio 2.06e-03
# against a promised 1e-06. So read the residual, not the word.
#
# The bound is RELATIVE to the model's largest coefficient. An absolute tolerance is
# wrong for a model whose matrix spans [1e-06, 1e+06]: the same session gated on one and
# rejected 87 of 91 solves whose relative violation was 4e-10.
MAX_RELATIVE_VIOLATION = 1e-9


def find_gdxdump(explicit: str | None) -> str | None:
    for cand in (explicit, os.environ.get("GDXDUMP"), shutil.which("gdxdump"), DEFAULT_GDXDUMP):
        if cand and Path(cand).is_file():
            return str(Path(cand))
    return None


def gams_objective(gdxdump: str, scenario: int) -> float | None:
    """Read z from the GDX at full precision."""
    gdx = RESULTS / f"scenario-{scenario:02d}" / f"scenario-{scenario:02d}.gdx"
    if not gdx.is_file():
        return None
    proc = subprocess.run([gdxdump, str(gdx), "symb=z", "format=csv"],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        print(f"  gdxdump failed for scenario {scenario}:\n{proc.stdout}\n{proc.stderr}",
              file=sys.stderr)
        return None
    for line in proc.stdout.splitlines():
        line = line.strip().strip('"')
        try:
            return float(line)
        except ValueError:
            continue
    return None


def read_grid() -> dict[int, dict[str, str]]:
    text = "\n".join(l for l in GRID.read_text().splitlines() if not l.startswith("#"))
    return {int(r["scenario"]): r for r in csv.DictReader(text.splitlines())}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", help="comma-separated scenario numbers")
    ap.add_argument("--gdxdump", help="path to gdxdump.exe")
    args = ap.parse_args()

    from sav_osemosys import Instance
    from sav_osemosys.licence import find_licence, gurobi_env
    from sav_osemosys.model import build
    from sav_osemosys.parameters import Scenario

    lic = find_licence()
    print(lic)
    if not lic.usable:
        sys.exit(
            "error: this needs a Gurobi licence that can build the full model.\n"
            "       Set GRB_WLSACCESSID / GRB_WLSSECRET / GRB_LICENSEID for a Web\n"
            "       License Service licence, or run notebooks/01_model.ipynb, which\n"
            "       solves a reduced instance with HiGHS and needs no licence at all."
        )
    env = gurobi_env()

    gdxdump = find_gdxdump(args.gdxdump)
    if gdxdump is None:
        sys.exit("error: could not find gdxdump.exe. Pass --gdxdump or set GDXDUMP.")

    grid = read_grid()
    wanted = ({int(s) for s in args.only.split(",")} if args.only else set(grid))
    inst = Instance()

    print(f"{'#':>2}  {'scenario':<34}{'gurobipy':>16}{'GAMS':>16}{'relative':>12}  ok")
    print("-" * 84)

    failures, compared, skipped = [], 0, []
    for n in sorted(wanted):
        row = grid[n]
        expected = gams_objective(gdxdump, n)
        if expected is None:
            skipped.append(n)
            continue

        scenario = Scenario(n, row["sav"], row["tax"], row["charging"],
                            row["dm"] if row["dm"] == "n/a" else float(row["dm"]))
        started = time.time()
        b = build(inst, scenario, env=env)
        b.model.Params.OutputFlag = 0
        b.model.optimize()
        elapsed = time.time() - started

        if b.model.Status != 2:
            failures.append(f"scenario {n}: gurobipy returned status {b.model.Status}")
            print(f"{n:>2}  {scenario.label()[:34]:<34}{'-':>16}{expected:>16,.4f}"
                  f"{'-':>12}  SOLVE FAILED")
            b.model.dispose()
            continue

        got = b.model.ObjVal
        rel = abs(got - expected) / max(abs(expected), 1.0)

        # Feasibility, read rather than assumed. Scaled by the largest matrix
        # coefficient so the tolerance means the same thing across a badly scaled model.
        # Scale by the largest CONSTRAINT-MATRIX coefficient, not by MaxRHS. MaxRHS
        # here is 1e9, the "no emissions cap" sentinel, and letting an arbitrary
        # sentinel set the yardstick would loosen the gate by three orders of magnitude
        # for reasons that have nothing to do with the solve.
        scale = max(abs(b.model.MaxCoeff), 1.0)
        violation = b.model.MaxVio / scale
        feasible = violation <= MAX_RELATIVE_VIOLATION

        ok = rel <= OBJECTIVE_TOLERANCE and feasible
        compared += 1
        if rel > OBJECTIVE_TOLERANCE:
            failures.append(f"scenario {n}: gurobipy {got!r} vs GAMS {expected!r} "
                            f"(relative {rel:.2e})")
        if not feasible:
            failures.append(f"scenario {n}: reported OPTIMAL but MaxVio is "
                            f"{b.model.MaxVio:.3e} ({violation:.3e} relative to a "
                            f"largest coefficient of {scale:.3e})")
        label = f"sav={row['sav']} tax={row['tax']} chg={row['charging']} dm={row['dm']}"
        print(f"{n:>2}  {label:<34}{got:>16,.4f}{expected:>16,.4f}{rel:>12.2e}"
              f"  {'OK' if ok else 'MISMATCH'}   vio {violation:.1e}  ({elapsed/60:.1f} min)")
        b.model.dispose()

    print()
    if skipped:
        print(f"skipped {len(skipped)} scenario(s) with no GAMS result: "
              f"{', '.join(str(s) for s in skipped)}")
    if failures:
        print(f"\nRECONCILIATION FAILED ({len(failures)}):", file=sys.stderr)
        for f in failures:
            print(f"  {f}", file=sys.stderr)
        return 1
    if compared == 0:
        print("nothing compared - run scripts/run_scenarios.py first")
        return 1
    print(f"all {compared} scenario(s) agree to within {OBJECTIVE_TOLERANCE:.0e} relative")
    return 0


if __name__ == "__main__":
    sys.exit(main())

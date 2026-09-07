#!/usr/bin/env python
"""Run the ten Table 2 scenarios of Jones and Leibowicz (2019).

    python scripts/run_scenarios.py                 # all ten
    python scripts/run_scenarios.py --only 2        # one, by scenario number
    python scripts/run_scenarios.py --only 2,3,8    # a subset
    python scripts/run_scenarios.py --compile-only  # syntax check, no solve
    python scripts/run_scenarios.py --dry-run       # print the commands only

The grid is scenarios/table2.csv. This script does not know what a scenario is; it
reads a row, hands the four levers to model/osemosys_scenario.gms, and checks the
result. Adding a case is an edit to the CSV.

Each scenario gets its own directory under results/, holding the results CSV, the
GDX, the GAMS listing and the log. Scenarios are independent, so an interrupted run
is resumed by re-running with --only for whatever is missing.

solprint is off in the driver. Do not turn it on: over 17.6M variables the listing
passed 4.7 GB and was still growing.
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
GRID = ROOT / "scenarios" / "table2.csv"
NOSAV = ROOT / "scenarios" / "no-sav-vmt.csv"
MODEL = ROOT / "model" / "osemosys_scenario.gms"
RESULTS = ROOT / "results"

DEFAULT_GAMS = r"C:\GAMS\42\gams.exe"

VALID_SAV = {"70", "none"}
VALID_TAX = {"yes", "no"}
VALID_CHARGING = {"optimized", "night", "n/a"}


def find_gams(explicit: str | None) -> str:
    """Locate the GAMS executable. It is not on PATH on the machine this was built on."""
    for candidate in (explicit, os.environ.get("GAMS_EXE"), shutil.which("gams"), DEFAULT_GAMS):
        if candidate and Path(candidate).is_file():
            return str(Path(candidate))
    sys.exit(
        "error: could not find gams.exe. Pass --gams <path> or set GAMS_EXE.\n"
        f"       tried: {DEFAULT_GAMS}"
    )


def read_grid() -> list[dict[str, str]]:
    """Read scenarios/table2.csv, skipping its comment header, and validate every row."""
    text = "\n".join(
        line for line in GRID.read_text().splitlines() if not line.startswith("#")
    )
    rows = list(csv.DictReader(text.splitlines()))
    if not rows:
        sys.exit(f"error: {GRID} defines no scenarios")

    for row in rows:
        sid = row["scenario"]
        if row["sav"] not in VALID_SAV:
            sys.exit(f"error: scenario {sid}: sav={row['sav']!r} not in {sorted(VALID_SAV)}")
        if row["tax"] not in VALID_TAX:
            sys.exit(f"error: scenario {sid}: tax={row['tax']!r} not in {sorted(VALID_TAX)}")
        if row["charging"] not in VALID_CHARGING:
            sys.exit(f"error: scenario {sid}: charging={row['charging']!r} "
                     f"not in {sorted(VALID_CHARGING)}")
        # "n/a" is only meaningful where there is no fleet for it to describe.
        for field in ("charging", "dm"):
            if row[field] == "n/a" and row["sav"] != "none":
                sys.exit(f"error: scenario {sid}: {field}=n/a but sav={row['sav']!r}; "
                         f"n/a is only valid when there is no SAV fleet")
        if row["dm"] != "n/a":
            float(row["dm"])
    return rows


def levers(row: dict[str, str]) -> dict[str, str]:
    """Translate one grid row into the driver's command-line levers.

    Where the paper writes n/a there is no SAV fleet, so FMT is zero and neither the
    charging paradigm nor the multiplier can affect anything. read_grid has already
    checked that. Inert values are passed so the driver needs no special case, and
    check_results.py verifies the fleet really is absent.
    """
    return {
        "SCENARIO": row["scenario"],
        "SAV": row["sav"],
        "TAX": row["tax"],
        "CHARGING": "optimized" if row["charging"] == "n/a" else row["charging"],
        "DM": "1" if row["dm"] == "n/a" else row["dm"],
    }


def run_one(gams: str, row: dict[str, str], compile_only: bool, dry_run: bool,
            solver: str = "cplex") -> bool:
    sid = row["scenario"]
    workdir = RESULTS / f"scenario-{int(sid):02d}"
    workdir.mkdir(parents=True, exist_ok=True)

    lv = levers(row)
    cmd = [
        gams, str(MODEL),
        f"IDir={ROOT / 'model'}",
        f"--NOSAVCSV={NOSAV}",
        f"--RESULTSFILE={workdir / f'scenario-{int(sid):02d}.csv'}",
        f"--GDXFILE={workdir / f'scenario-{int(sid):02d}.gdx'}",
        f"--LEVERSFILE={workdir / 'levers.csv'}",
        f"--SOLVER={solver}",
        "o=" + str(workdir / "run.lst"),
        "lo=2", "lf=" + str(workdir / "run.log"),
    ] + [f"--{k}={v}" for k, v in lv.items()]
    if compile_only:
        cmd.append("a=c")

    label = (f"scenario {sid:>2}  sav={row['sav']:<4} tax={row['tax']:<3} "
             f"charging={row['charging']:<9} dm={row['dm']}")
    if dry_run:
        print(f"{label}\n    {' '.join(cmd)}")
        return True

    print(f"{label} ... ", end="", flush=True)
    started = time.time()
    proc = subprocess.run(cmd, cwd=workdir, capture_output=True, text=True)
    elapsed = time.time() - started

    if proc.returncode != 0:
        print(f"FAILED (rc={proc.returncode}, {elapsed/60:.1f} min)")
        # Both streams, always. A capture that prints only stdout hides the cause.
        for name, stream in (("stdout", proc.stdout), ("stderr", proc.stderr)):
            if stream.strip():
                print(f"  --- gams {name} ---")
                print("  " + "\n  ".join(stream.strip().splitlines()[-25:]))
        lst = workdir / "run.lst"
        if lst.is_file():
            errs = [ln for ln in lst.read_text(errors="replace").splitlines()
                    if ln.startswith("***")]
            if errs:
                print("  --- listing errors ---")
                print("  " + "\n  ".join(errs[:25]))
        return False

    print(f"ok ({elapsed/60:.1f} min)")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", help="comma-separated scenario numbers")
    ap.add_argument("--gams", help="path to gams.exe")
    ap.add_argument("--solver", default="cplex",
                    help="LP solver (default cplex; highs ships with GAMS, no licence)")
    ap.add_argument("--compile-only", action="store_true",
                    help="compile the driver without solving")
    ap.add_argument("--dry-run", action="store_true", help="print commands, run nothing")
    args = ap.parse_args()

    gams = find_gams(args.gams)
    rows = read_grid()

    if args.only:
        wanted = {s.strip() for s in args.only.split(",")}
        unknown = wanted - {r["scenario"] for r in rows}
        if unknown:
            sys.exit(f"error: no such scenario(s): {', '.join(sorted(unknown))}")
        rows = [r for r in rows if r["scenario"] in wanted]

    if not args.dry_run:
        print(f"gams:   {gams}")
        print(f"grid:   {GRID.relative_to(ROOT)} ({len(rows)} scenario(s) selected)")
        print()

    started = time.time()
    failed = [r["scenario"] for r in rows
              if not run_one(gams, r, args.compile_only, args.dry_run, args.solver)]

    if args.dry_run:
        return 0
    print(f"\ntotal {(time.time() - started)/60:.1f} min")
    if failed:
        print(f"FAILED: scenario(s) {', '.join(failed)}")
        print(f"re-run with: python scripts/run_scenarios.py --only {','.join(failed)}")
        return 1
    print(f"all {len(rows)} scenario(s) solved -> {RESULTS.relative_to(ROOT)}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python
"""Check the scenario runs and print the Table 2 grid with what each case produced.

    python scripts/check_results.py            # every scenario that has results
    python scripts/check_results.py --only 2,8

Three things happen here, in order of what they are worth:

1. The levers are confirmed FROM THE OUTPUTS. Each run records what its levers
   actually did (results/scenario-NN/levers.csv); this re-derives what they should
   have been from scenarios/table2.csv and compares. Ten scenarios that were quietly
   the same scenario would all solve and all report success, so "the run succeeded"
   is not evidence that the grid was applied.

2. The acceptance test. The paper states two electricity-mix figures, which are the
   only published numbers this model can be checked against - it prints no costs.
   Natural gas is 80% of generation in 2035 without a carbon tax, and peaks at 56%
   in 2021 with one. The denominator is generation only: storage, V2G and charging
   also produce ELC and are excluded.

3. The grid itself: objective value and gas share per scenario.
"""
from __future__ import annotations

import argparse
import csv
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
GRID = ROOT / "scenarios" / "table2.csv"
RESULTS = ROOT / "results"

YEARS = [str(y) for y in range(2015, 2051)]

# ELC-producing technologies that are generation. BATTERY, EV_CHARGE, V2G,
# EV_DISCHARGE, EV_CHARGE_F, V2G_F and EV_DISCHARGE_F also carry an
# OutputActivityRatio to ELC but move electricity rather than making it.
GENERATION = ["COALPP", "CCPP", "CTPP", "NUCPP", "HYDROPP", "WINDPP", "SOLPP",
              "BIOPP", "CCCCSPP", "IGCCCCSPP", "H2FUELCELL"]
GAS = ["CCPP", "CTPP", "CCCCSPP"]

# The demand endpoints the levers are checked against, read off the model's own
# SpecifiedAnnualDemand table. scripts/extract_no_sav_row.py regenerates the third.
VMT_2050_SAV = 4259.69675
FMT_2050_BASE = 9707.77499
VMT_2050_NO_SAV = 13967.47174


def read_grid() -> dict[str, dict[str, str]]:
    text = "\n".join(l for l in GRID.read_text().splitlines() if not l.startswith("#"))
    return {r["scenario"]: r for r in csv.DictReader(text.splitlines())}


def read_results(path: pathlib.Path) -> tuple[dict, float | None]:
    """Parse a results CSV into {(section, ...labels): [values]} plus the objective.

    The number of leading label fields varies by section, so split on the first field
    that parses as a number - see the note in validate.py, where assuming three
    silently dropped 19% of the data.
    """
    rows: dict[tuple[str, ...], list[float]] = {}
    objective = None
    for line in path.read_text(errors="replace").splitlines():
        parts = [p.strip().strip('"') for p in line.split(",")]
        if parts and parts[0] == "Objective Value" and len(parts) > 1:
            objective = float(parts[1])
            continue
        k = 0
        while k < len(parts):
            try:
                float(parts[k])
                break
            except ValueError:
                k += 1
        if k == 0 or k >= len(parts):
            continue
        try:
            rows[tuple(parts[:k])] = [float(p) for p in parts[k:] if p.strip()]
        except ValueError:
            continue
    return rows, objective


def gas_share(rows: dict) -> list[float]:
    gen = {t: rows.get(("AnnualGenerationByTechnology", "ATX", t, "ELC"), [0.0] * 36)
           for t in GENERATION}
    out = []
    for i in range(36):
        total = sum(g[i] for g in gen.values() if i < len(g))
        gas = sum(gen[t][i] for t in GAS if i < len(gen[t]))
        out.append(100.0 * gas / total if total else 0.0)
    return out


def read_levers(path: pathlib.Path) -> dict[str, str]:
    out = {}
    for line in path.read_text(errors="replace").splitlines()[1:]:
        parts = [p.strip().strip('"') for p in line.split(",")]
        if len(parts) >= 2:
            out[parts[0]] = parts[1]
    return out


def close(got: float, want: float, rel: float = 1e-6) -> bool:
    return abs(got - want) <= rel * abs(want)


def check_levers(row: dict[str, str], lv: dict[str, str]) -> list[str]:
    """Re-derive what the levers should have done, compare against what they did."""
    problems = []

    tax = float(lv["tax_2015"])
    if row["tax"] == "yes":
        if not close(tax, 20.0):
            problems.append(f"tax requested but EmissionsPenalty(2015)={tax}, expected 20")
        want = 20.0 * 1.05 ** 35
        got = float(lv["tax_2050"])
        if not close(got, want):
            problems.append(f"tax in 2050 is {got:.4f}, expected {want:.4f} (20 x 1.05^35)")
    elif tax != 0.0:
        problems.append(f"no tax requested but EmissionsPenalty(2015)={tax}")

    vmt, fmt = float(lv["vmt_2050"]), float(lv["fmt_2050"])
    if row["sav"] == "none":
        if fmt != 0.0:
            problems.append(f"no SAV fleet requested but FMT(2050)={fmt}")
        if not close(vmt, VMT_2050_NO_SAV):
            problems.append(f"no-SAV VMT(2050)={vmt}, expected undivided {VMT_2050_NO_SAV}")
    else:
        want = float(row["dm"]) * FMT_2050_BASE
        if not close(fmt, want):
            problems.append(f"FMT(2050)={fmt}, expected dm x base = {want:.4f}")
        if not close(vmt, VMT_2050_SAV):
            problems.append(f"SAV-case VMT(2050)={vmt}, expected {VMT_2050_SAV}")

    day = float(lv["charge_factor_day_W12"])
    if row["sav"] != "none":
        if row["charging"] == "night" and day != 0.0:
            problems.append(f"night-only charging requested but daytime factor is {day}")
        if row["charging"] == "optimized" and day == 0.0:
            problems.append("optimized charging requested but daytime factor is zero")

    gap = float(lv["demand_gap"])
    if gap > 1e-3:
        problems.append(f"demand agreement assertion is loose: gap {gap}")
    return problems


FLEET = ["ICE_PET_F", "ICE_DSL_F", "PHEV_F", "HYBRID_F", "H2V_F", "EV_F"]


def check_outputs(row: dict[str, str], rows: dict) -> list[str]:
    """Confirm from the solution that the fleet is present or absent as asked.

    Zeroing FMT demand is what removes the SAV fleet, and nothing forces that to work -
    a lever that quietly failed would still solve. Test NewCapacity, not
    TotalAnnualCapacity: the 2015 column carries inherited stock (180 thousand ICE_PET_F,
    2 thousand EV_F) that exists whatever the scenario says, and the model retires it in
    the first period. What distinguishes the cases is whether anything is BUILT.
    """
    problems = []
    built = {}
    for t in FLEET:
        series = rows.get(("NewCapacity", "ATX", t))
        if series is None:
            problems.append(f"results carry no NewCapacity row for {t}")
            continue
        built[t] = max(series)

    if not built:
        return problems
    total = sum(built.values())
    if row["sav"] == "none":
        if total > 1e-6:
            worst = max(built, key=built.get)
            problems.append(f"no SAV fleet requested but fleet capacity was built "
                            f"(largest: {worst} at {built[worst]:g})")
    elif total <= 1e-6:
        problems.append("SAV diffusion requested but no fleet capacity was ever built")
    return problems


def check_invariants(found: dict) -> list[str]:
    """Two orderings that must hold for reasons of optimisation, not of energy policy.

    Both compare scenarios that differ in exactly one lever, so a violation means the
    solve or the lever is wrong rather than that the model has said something surprising.

    1. Taxing emissions cannot lower total cost. The objective is cost plus emissions
       penalty; the penalty is non-negative, so min(C + T) >= min(C) over the same
       feasible set.
    2. Night-only charging cannot be cheaper than optimized. It is the same model with
       a subset of the charging hours available, so its optimum cannot beat the
       unrestricted one.

    These are the invariants worth asserting. That no-SAV costs more than SAV is a
    RESULT, not a theorem - the two have different demand structures - so it is
    reported and not asserted.
    """
    problems = []
    by_config = {}
    for sid, (row, objective, _) in found.items():
        if objective is not None:
            by_config[(row["sav"], row["tax"], row["charging"], row["dm"])] = (sid, objective)

    for (sav, tax, chg, dm), (sid, obj) in by_config.items():
        if tax == "yes":
            twin = by_config.get((sav, "no", chg, dm))
            if twin and obj < twin[1] - 1e-6:
                problems.append(f"scenario {sid} ({obj:,.2f}) is cheaper than untaxed "
                                f"scenario {twin[0]} ({twin[1]:,.2f}); a carbon tax "
                                f"cannot reduce total cost")
        if chg == "night":
            twin = by_config.get((sav, tax, "optimized", dm))
            if twin and obj < twin[1] - 1e-6:
                problems.append(f"scenario {sid} ({obj:,.2f}) is cheaper than "
                                f"optimized-charging scenario {twin[0]} ({twin[1]:,.2f}); "
                                f"restricting charging hours cannot reduce cost")
    return problems


def check_readme(found: dict) -> list[str]:
    """Every number in the README's scenario table must come from these runs.

    The table was transcribed once by hand and will decay silently: a lever changes, the
    grid is re-solved, and ten stale figures sit in the prose with nothing complaining.
    Only rows for scenarios actually present in results/ are checked.
    """
    readme = ROOT / "README.md"
    if not readme.is_file():
        return ["README.md is missing"]

    problems, checked = [], 0
    for line in readme.read_text(encoding="utf-8").splitlines():
        if not line.startswith("| ") or "|" not in line[2:]:
            continue
        cells = [c.strip().replace("**", "") for c in line.strip().strip("|").split("|")]
        if len(cells) != 9 or not cells[0].isdigit():
            continue
        sid = cells[0]
        if sid not in found:
            continue
        checked += 1
        _, objective, share = found[sid]
        pk = max(range(36), key=lambda i: share[i])
        want = [f"{objective:,.2f}", f"{share[20]:.1f}%", f"{share[pk]:.1f}%", YEARS[pk]]
        for label, got, exp in zip(("objective", "gas 2035", "gas peak", "peak year"),
                                   cells[5:9], want):
            if got != exp:
                problems.append(f"README scenario {sid}: {label} reads {got!r}, "
                                f"the run gives {exp!r}")
    if checked == 0:
        problems.append("no README scenario rows matched the available results; "
                        "the table may have been reformatted and is no longer checked")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", help="comma-separated scenario numbers")
    args = ap.parse_args()

    grid = read_grid()
    wanted = {s.strip() for s in args.only.split(",")} if args.only else set(grid)
    unknown = wanted - set(grid)
    if unknown:
        sys.exit(f"error: no such scenario(s): {', '.join(sorted(unknown))}")

    found, problems = {}, []
    for sid in sorted(wanted, key=int):
        d = RESULTS / f"scenario-{int(sid):02d}"
        rcsv, lcsv = d / f"scenario-{int(sid):02d}.csv", d / "levers.csv"
        if not rcsv.is_file() or not lcsv.is_file():
            continue
        rows, objective = read_results(rcsv)
        lv = read_levers(lcsv)
        problems += [f"scenario {sid}: {p}" for p in check_levers(grid[sid], lv)]
        problems += [f"scenario {sid}: {p}" for p in check_outputs(grid[sid], rows)]
        if objective is None:
            problems.append(f"scenario {sid}: results CSV carries no objective value")
        found[sid] = (grid[sid], objective, gas_share(rows))

    if not found:
        print("no scenario results found under results/ - run scripts/run_scenarios.py")
        return 1

    missing = sorted(wanted - set(found), key=int)
    print(f"{len(found)} of {len(wanted)} selected scenario(s) have results"
          + (f"; missing {', '.join(missing)}" if missing else ""))
    print()

    print("Table 2 - as run")
    print(f"{'#':>2}  {'SAV':<5} {'tax':<4} {'charging':<10} {'dm':>4}  "
          f"{'objective':>13}  {'gas 2035':>9}  {'gas peak':>9}  {'year':>5}")
    print("-" * 82)
    for sid in sorted(found, key=int):
        row, objective, share = found[sid]
        pk = max(range(36), key=lambda i: share[i])
        obj = f"{objective:,.4f}" if objective is not None else "-"
        print(f"{sid:>2}  {row['sav']:<5} {row['tax']:<4} {row['charging']:<10} "
              f"{row['dm']:>4}  {obj:>13}  {share[20]:8.1f}%  {share[pk]:8.1f}%  "
              f"{YEARS[pk]:>5}")

    print()
    print("Acceptance test - the paper's two published electricity-mix figures")
    print("  no tax: natural gas is 80% of generation in 2035")
    print("  tax:    natural gas peaks at 56%, in 2021")
    print()
    for sid in sorted(found, key=int):
        row, _, share = found[sid]
        if row["sav"] == "none":
            continue
        pk = max(range(36), key=lambda i: share[i])
        if row["tax"] == "no":
            print(f"  scenario {sid:>2} (no tax, dm={row['dm']:>3}, {row['charging']:<9}): "
                  f"2035 = {share[20]:5.1f}%  vs 80%   [off by {share[20] - 80:+5.1f}]")
        else:
            print(f"  scenario {sid:>2} (tax,    dm={row['dm']:>3}, {row['charging']:<9}): "
                  f"peak = {share[pk]:5.1f}% in {YEARS[pk]}  vs 56% in 2021  "
                  f"[off by {share[pk] - 56:+5.1f}, {int(YEARS[pk]) - 2021:+d} yr]")

    problems += check_invariants(found)
    if not args.only:
        problems += check_readme(found)

    if problems:
        print()
        print("CHECK FAILED - the grid was not applied as the config asks:",
              file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        return 1
    print()
    print(f"checks: ok - all {len(found)} scenario(s) applied the grid as configured,")
    print("        and the tax and charging cost orderings hold")
    return 0


if __name__ == "__main__":
    sys.exit(main())

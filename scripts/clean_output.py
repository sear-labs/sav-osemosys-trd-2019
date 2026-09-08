#!/usr/bin/env python
"""Turn the raw GAMS results into tidy CSVs that anything can read.

    python scripts/clean_output.py

The GAMS report writer emits a wide, ragged file: a section label, then a VARYING number
of index columns, then 36 or 24 unheaded values. Nothing about it says how many labels a
row carries - `AnnualGenerationByTechnology` and `AnnualEmissions` carry four, everything
else carries three. Assuming three silently dropped 2,701 of 14,149 cells, 19% of a
comparison, and reported success.

That format is the reason this script exists. `results/clean/` is long-format, one value
per row, with named columns, and it is what the notebooks and figures read. Nothing
downstream re-parses the ragged file.

Three outputs, because the raw file holds three different shapes:

    annual.csv      scenario, quantity, region, technology, item, year, value
    timeslice.csv   scenario, quantity, region, technology, year, season, timeslice, value
    objective.csv   scenario, objective

`item` is the fuel for generation rows and the emission for emissions rows, and empty
otherwise - one column rather than two mostly-empty ones.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
CLEAN = RESULTS / "clean"

YEARS = [str(y) for y in range(2015, 2051)]

# Sections whose four-label rows carry an extra index. Everything else has three.
FOUR_LABEL = {"AnnualGenerationByTechnology", "AnnualEmissions"}

# "Year 2020 Electricity Production - WINTER" -> quantity, year, season
TIMESLICE_SECTION = re.compile(
    r"^Year (?P<year>\d{4}) (?P<quantity>.+?) - (?P<season>WINTER|INTERMEDIATE|SUMMER)$")

SEASON_PREFIX = {"WINTER": "W", "INTERMEDIATE": "SF", "SUMMER": "S"}


def split_row(parts: list[str]) -> tuple[list[str], list[float]] | None:
    """Split a raw row into labels and values on the first field that parses as a number.

    Never assume a label count. See the module docstring for what that costs.
    """
    k = 0
    while k < len(parts):
        try:
            float(parts[k])
            break
        except ValueError:
            k += 1
    if k == 0 or k >= len(parts):
        return None
    try:
        return parts[:k], [float(x) for x in parts[k:] if x.strip()]
    except ValueError:
        return None


def read_raw(path: Path):
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = [p.strip().strip('"') for p in line.split(",")]
        split = split_row(parts)
        if split:
            yield split


def clean_one(scenario: int, path: Path, annual, timeslice, objective) -> dict[str, int]:
    counts = {"annual": 0, "timeslice": 0, "objective": 0, "unrecognised": 0}
    for labels, values in read_raw(path):
        section = labels[0]

        if section == "Objective Value":
            objective.append({"scenario": scenario, "objective": values[0]})
            counts["objective"] += 1
            continue

        ts = TIMESLICE_SECTION.match(section)
        if ts:
            season = ts.group("season")
            prefix = SEASON_PREFIX[season]
            region = labels[1] if len(labels) > 1 else ""
            tech = labels[2] if len(labels) > 2 else ""
            for hour, value in enumerate(values, start=1):
                timeslice.append({
                    "scenario": scenario, "quantity": ts.group("quantity"),
                    "region": region, "technology": tech, "year": ts.group("year"),
                    "season": season, "timeslice": f"{prefix}{hour}", "value": value,
                })
                counts["timeslice"] += 1
            continue

        if len(values) == len(YEARS):
            region = labels[1] if len(labels) > 1 else ""
            if section in FOUR_LABEL and len(labels) >= 4:
                # AnnualEmissions is <name>,<region>,<emission>,<technology>;
                # AnnualGenerationByTechnology is <name>,<region>,<technology>,<fuel>.
                if section == "AnnualEmissions":
                    item, tech = labels[2], labels[3]
                else:
                    tech, item = labels[2], labels[3]
            else:
                tech = labels[2] if len(labels) > 2 else ""
                item = ""
            for year, value in zip(YEARS, values):
                annual.append({
                    "scenario": scenario, "quantity": section, "region": region,
                    "technology": tech, "item": item, "year": year, "value": value,
                })
                counts["annual"] += 1
            continue

        counts["unrecognised"] += 1
    return counts


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", help="comma-separated scenario numbers")
    args = ap.parse_args()

    wanted = ({int(s) for s in args.only.split(",")} if args.only
              else set(range(1, 11)))

    annual, timeslice, objective = [], [], []
    found, unrecognised = [], 0
    for n in sorted(wanted):
        path = RESULTS / f"scenario-{n:02d}" / f"scenario-{n:02d}.csv"
        if not path.is_file():
            continue
        counts = clean_one(n, path, annual, timeslice, objective)
        unrecognised += counts["unrecognised"]
        found.append(n)
        print(f"  scenario {n:>2}: {counts['annual']:>6,} annual, "
              f"{counts['timeslice']:>6,} timeslice, {counts['objective']} objective"
              + (f"  ({counts['unrecognised']} UNRECOGNISED)" if counts["unrecognised"] else ""))

    if not found:
        print("no raw results found - run scripts/run_scenarios.py first", file=sys.stderr)
        return 1

    write_csv(CLEAN / "annual.csv", annual,
              ["scenario", "quantity", "region", "technology", "item", "year", "value"])
    write_csv(CLEAN / "timeslice.csv", timeslice,
              ["scenario", "quantity", "region", "technology", "year", "season",
               "timeslice", "value"])
    write_csv(CLEAN / "objective.csv", objective, ["scenario", "objective"])

    total = len(annual) + len(timeslice) + len(objective)
    print(f"\n{len(found)} scenario(s) -> {CLEAN.relative_to(ROOT)}/  ({total:,} rows)")
    for name in ("annual.csv", "timeslice.csv", "objective.csv"):
        size = (CLEAN / name).stat().st_size
        print(f"  {name:<16}{size:>12,} bytes")
    if unrecognised:
        print(f"\nWARNING: {unrecognised} row(s) matched no known shape and were dropped",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

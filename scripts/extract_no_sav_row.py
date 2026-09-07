#!/usr/bin/env python
"""Regenerate scenarios/no-sav-vmt.csv from the model's own data file.

    python scripts/extract_no_sav_row.py

The no-SAV travel demand is not a live parameter. It sits in
model/ATX_Integrated_Final_Fleet.gms as a commented-out row of the
SpecifiedAnnualDemand table:

    ATX.VMT    9500.85 ...      <- the SAV case, private miles only
   *ATX.VMT   10641.81 ...      <- the same demand undivided, no SAV fleet

Transcribing 36 numbers by hand is exactly the kind of edit that produces a
plausible wrong answer, so the CSV is generated rather than typed, and the driver
asserts at run time that VMT + FMT equals it in every year.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "model" / "ATX_Integrated_Final_Fleet.gms"
OUT = ROOT / "scenarios" / "no-sav-vmt.csv"


def main() -> int:
    lines = DATA.read_text(errors="replace").splitlines()

    years, nosav = None, None
    for line in lines:
        stripped = line.strip()
        if years is None and stripped.startswith("2015 ") and "2050" in stripped:
            years = stripped.split()
        if stripped.startswith("*ATX.VMT"):
            if nosav is not None:
                print("error: more than one commented ATX.VMT row", file=sys.stderr)
                return 1
            nosav = stripped.split()[1:]

    if years is None or nosav is None:
        print("error: could not find the year header or the commented ATX.VMT row",
              file=sys.stderr)
        return 1
    if len(years) != len(nosav):
        print(f"error: {len(years)} years but {len(nosav)} values", file=sys.stderr)
        return 1
    if (years[0], years[-1]) != ("2015", "2050"):
        print(f"error: year header runs {years[0]}..{years[-1]}, expected 2015..2050",
              file=sys.stderr)
        return 1
    for v in nosav:
        float(v)  # raises rather than writing a CSV with a stray label in it

    OUT.write_text(
        "region," + ",".join(years) + "\n" + "ATX," + ",".join(nosav) + "\n",
        newline="\n",
    )
    print(f"wrote {OUT.relative_to(ROOT)}: {len(nosav)} years, "
          f"{years[0]}={nosav[0]} .. {years[-1]}={nosav[-1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

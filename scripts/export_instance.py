#!/usr/bin/env python
"""Export the model's instance data from GAMS into open CSVs.

    python scripts/export_instance.py

The parameters live inline in a 1,889-line GAMS data file, so today reading this
instance at all requires a GAMS licence. That is the real barrier to anyone checking
this work - CPLEX is secondary, because you cannot even *see* the formulation in
runnable form without GAMS.

This writes every set and parameter to data/instance/*.csv, which any reader can open
and which the Python port consumes. It needs GAMS once; after that the CSVs are the
instance and are committed.

Two things it does NOT do:

  - it does not modify the GAMS files. It includes the data file and unloads what that
    file built, so the CSVs are what the model actually uses, not a transcription.
  - it does not undo the data file's `scalar DM`, which has already multiplied FMT by
    the time control reaches the unload. The Python port recovers the base row exactly
    as model/osemosys_scenario.gms does, so both start from the same numbers.
"""
from __future__ import annotations

import argparse
import csv
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "model"
OUT = ROOT / "data" / "instance"
GDX = ROOT / "data" / "atx_instance.gdx"

DEFAULT_GAMS = r"C:\GAMS\42\gams.exe"

# Solution variables are unloaded empty because nothing is solved here; only sets and
# parameters carry the instance.
WANTED_TYPES = {"Set", "Par"}


def find_tool(name: str, explicit: str | None = None) -> str:
    for cand in (explicit, os.environ.get("GAMS_EXE") if name == "gams" else None,
                 shutil.which(name), DEFAULT_GAMS if name == "gams" else None,
                 str(Path(DEFAULT_GAMS).with_name(f"{name}.exe"))):
        if cand and Path(cand).is_file():
            return str(Path(cand))
    sys.exit(f"error: could not find {name}. Pass --gams <path to gams.exe> or set GAMS_EXE.")


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    """Run a command, surfacing BOTH streams on failure - never stdout alone."""
    proc = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if proc.returncode != 0:
        print(f"error: command failed (rc={proc.returncode}): {' '.join(cmd[:3])} ...",
              file=sys.stderr)
        for stream_name, stream in (("stdout", proc.stdout), ("stderr", proc.stderr)):
            if stream.strip():
                print(f"--- {stream_name} ---\n{stream.strip()[-2000:]}", file=sys.stderr)
        sys.exit(1)
    return proc


def list_symbols(gdxdump: str) -> list[tuple[str, str, int]]:
    """Return (name, type, records) for every symbol in the GDX."""
    out = run([gdxdump, str(GDX), "symbols"]).stdout
    symbols = []
    for line in out.splitlines():
        parts = line.split()
        # "  8 AnnualEmissionLimit    3  Par   36  <text>"
        if len(parts) >= 5 and parts[0].rstrip(".").isdigit():
            name, typ = parts[1], parts[3]
            try:
                records = int(parts[4])
            except ValueError:
                continue
            symbols.append((name, typ, records))
    return symbols


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--gams", help="path to gams.exe")
    args = ap.parse_args()

    gams = find_tool("gams", args.gams)
    gdxdump = find_tool("gdxdump")

    GDX.parent.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    print("1. unloading the instance from GAMS ...")
    run([gams, str(MODEL / "export_data.gms"), f"IDir={MODEL}", f"--GDXFILE={GDX}",
         f"o={GDX.with_suffix('.lst')}", "lo=2", f"lf={GDX.with_suffix('.log')}"],
        cwd=GDX.parent)
    print(f"   {GDX.relative_to(ROOT)}  {GDX.stat().st_size:,} bytes")

    symbols = list_symbols(gdxdump)
    if not symbols:
        print("error: no symbols parsed from the GDX; the dump format may have changed",
              file=sys.stderr)
        return 1

    print("2. converting sets and parameters to CSV ...")
    written, skipped, total_rows = [], 0, 0
    for name, typ, records in symbols:
        if typ not in WANTED_TYPES or records == 0:
            skipped += 1
            continue
        text = run([gdxdump, str(GDX), f"symb={name}", "format=csv"]).stdout
        rows = [r for r in csv.reader(text.splitlines()) if r]
        if len(rows) - 1 != records:
            print(f"error: {name} dumped {len(rows) - 1} rows, GDX says {records}",
                  file=sys.stderr)
            return 1
        (OUT / f"{name}.csv").write_text(text.replace("\r\n", "\n"),
                                         encoding="utf-8", newline="\n")
        written.append((name, typ, records))
        total_rows += records

    print(f"   {len(written)} symbols -> {OUT.relative_to(ROOT)}/  "
          f"({total_rows:,} rows; {skipped} empty or non-data symbols skipped)")

    manifest = OUT / "_manifest.csv"
    with manifest.open("w", encoding="utf-8", newline="\n") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["symbol", "kind", "records"])
        w.writerows(sorted(written))
    print(f"   manifest: {manifest.relative_to(ROOT)}")

    biggest = sorted(written, key=lambda r: -r[2])[:5]
    print("\n   largest symbols:")
    for name, _, records in biggest:
        print(f"     {name:<28} {records:>9,} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python
"""Everything that can be checked without a solver.

    python scripts/test_offline.py

Every solve here needs a commercial LP licence, so there is no CI. This is the suite CI
would run: it covers the parts that go wrong silently - a mis-transcribed demand row, a
drifted results writer, a scenario grid that no longer means what it says - and it runs
in under a second.

Comparisons against regenerated files are LINE-based, never byte-based. Git checks these
files out with CRLF on Windows while the generators write LF, so a byte comparison passes
only on the machine where the file was first written - which is the one machine nobody
thinks to check. .gitattributes pins the endings; line-based comparison is the belt to
that pair of braces. Measured 2026-09-06: a clean clone failed two checks for exactly this.

It does NOT check that the model solves, or that the scenarios reproduce the paper.
scripts/run_scenarios.py and scripts/check_results.py do that, and they need GAMS.
"""
from __future__ import annotations

import csv
import io
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]

PASS, FAIL = "ok  ", "FAIL"
failures: list[str] = []


def check(name: str, fn) -> None:
    try:
        detail = fn()
    except AssertionError as exc:
        failures.append(name)
        print(f"{FAIL} {name}\n       {exc}")
    except Exception as exc:  # noqa: BLE001 - a broken check is a failed check
        failures.append(name)
        print(f"{FAIL} {name}\n       unexpected {type(exc).__name__}: {exc}")
    else:
        print(f"{PASS} {name}" + (f" - {detail}" if detail else ""))


# --------------------------------------------------------------------------------
# The no-SAV demand row


def no_sav_row_is_reproducible() -> str:
    """extract_no_sav_row.py must regenerate the committed CSV byte for byte.

    The CSV is 36 numbers lifted out of a commented-out line in a 1,889-line GAMS file.
    If it were hand-edited, nothing downstream would notice: the driver's agreement
    assertion would fail, but only after a four-minute solve had been set up.
    """
    csv_path = ROOT / "scenarios" / "no-sav-vmt.csv"
    before = csv_path.read_text(encoding="utf-8").splitlines()
    proc = subprocess.run([sys.executable, str(ROOT / "scripts" / "extract_no_sav_row.py")],
                          capture_output=True, text=True)
    assert proc.returncode == 0, f"extractor failed:\n{proc.stdout}\n{proc.stderr}"
    after = csv_path.read_text(encoding="utf-8").splitlines()
    assert before == after, "committed no-sav-vmt.csv differs from what the extractor produces"
    return f"{len(after)} lines, regenerated identically"


def demand_split_holds() -> str:
    """VMT + FMT must equal the no-SAV row - the assumption the whole grid rests on.

    This is the same assertion the GAMS driver makes at run time, made here against the
    source so it fails in a second rather than after a solve.
    """
    data = (ROOT / "model" / "ATX_Integrated_Final_Fleet.gms").read_text(errors="replace")
    lines = data.splitlines()

    vmt = fmt = dm = None
    for line in lines:
        s = line.strip()
        if s.startswith("ATX.VMT"):
            vmt = [float(v) for v in s.split()[1:]]
        elif s.startswith("ATX.FMT"):
            fmt = [float(v) for v in s.split()[1:]]
        elif s.startswith("scalar DM"):
            dm = float(s.split("/")[1])
    assert vmt and fmt and dm, f"could not read VMT/FMT/DM (dm={dm})"

    row = next(csv.reader(io.StringIO(
        (ROOT / "scenarios" / "no-sav-vmt.csv").read_text().splitlines()[1])))
    nosav = [float(v) for v in row[1:]]

    assert len(vmt) == len(fmt) == len(nosav) == 36, \
        f"lengths {len(vmt)}/{len(fmt)}/{len(nosav)}, expected 36 each"
    gap = max(abs(v + f - n) for v, f, n in zip(vmt, fmt, nosav))
    assert gap <= 1e-3, f"VMT + FMT departs from the no-SAV row by {gap}"

    share = fmt[-1] / (vmt[-1] + fmt[-1])
    assert 0.65 <= share <= 0.75, f"2050 SAV share is {share:.1%}, not the paper's ~70%"
    return f"max gap {gap:.2e}; 2050 SAV share {share:.1%}; data-file DM={dm:g}"


# --------------------------------------------------------------------------------
# The scenario grid


def grid_matches_table2() -> str:
    """The committed grid must still be the paper's Table 2, all ten rows."""
    sys.path.insert(0, str(ROOT / "scripts"))
    import run_scenarios  # noqa: PLC0415 - validates on import-time read

    rows = run_scenarios.read_grid()
    assert len(rows) == 10, f"{len(rows)} scenarios, expected 10"
    assert [r["scenario"] for r in rows] == [str(i) for i in range(1, 11)], \
        "scenarios are not numbered 1..10 in order"

    expected = {
        "1": ("70", "no", "optimized", "0.5"), "2": ("70", "no", "optimized", "2"),
        "3": ("70", "no", "optimized", "1"), "4": ("70", "no", "night", "1"),
        "5": ("none", "no", "n/a", "n/a"), "6": ("70", "yes", "optimized", "0.5"),
        "7": ("70", "yes", "optimized", "2"), "8": ("70", "yes", "optimized", "1"),
        "9": ("70", "yes", "night", "1"), "10": ("none", "yes", "n/a", "n/a"),
    }
    for r in rows:
        got = (r["sav"], r["tax"], r["charging"], r["dm"])
        assert got == expected[r["scenario"]], \
            f"scenario {r['scenario']} is {got}, Table 2 says {expected[r['scenario']]}"

    tax = sum(r["tax"] == "yes" for r in rows)
    assert tax == 5, f"{tax} taxed scenarios, Table 2 has 5"
    return "10 rows, 5 taxed, 2 no-SAV, matches Table 2"


def na_only_where_there_is_no_fleet() -> str:
    """read_grid must reject n/a on a scenario that HAS a fleet - a guard, watched to fire."""
    sys.path.insert(0, str(ROOT / "scripts"))
    import run_scenarios  # noqa: PLC0415

    good = {"scenario": "x", "sav": "70", "tax": "no", "charging": "n/a", "dm": "1"}
    caught = False
    try:
        # read_grid validates rows; exercise the same rule through it
        original = run_scenarios.GRID.read_text()
        tmp = run_scenarios.GRID.with_suffix(".test.csv")
        tmp.write_text("scenario,sav,tax,charging,dm\n"
                       f"{good['scenario']},{good['sav']},{good['tax']},"
                       f"{good['charging']},{good['dm']}\n")
        run_scenarios.GRID = tmp
        try:
            run_scenarios.read_grid()
        except SystemExit as exc:
            caught = "n/a is only valid when there is no SAV fleet" in str(exc)
        finally:
            run_scenarios.GRID = ROOT / "scenarios" / "table2.csv"
            tmp.unlink(missing_ok=True)
            assert run_scenarios.GRID.read_text() == original, "the real grid was modified"
    finally:
        pass
    assert caught, "a fleet scenario with charging=n/a was accepted; the guard does not fire"
    return "guard fires on charging=n/a with sav=70"


# --------------------------------------------------------------------------------
# The results writers


def writers_agree() -> str:
    proc = subprocess.run([sys.executable, str(ROOT / "scripts" / "check_writers.py")],
                          capture_output=True, text=True)
    assert proc.returncode == 0, f"check_writers.py failed:\n{proc.stdout}\n{proc.stderr}"
    return proc.stdout.strip().splitlines()[-1].strip()


def scenario_writer_is_derived() -> str:
    """Regenerating the scenario writer must be a no-op, or someone hand-edited it."""
    path = ROOT / "model" / "Results_Scenario.gms"
    before = path.read_text(encoding="utf-8", errors="replace").splitlines()
    proc = subprocess.run([sys.executable, str(ROOT / "scripts" / "derive_results_writer.py")],
                          capture_output=True, text=True)
    assert proc.returncode == 0, f"derivation failed:\n{proc.stdout}\n{proc.stderr}"
    after = path.read_text(encoding="utf-8", errors="replace").splitlines()
    assert after == before, \
        "Results_Scenario.gms was hand-edited; regenerate it with derive_results_writer.py"
    return "regenerates identically"


# --------------------------------------------------------------------------------
# The driver


def driver_never_turns_solprint_on() -> str:
    """solprint=on over 17.6M variables wrote 4.7 GB and was still growing.

    Comment lines are stripped first. The driver's own comment explains the trap by
    naming it, and a check that reads comments as code fails on the documentation.
    """
    text = (ROOT / "model" / "osemosys_scenario.gms").read_text(errors="replace")
    code = "\n".join(ln for ln in text.splitlines() if not ln.lstrip().startswith("*"))
    assert "solprint=off" in code, "the driver does not set solprint=off"
    assert "solprint=on" not in code, "the driver sets solprint=on somewhere"
    for gap in ("optcr=0", "optca=0"):
        assert gap in code, f"the driver does not zero {gap.split('=')[0]}"
    return "solprint=off, optcr=0, optca=0"


def driver_keeps_the_agreement_assertion() -> str:
    text = (ROOT / "model" / "osemosys_scenario.gms").read_text(errors="replace")
    for needle in ("demand_gap", "abort$(demand_gap", "abort$(smin((y,r), FleetSize"):
        assert needle in text, f"the driver has lost its guard: {needle!r} is gone"
    return "demand-split and FleetSize guards present"


def shipped_driver_is_untouched() -> str:
    """osemosys_run.gms is the 2018 artifact. The rebuild must not have edited it."""
    proc = subprocess.run(["git", "diff", "--stat", "HEAD", "--", "model/osemosys_run.gms",
                           "model/Results_Baseline.gms", "model/Results_CO2_Policy.gms",
                           "model/ATX_Integrated_Final_Fleet.gms",
                           "model/osemosys_equations.gms"],
                          capture_output=True, text=True, cwd=ROOT)
    assert proc.returncode == 0, f"git diff failed: {proc.stderr}"
    assert not proc.stdout.strip(), \
        f"the 2018 model files have been modified:\n{proc.stdout}"
    return "5 shipped model files unmodified since HEAD"


def exported_instance_agrees_with_the_gams_source() -> str:
    """The demand identity must hold in the exported CSVs too, with no GAMS involved.

    data/instance/ is the model readable without a licence, so it needs its own check
    rather than inheriting trust from the GAMS run that produced it. If the export ever
    drifts from the source - a changed unload, a changed DM - this fails here.
    """
    import csv as _csv
    d = ROOT / "data" / "instance"
    if not d.is_dir():
        raise AssertionError("data/instance/ is missing; run scripts/export_instance.py")

    def load(name):
        with (d / f"{name}.csv").open(encoding="utf-8") as fh:
            return list(_csv.DictReader(fh))

    sad = {(r["FUEL"], r["YEAR"]): float(r["Val"]) for r in load("SpecifiedAnnualDemand")}
    dm = float(load("DM")[0]["Val"])
    assert dm != 0, "exported DM is zero; the base FMT row cannot be recovered"

    with (ROOT / "scenarios" / "no-sav-vmt.csv").open(encoding="utf-8") as fh:
        rows = list(_csv.reader(fh))
    nosav = {y: float(v) for y, v in zip(rows[0][1:], rows[1][1:])}

    gap = max(abs(sad[("VMT", y)] + sad[("FMT", y)] / dm - nosav[y]) for y in nosav)
    assert gap <= 1e-3, f"exported instance departs from the no-SAV row by {gap}"
    return f"{len(sad)} demand rows, DM={dm:g}, max gap {gap:.2e}"


def main() -> int:
    print("offline checks - everything that does not need a solver\n")
    check("no-SAV row regenerates from the data file", no_sav_row_is_reproducible)
    check("VMT + FMT equals the no-SAV row", demand_split_holds)
    check("scenario grid is the paper's Table 2", grid_matches_table2)
    check("n/a guard fires where there is a fleet", na_only_where_there_is_no_fleet)
    check("three results writers agree", writers_agree)
    check("scenario writer is derived, not edited", scenario_writer_is_derived)
    check("driver never enables solprint", driver_never_turns_solprint_on)
    check("driver keeps its guards", driver_keeps_the_agreement_assertion)
    check("2018 model files untouched", shipped_driver_is_untouched)
    check("exported instance agrees with GAMS", exported_instance_agrees_with_the_gams_source)

    print()
    if failures:
        print(f"{len(failures)} check(s) FAILED: {', '.join(failures)}")
        return 1
    print("all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

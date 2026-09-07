#!/usr/bin/env python
"""Assert the three results writers still agree, section for section.

    python scripts/check_writers.py

model/Results_Baseline.gms and model/Results_CO2_Policy.gms are the 2018 artifact and
are kept verbatim. model/Results_Scenario.gms is the same writer with its output path
parameterised, used by the scenario driver. Three copies of one file is the shape that
drifts, so this compares them after normalising the two things that legitimately
differ: the put-file identifier and its target.

Regenerate the scenario writer with scripts/derive_results_writer.py rather than
editing it, and this check stays cheap.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1] / "model"
FILES = ["Results_Baseline.gms", "Results_CO2_Policy.gms", "Results_Scenario.gms"]


def normalise(path: pathlib.Path) -> list[str]:
    text = path.read_text(errors="replace")
    text = re.sub(r"Results_Baseline|Results_CO2_Policy|ResultsFile", "W", text)
    text = re.sub(r"/'?[^/\n]*Results\.csv'?/|/'%RESULTSFILE%'/", "/OUT/", text)
    # the scenario writer carries a provenance header the 2018 pair does not
    lines = [ln.rstrip() for ln in text.splitlines()]
    return [ln for ln in lines if ln and not ln.startswith("*")]


def main() -> int:
    normed = {f: normalise(ROOT / f) for f in FILES}

    # Prove the comparison can fail before trusting that it passed.
    canary = list(normed[FILES[0]])
    canary[5] = canary[5] + " put 'drift';"
    assert canary != normed[FILES[0]], "the normaliser erased the difference it must catch"

    ref_name, ref = FILES[0], normed[FILES[0]]
    failed = False
    for name in FILES[1:]:
        other = normed[name]
        if other == ref:
            print(f"ok   {name} matches {ref_name} ({len(ref)} significant lines)")
            continue
        failed = True
        print(f"DRIFT {name} differs from {ref_name}", file=sys.stderr)
        for i, (a, b) in enumerate(zip(ref, other)):
            if a != b:
                print(f"  first difference at significant line {i + 1}:", file=sys.stderr)
                print(f"    {ref_name}: {a}", file=sys.stderr)
                print(f"    {name}: {b}", file=sys.stderr)
                break
        if len(ref) != len(other):
            print(f"  lengths differ: {len(ref)} vs {len(other)}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

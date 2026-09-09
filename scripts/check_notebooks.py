#!/usr/bin/env python
"""Both notebooks must regenerate byte-identical - source AND output.

    python scripts/check_notebooks.py

Needs nbformat and nbclient always, and highspy for 01_model.ipynb (open-source,
no licence - see pyproject.toml's `highs` extra). Missing either is reported as a
skip, not a failure: this is the licence-free path and it should say so rather than
error at whoever does not have the optional pieces installed.

scripts/build_notebooks.py already asserts SOURCE matches on generation. What this
adds is OUTPUT: re-executing the committed notebooks and comparing what they produce
against what is committed, cell by cell, across every channel a cell emits - not just
the ones a comparison happens to name.

That distinction is not cosmetic. A pandas ``Styler``'s ``text/plain`` repr is
``<Styler at 0x...>`` and carries none of its table; the table exists only in
``text/html``. A comparison written to check "the output" by checking ``text/plain``
is blind to exactly the cells whose content matters, and the miss does not announce
itself - the check passes, having compared nothing. ``_cell_outputs`` below compares
whichever channels a cell actually has, discovered from the output object itself, so
narrowing the comparison to a named subset is not a decision this file lets a future
edit make by accident. ``test_the_comparison_sees_a_renderer_only_difference`` proves
it catches the specific case that motivated it, watched to fail by construction: two
synthetic outputs identical in ``text/plain`` and different only in ``text/html``.

Two more things worth knowing before reading a pass here as more than it is:

**A verification that only runs on the machine that wrote it is not a verification.**
Both notebooks passed a strict byte-for-byte comparison against committed output
before this file existed - on the machine that had just generated them. Re-run from
an isolated clone with the clone's own installed package (not whatever `sav_osemosys`
`PYTHONPATH` happens to resolve to - an editable install can silently shadow a clone),
the comparison failed: the committed output carried the absolute path of the machine
that wrote it. Fixed at the two print statements in build_model_notebook.py rather
than normalised here, because a normaliser for a value the notebook itself chose to
print would still be hiding it from every reader who is not comparing bytes.

**Object-identity tokens (memory addresses) are normalised here because they are not
this notebook's to fix** - a Styler's repr address is CPython's choice, not this
repo's. A stopwatch reading is a different case: fixed at the source that prints it,
not normalised, because it is a value this repo chose to print and could simply stop
printing. Confusing the two - reaching for the normaliser because it is easier than
finding the print statement - is how a normaliser grows into something that hides an
increasingly wide class of real differences instead of a narrow class of inert ones.
"""
from __future__ import annotations

import copy
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

_ADDR = re.compile(r"0x[0-9a-fA-F]{6,}")


def _normalise_object_addresses(value):
    if isinstance(value, str):
        return _ADDR.sub("0xADDR", value)
    if isinstance(value, list):
        return [_normalise_object_addresses(v) for v in value]
    return value


def _cell_outputs(cell) -> list[dict]:
    """Every output channel the cell actually carries, not a named subset of them.

    Comparing the whole normalised output object - rather than extracting `text/plain`
    or any other single key - is what makes this sensitive to a difference that lives
    only in `text/html`, only in `image/png`, or in a channel nobody has thought to
    name yet. See the module docstring for the concrete case this was written for.
    """
    out = []
    for o in cell.get("outputs", []):
        o = dict(o)
        o.pop("execution_count", None)
        if "text" in o:
            t = o["text"]
            o["text"] = _normalise_object_addresses(t if isinstance(t, str) else "".join(t))
        if "data" in o:
            o["data"] = {k: _normalise_object_addresses(v) for k, v in o["data"].items()}
        out.append(o)
    return out


def test_the_comparison_sees_a_renderer_only_difference() -> None:
    """Watched to fail: two outputs alike in text/plain, differing only in text/html.

    A comparison narrowed to text/plain would call these identical. This one must not.
    Run first, every time - a comparator that cannot be shown to fail is not verified
    by a pass, it is merely unfalsified.
    """
    a = {"cells": [{"cell_type": "code", "outputs": [
        {"output_type": "display_data",
         "data": {"text/plain": "<Styler at 0x111111>", "text/html": "<table>66113.2</table>"}},
    ]}]}
    b = copy.deepcopy(a)
    b["cells"][0]["outputs"][0]["data"]["text/html"] = "<table>77224.2</table>"

    out_a = _cell_outputs(a["cells"][0])
    out_b = _cell_outputs(b["cells"][0])
    assert out_a != out_b, (
        "the comparison did not notice a text/html-only difference - "
        "it would pass on an injected result exactly as it did before this was fixed"
    )
    # and the address normalisation must not itself be what makes them differ
    only_address_differs = copy.deepcopy(a)
    only_address_differs["cells"][0]["outputs"][0]["data"]["text/plain"] = "<Styler at 0x222222>"
    assert _cell_outputs(a["cells"][0]) == _cell_outputs(only_address_differs["cells"][0]), (
        "an object-identity address alone was treated as a real difference"
    )


def _reexecute(name: str):
    import nbformat as nbf
    from nbclient import NotebookClient

    path = ROOT / "notebooks" / name
    committed = nbf.read(path, as_version=4)
    fresh = copy.deepcopy(committed)
    for cell in fresh.cells:
        if cell.cell_type == "code":
            cell.outputs, cell.execution_count = [], None
    NotebookClient(fresh, timeout=1800, kernel_name="python3",
                   resources={"metadata": {"path": str(ROOT)}}).execute()
    return committed, fresh


def check_notebook(name: str, *, needs) -> str:
    for dep in needs:
        try:
            __import__(dep)
        except ImportError:
            return f"SKIP ({dep} not installed)"

    committed, fresh = _reexecute(name)
    if len(committed.cells) != len(fresh.cells):
        raise AssertionError(f"{name}: {len(committed.cells)} committed cells, "
                             f"{len(fresh.cells)} regenerated")

    mismatches = []
    for i, (a, b) in enumerate(zip(committed.cells, fresh.cells)):
        if a.cell_type != "code":
            continue
        if "".join(a.source) != "".join(b.source):
            mismatches.append(f"cell {i}: SOURCE differs")
        elif _cell_outputs(a) != _cell_outputs(b):
            mismatches.append(f"cell {i}: OUTPUT differs")

    if mismatches:
        raise AssertionError(f"{name}: " + "; ".join(mismatches))
    n_code = sum(1 for c in committed.cells if c.cell_type == "code")
    return f"{n_code} code cells, source and output both reproduce"


def main() -> int:
    print("notebook reproducibility - source and every output channel\n")
    failures = []

    try:
        test_the_comparison_sees_a_renderer_only_difference()
        print("ok   comparison is sensitive to a renderer-only (text/html) difference")
    except AssertionError as exc:
        failures.append("comparator self-test")
        print(f"FAIL comparator self-test\n       {exc}")

    for name, needs in [("00_verify.ipynb", ["nbformat", "nbclient"]),
                       ("01_model.ipynb", ["nbformat", "nbclient", "highspy"])]:
        try:
            detail = check_notebook(name, needs=needs)
        except AssertionError as exc:
            failures.append(name)
            print(f"FAIL {name}\n       {exc}")
        except Exception as exc:  # noqa: BLE001 - a broken check is a failed check
            failures.append(name)
            print(f"FAIL {name}\n       unexpected {type(exc).__name__}: {exc}")
        else:
            print(f"{'SKIP' if detail.startswith('SKIP') else 'ok  '} {name} - {detail}")

    print()
    if failures:
        print(f"{len(failures)} check(s) FAILED: {', '.join(failures)}")
        return 1
    print("all checks passed (or skipped for a missing optional dependency)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

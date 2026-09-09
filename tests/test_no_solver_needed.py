"""The licence-free claim, checked by blocking the solver and importing for real.

`00_verify.ipynb` claims it needs no solver. **That claim cannot be checked by reading**,
and this file exists because reading it is exactly what fails:

    the notebook contains no `import gurobipy`
    it contains `import sav_osemosys`
    ... which, if the package eagerly imported its model module, would import gurobipy

A guard that greps the notebook source for the name of the solver finds nothing and passes,
while the notebook fails at import on the one machine it exists to serve. Reported by the
session reproducing `fews-stochopt-esd-2022`, which had that exact defect and that exact
guard. Dependencies are transitive; the text carries no evidence of them.

So: block the solver, then import for real.

The blocker is itself tested first. The same session's first attempt used `find_module`,
removed from modern Python, so it blocked nothing and the run that "passed" had proved
nothing at all — the sharpest possible case of a probe agreeing with itself.
"""
from __future__ import annotations

import importlib
import importlib.abc
import re
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK = ROOT / "notebooks" / "00_verify.ipynb"

# Everything a solver-free reader must never need.
SOLVERS = {"gurobipy", "highspy", "cplex", "pulp", "pyomo"}


class _Blocker(importlib.abc.MetaPathFinder):
    """Refuse to import the named top-level packages.

    `find_spec`, not `find_module` — the latter was removed and silently blocks nothing.
    """

    def __init__(self, names: set[str]) -> None:
        self.names = names

    def find_spec(self, fullname, path=None, target=None):
        if fullname.split(".")[0] in self.names:
            raise ImportError(f"BLOCKED by the no-solver test: {fullname}")
        return None


@pytest.fixture
def no_solvers():
    """Install the blocker and drop anything already imported, so it actually bites."""
    blocker = _Blocker(SOLVERS)
    saved = {k: v for k, v in sys.modules.items() if k.split(".")[0] in SOLVERS}
    package = {k: v for k, v in sys.modules.items() if k.split(".")[0] == "sav_osemosys"}
    for name in list(saved) + list(package):
        del sys.modules[name]
    sys.meta_path.insert(0, blocker)
    try:
        yield
    finally:
        sys.meta_path.remove(blocker)
        for name in list(sys.modules):
            if name.split(".")[0] == "sav_osemosys":
                del sys.modules[name]
        sys.modules.update(saved)
        sys.modules.update(package)


def test_the_blocker_itself_works(no_solvers):
    """A clean result from a broken blocker is indistinguishable from a real pass.

    Prove it fires before believing anything else in this file.
    """
    with pytest.raises(ImportError, match="BLOCKED"):
        importlib.import_module("gurobipy")
    with pytest.raises(ImportError, match="BLOCKED"):
        importlib.import_module("highspy")


def test_importing_the_package_does_not_pull_in_a_solver(no_solvers):
    """`import sav_osemosys` is what the notebook actually writes."""
    importlib.import_module("sav_osemosys")


@pytest.mark.parametrize("module", [
    "sav_osemosys.data",
    "sav_osemosys.sets",
    "sav_osemosys.parameters",
    "sav_osemosys.verify",
    "sav_osemosys.figures",
])
def test_every_module_the_verification_path_touches(no_solvers, module):
    importlib.import_module(module)


def test_the_notebooks_own_imports(no_solvers):
    """Import exactly what the notebook imports, rather than what we think it imports.

    Reads the committed notebook, so adding an import to it that needs a solver fails
    here rather than in a reader's Colab session.
    """
    import json

    cells = json.loads(NOTEBOOK.read_text(encoding="utf-8"))["cells"]
    source = "\n".join("".join(c["source"]) for c in cells if c["cell_type"] == "code")
    names = set()
    for match in re.finditer(r"^\s*(?:import|from)\s+([a-zA-Z_][\w.]*)", source, re.M):
        top = match.group(1).split(".")[0]
        if top not in sys.stdlib_module_names:
            names.add(top)

    assert names, "no third-party imports found; the parser is probably broken"
    for name in sorted(names):
        importlib.import_module(name)


def test_the_verification_runs_end_to_end_with_no_solver(no_solvers):
    """The claim in full: check a real instance with no solver importable."""
    verify = importlib.import_module("sav_osemosys.verify")
    artifacts = ROOT / "artifacts"
    mps = artifacts / "reduced-scenario-03.mps.gz"
    sol = artifacts / "reduced-scenario-03.sol.gz"
    if not mps.is_file():
        pytest.skip("no shipped instance; run scripts/export_reduced.py")

    result = verify.check_instance(mps, sol)
    assert result.rows_checked > 70_000
    assert result.ok(), result.summary()


def test_the_model_module_imports_without_a_solver(no_solvers):
    """`model.py` must import lazily: the solver is needed by build(), not by import.

    Split from the build() assertion below on purpose. One `pytest.raises` wrapping
    both statements would keep passing if the import itself started needing gurobipy
    - the exact defect this file exists to catch - because ImportError would simply
    be raised one line earlier than expected. A single assertion can't distinguish
    "failed for the right reason" from "failed for a different reason at all."
    """
    importlib.import_module("sav_osemosys.model")


def test_building_a_model_still_needs_a_solver(no_solvers):
    """The other direction, so the blocker is shown to be load-bearing.

    If this ever passes, the model module has stopped needing a solver, which would mean
    the tests above are no longer testing anything.
    """
    model = importlib.import_module("sav_osemosys.model")
    with pytest.raises(ImportError, match="BLOCKED"):
        model.build()

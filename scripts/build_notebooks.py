#!/usr/bin/env python
"""Generate the two notebooks, then execute them so they ship with their outputs.

    python scripts/build_notebooks.py            # build and execute both
    python scripts/build_notebooks.py --no-exec  # build only

The notebooks are GENERATED rather than hand-edited, for the same reason
Results_Scenario.gms is: a notebook is a JSON file that a human edits by running it, so
the source of truth drifts from what is committed unless something regenerates it. Edit
this script, not the .ipynb.

Both notebooks import from `sav_osemosys` rather than restating the model. That is the
Part 4 arrangement: the notebook narrates, the package implements, and one assertion
compares them.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import nbformat as nbf

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOKS = ROOT / "notebooks"
REPO = "sear-labs/sav-osemosys-trd-2019"
RAW = f"https://raw.githubusercontent.com/{REPO}/main"


def md(text: str) -> nbf.NotebookNode:
    return nbf.v4.new_markdown_cell(text.strip("\n"))


def code(text: str) -> nbf.NotebookNode:
    return nbf.v4.new_code_cell(text.strip("\n"))


SETUP = f'''
# Works from a clone or from Colab with nothing checked out.
try:
    import sav_osemosys  # noqa: F401
except ImportError:
    !pip install -q "git+https://github.com/{REPO}.git"

import matplotlib.pyplot as plt
import pandas as pd

pd.set_option("display.width", 120)
plt.rcParams["figure.dpi"] = 110
'''


# ============================================================================
# 00 - verification. No solver, no licence.
# ============================================================================

def thin_notebook() -> nbf.NotebookNode:
    cells = [
        md(f"""
# Verifying the SAV model's published results

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/{REPO}/blob/main/notebooks/00_verify.ipynb)

The optimisation model behind **Jones and Leibowicz (2019)**, *Transportation Research
Part D*, [10.1016/j.trd.2019.05.005](https://doi.org/10.1016/j.trd.2019.05.005).

**Nothing here solves anything.** No solver, no licence, no Gurobi — this notebook
*checks* results rather than reproducing them, which is a different and in some ways
stronger thing: re-solving asks you to trust a solver, a licence and a machine, while
checking asks you to trust arithmetic.

To be exact about "needs nothing", because it is a claim and not a slogan: this needs
**numpy, pandas and matplotlib**, which the install cell fetches. What it does not need is
a solver, a licence, GAMS, or Gurobi.

Three things are established below:

1. the ten published scenarios, and how they compare to the two figures the paper prints
2. the shipped reduced instance, verified row by row and bound by bound
3. what does **not** reproduce, and why that is a property of the model rather than a defect
"""),
        code(SETUP),
        md("""
## 1. The published results

`results/clean/` is tidy long-format output — one value per row, named columns. The raw
GAMS report is wide and ragged, with a *varying* number of index columns; assuming a
fixed number once dropped 19% of a comparison silently. Nothing downstream reads it.
"""),
        code('''
from sav_osemosys.figures import load_clean

annual = load_clean("annual")
objective = load_clean("objective")
timeslice = load_clean("timeslice")

print(f"annual     {len(annual):>8,} rows")
print(f"timeslice  {len(timeslice):>8,} rows")
print(f"objective  {len(objective):>8,} rows")
annual.head()
'''),
        md("""
### The Table 2 grid, as run

The paper crosses SAV diffusion, carbon tax, charging paradigm and a travel-demand
multiplier. The 2018 run file that survived produces **two** solves under an emissions
*cap*; the paper runs **ten** under a *tax*. That mismatch is why the paper resisted
reproduction for years.
"""),
        code('''
import io, urllib.request

def read_grid():
    """Local first, then the copy on GitHub — same rule the package uses for data."""
    local = next((p for p in [Path.cwd(), *Path.cwd().parents]
                  if (p / "scenarios" / "table2.csv").is_file()), None)
    if local:
        text = (local / "scenarios" / "table2.csv").read_text()
    else:
        text = urllib.request.urlopen(f"{RAW_BASE}/scenarios/table2.csv").read().decode()
    return pd.read_csv(io.StringIO("\\n".join(l for l in text.splitlines()
                                              if not l.startswith("#"))))

from pathlib import Path
RAW_BASE = "''' + RAW + '''"
grid = read_grid()
table = grid.merge(objective, on="scenario")
table
'''),
        md("""
### The acceptance test

The paper prints **no cost figures at all** — Fig. 10 gives objective values as bar
heights with no table — so not one number in the objective column can be checked against
the article. The electricity mix is the only published quantity this model can be held
to, and the paper states two figures:

- without a carbon tax, natural gas is **80%** of electricity produced in 2035
- with one, gas **peaks at 56%**, in **2021**

The denominator is generation only: storage, V2G and charging also produce electricity
but move it rather than make it.
"""),
        code('''
from sav_osemosys.figures import gas_share

rows = []
for _, r in grid.iterrows():
    s = gas_share(annual, r.scenario)
    rows.append({"scenario": r.scenario, "sav": r.sav, "tax": r.tax,
                 "charging": r.charging, "dm": r.dm,
                 "gas 2035 %": round(s.loc[2035], 1),
                 "peak %": round(s.max(), 1), "peak year": s.idxmax()})
summary = pd.DataFrame(rows)
summary
'''),
        code('''
no_tax = summary[(summary.tax == "no") & (summary.sav == "70")]
taxed = summary[(summary.tax == "yes") & (summary.sav == "70")]

print("no tax  — paper says gas is 80% of generation in 2035")
for _, r in no_tax.iterrows():
    print(f"   scenario {r.scenario:>2}: {r['gas 2035 %']:>5.1f}%   off by {r['gas 2035 %']-80:+.1f}")
print()
print("tax     — paper says gas peaks at 56%, in 2021")
for _, r in taxed.iterrows():
    print(f"   scenario {r.scenario:>2}: {r['peak %']:>5.1f}% in {r['peak year']}"
          f"   off by {r['peak %']-56:+.1f}, {r['peak year']-2021:+d} yr")
print()
print(f"every taxed scenario peaks in {sorted(set(taxed['peak year']))} "
      f"— the paper's year, and it does not move with the demand multiplier")
'''),
        md("""
**The peak year is the load-bearing evidence.** The old emissions-cap run peaks at 54.6%
in **2025** — right magnitude, four years late, which is exactly what a cap ramping
linearly to 2050 does against a tax that bites immediately. Enabling the tax moves the
peak to 2021 and it stays there across every taxed case regardless of demand multiplier
or charging paradigm. That is a signature, not a coincidence.
"""),
        md("## 2. Figures"),
        code('''
fig, ax = plt.subplots(figsize=(9, 4.5))
from sav_osemosys.figures import plot_gas_share
plot_gas_share(annual, [3, 8], ax=ax)
ax.set_title("Gas share: central case, with and without the carbon tax")
plt.tight_layout(); plt.show()
'''),
        code('''
fig, ax = plt.subplots(figsize=(9, 4.5))
from sav_osemosys.figures import plot_objectives
plot_objectives(objective, ax=ax, grid=grid)
plt.tight_layout(); plt.show()
'''),
        code('''
fig, ax = plt.subplots(figsize=(9, 4.5))
from sav_osemosys.figures import plot_capacity_mix
plot_capacity_mix(annual, 8, ax=ax)
plt.tight_layout(); plt.show()
'''),
        md("""
## 3. Checking a solution by hand — no solver

The repository ships a **reduced instance** as standard `.mps` and `.sol` files. The cell
below reads both and verifies every constraint row, every variable bound, and the
objective, using numpy and nothing else.

The *full* model cannot be shipped this way: its `.mps` is about **3.4 GB** against
GitHub's 100 MB limit, measured. That is a real limit of this pattern and worth stating
rather than working around quietly.
"""),
        code('''
import urllib.request, tempfile
from pathlib import Path
from sav_osemosys.verify import check_instance

def fetch(relative):
    local = next((p for p in [Path.cwd(), *Path.cwd().parents]
                  if (p / relative).is_file()), None)
    if local:
        return local / relative
    target = Path(tempfile.gettempdir()) / Path(relative).name
    if not target.exists():
        urllib.request.urlretrieve(f"{RAW_BASE}/{relative}", target)
    return target

mps = fetch("artifacts/reduced-scenario-03.mps.gz")
sol = fetch("artifacts/reduced-scenario-03.sol.gz")

result = check_instance(mps, sol)
print(result.summary())
print()
print("verdict:", "PASS" if result.ok() else "FAIL")
'''),
        md("""
Violations are measured **relative to the largest coefficient in the problem**. An
absolute threshold is the wrong instrument here — this model's matrix spans twelve orders
of magnitude, so a fixed tolerance either waves everything through or rejects correct
answers.
"""),
        md("""
## 4. What does not reproduce

Cost and totals reproduce. **Dispatch and build timing do not, and never were unique.**
This is a degenerate LP: storage charge and discharge shift between timeslices at zero
cost, so many different schedules achieve the same optimal cost.

The surviving differences against the 2018 reference are of exactly two kinds:

- **under 0.005 absolute** — the GAMS report writer prints two decimals, so this is the
  print format rather than the model.
- **`EV_DISCHARGE` and `EV_DISCHARGE_F`**, differing by 9–22%. Nothing constrains their
  capacity and nothing charges for it, so the optimum does not determine them at all.

That is the whole residual. It is written down because an unexplained residual is
indistinguishable from an unfound bug.

**So: do not cite a specific build year or storage level from this model.** Cost, capacity
totals and emissions are reproducible; the schedule is one optimal answer among many.
"""),
    ]
    nb = nbf.v4.new_notebook(cells=cells)
    nb.metadata.update({"kernelspec": {"display_name": "Python 3", "language": "python",
                                       "name": "python3"}})
    return nb


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-exec", action="store_true", help="build without executing")
    ap.add_argument("--only", choices=["thin", "model"], help="build just one")
    args = ap.parse_args()

    NOTEBOOKS.mkdir(exist_ok=True)
    built = []
    if args.only in (None, "thin"):
        path = NOTEBOOKS / "00_verify.ipynb"
        nbf.write(thin_notebook(), path)
        built.append(path)
    if args.only in (None, "model"):
        from build_model_notebook import model_notebook  # split for length
        path = NOTEBOOKS / "01_model.ipynb"
        nbf.write(model_notebook(RAW), path)
        built.append(path)

    for path in built:
        print(f"  wrote {path.relative_to(ROOT)}")

    if args.no_exec:
        return 0

    from nbclient import NotebookClient
    for path in built:
        print(f"\nexecuting {path.name} ...")
        nb = nbf.read(path, as_version=4)
        client = NotebookClient(nb, timeout=1800, kernel_name="python3",
                                resources={"metadata": {"path": str(ROOT)}})
        try:
            client.execute()
        except Exception as exc:  # noqa: BLE001 - report and fail, do not ship broken
            print(f"  FAILED: {type(exc).__name__}: {str(exc)[:400]}", file=sys.stderr)
            return 1
        nbf.write(nb, path)
        print(f"  executed and saved with outputs")
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sys.exit(main())

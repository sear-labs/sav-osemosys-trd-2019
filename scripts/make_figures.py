#!/usr/bin/env python
"""Regenerate every published figure, deterministically, with no solver.

    python scripts/make_figures.py

These are the figures the README shows and anyone may cite. They are regenerated from
`results/clean/` by this script - never by running a notebook - so that:

  - they can be rebuilt in one command by someone who cannot solve the model
  - a change to the results changes the committed figure, visibly, in a diff
  - nothing depends on a human having run a cell

Notebook figures are a different thing and stay in the notebooks. A notebook plot is
exploratory and inline; a published figure is a file with a name that something else
points at. Mixing them means the published set silently depends on who last ran what.

Figures read `results/clean/`, never `results/scenario-NN/`. A figure that parses the raw
GAMS report is re-implementing the cleanup, and the second copy is the one that drifts -
that ragged format has already dropped 19% of a comparison once.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIGURES = ROOT / "figures"


def main() -> int:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import pandas as pd

    from sav_osemosys.figures import (load_clean, plot_capacity_mix, plot_gas_share,
                                      plot_objectives)

    try:
        annual = load_clean("annual")
        objective = load_clean("objective")
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    text = "\n".join(l for l in (ROOT / "scenarios" / "table2.csv").read_text().splitlines()
                     if not l.startswith("#"))
    import io
    grid = pd.read_csv(io.StringIO(text))

    FIGURES.mkdir(exist_ok=True)
    plt.rcParams["figure.dpi"] = 130
    written = []

    def save(name: str, fig) -> None:
        path = FIGURES / name
        fig.tight_layout()
        fig.savefig(path, bbox_inches="tight")
        plt.close(fig)
        written.append((name, path.stat().st_size))

    # 1. The acceptance test, as a picture: every taxed scenario peaking in 2021.
    fig, ax = plt.subplots(figsize=(9, 4.8))
    plot_gas_share(annual, [3, 8], ax=ax)
    ax.set_title("Natural gas share of generation — central case, with and without the tax")
    save("gas-share-central.png", fig)

    # 2. All ten, so the peak-year signature is visible across the whole grid.
    fig, ax = plt.subplots(figsize=(9, 4.8))
    plot_gas_share(annual, [1, 2, 3, 4, 6, 7, 8, 9], ax=ax, show_paper=True)
    ax.set_title("Gas share across the Table 2 grid — every taxed case peaks in 2021")
    ax.legend(fontsize=6, ncol=2)
    save("gas-share-all-scenarios.png", fig)

    # 3. Fig. 10 of the paper, which the paper prints without a table.
    fig, ax = plt.subplots(figsize=(9, 4.5))
    plot_objectives(objective, ax=ax, grid=grid)
    save("objectives.png", fig)

    # 4. What the tax actually does to the build.
    for scenario in (3, 8):
        fig, ax = plt.subplots(figsize=(9, 4.8))
        plot_capacity_mix(annual, scenario, ax=ax)
        save(f"capacity-mix-scenario-{scenario:02d}.png", fig)

    print(f"{len(written)} figures -> {FIGURES.relative_to(ROOT)}/")
    for name, size in written:
        print(f"  {name:<38}{size:>10,} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

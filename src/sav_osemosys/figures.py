"""Figures. One implementation, called by the scripts and by both notebooks.

Nothing here reads the raw GAMS output. Figures read `results/clean/`, which is tidy and
named; the raw file is ragged and is the format that once silently dropped 19% of a
comparison. That direction is a rule, not a preference: a figure that parses raw output is
re-implementing the cleanup, and the second copy is the one that goes wrong.

Every function takes an axis and returns it, so a notebook can compose them. Every
function also takes `reduced=`, which stamps the reduction INTO the image rather than into
markdown around it - a chart gets screenshotted into a slide and the caption does not
follow it.
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd

__all__ = ["load_clean", "gas_share", "plot_gas_share", "plot_objectives",
           "plot_capacity_mix", "plot_timeslice_profile", "GENERATION", "GAS"]

# ELC-producing technologies that are generation. BATTERY, EV_CHARGE, V2G, EV_DISCHARGE,
# EV_CHARGE_F, V2G_F and EV_DISCHARGE_F also produce ELC but move it rather than make it,
# so they are excluded from the denominator - which is what makes these numbers
# comparable to the paper's.
GENERATION = ["COALPP", "CCPP", "CTPP", "NUCPP", "HYDROPP", "WINDPP", "SOLPP",
              "BIOPP", "CCCCSPP", "IGCCCCSPP", "H2FUELCELL"]
GAS = ["CCPP", "CTPP", "CCCCSPP"]

# The paper's two published electricity-mix figures.
PAPER_GAS_2035_NO_TAX = 80.0
PAPER_GAS_PEAK_TAX = 56.0
PAPER_GAS_PEAK_YEAR = 2021


def _clean_dir(explicit: str | Path | None = None) -> Path:
    if explicit:
        return Path(explicit)
    for start in (Path(__file__).resolve(), Path.cwd().resolve()):
        for parent in [start, *start.parents]:
            candidate = parent / "results" / "clean"
            if (candidate / "annual.csv").is_file():
                return candidate
    raise FileNotFoundError(
        "no results/clean/ found. Run scripts/run_scenarios.py then "
        "scripts/clean_output.py, or pass a path."
    )


def load_clean(which: str = "annual", *, path: str | Path | None = None) -> pd.DataFrame:
    """Load one tidy results table: 'annual', 'timeslice' or 'objective'."""
    if which not in {"annual", "timeslice", "objective"}:
        raise ValueError(f"unknown table {which!r}")
    return pd.read_csv(_clean_dir(path) / f"{which}.csv")


def gas_share(annual: pd.DataFrame, scenario: int) -> pd.Series:
    """Natural gas as a percentage of electricity GENERATION, by year."""
    gen = annual[(annual.scenario == scenario)
                 & (annual.quantity == "AnnualGenerationByTechnology")
                 & (annual.item == "ELC")]
    if gen.empty:
        raise ValueError(f"no generation rows for scenario {scenario}")
    total = gen[gen.technology.isin(GENERATION)].groupby("year").value.sum()
    gas = gen[gen.technology.isin(GAS)].groupby("year").value.sum()
    return (100 * gas / total).rename("gas_share_pct")


def _stamp(ax, reduced: str | None) -> None:
    """Put the reduction in the IMAGE, not in prose beside it."""
    if not reduced:
        return
    ax.text(0.5, 1.02, f"reduced instance · {reduced} · NOT the published result",
            transform=ax.transAxes, ha="center", va="bottom",
            fontsize=8, color="#b03030", style="italic")


def plot_gas_share(annual: pd.DataFrame, scenarios, ax=None, *,
                   compare_to: pd.DataFrame | None = None, reduced: str | None = None,
                   show_paper: bool = True):
    """Gas share of generation over time, one line per scenario.

    `compare_to` overlays the same series from another results table - which is how the
    example notebook shows a reduced run against the published one. Where the full model
    fits, it is equally the way a reader compares a change they made against the original.
    """
    import matplotlib.pyplot as plt

    ax = ax or plt.subplots(figsize=(8, 4.5))[1]
    scenarios = [scenarios] if isinstance(scenarios, int) else list(scenarios)

    for n in scenarios:
        s = gas_share(annual, n)
        ax.plot([int(y) for y in s.index], s.values, lw=2, label=f"scenario {n}")
    if compare_to is not None:
        for n in scenarios:
            try:
                s = gas_share(compare_to, n)
            except ValueError:
                continue
            ax.plot([int(y) for y in s.index], s.values, lw=1.4, ls="--", color="0.45",
                    label=f"scenario {n} — published")

    if show_paper:
        ax.axhline(PAPER_GAS_2035_NO_TAX, color="#2a6f97", lw=1, ls=":",
                   label="paper: 80% in 2035 (no tax)")
        ax.plot([PAPER_GAS_PEAK_YEAR], [PAPER_GAS_PEAK_TAX], "o", ms=7,
                color="#b03030", label="paper: 56% peak in 2021 (tax)")

    ax.set_xlabel("year")
    ax.set_ylabel("natural gas, % of generation")
    ax.set_title("Natural gas share of electricity generation")
    ax.set_ylim(0, 100)
    ax.grid(alpha=0.3)
    ax.legend(fontsize=8, loc="best")
    _stamp(ax, reduced)
    return ax


def plot_objectives(objective: pd.DataFrame, ax=None, *, grid: pd.DataFrame | None = None,
                    reduced: str | None = None):
    """Total discounted system cost by scenario - the paper's Fig. 10, as numbers.

    The paper prints these as bar heights with no table, which is why no value here can be
    checked against the article.
    """
    import matplotlib.pyplot as plt

    ax = ax or plt.subplots(figsize=(8, 4.5))[1]
    d = objective.sort_values("scenario")
    taxed = set()
    if grid is not None:
        taxed = set(grid.loc[grid.tax == "yes", "scenario"].astype(int))
    colors = ["#b03030" if int(n) in taxed else "#2a6f97" for n in d.scenario]

    ax.bar(d.scenario.astype(str), d.objective, color=colors)
    ax.set_xlabel("scenario")
    ax.set_ylabel("total discounted cost")
    ax.set_title("System cost by scenario" + ("  (red = carbon tax)" if taxed else ""))
    ax.grid(alpha=0.3, axis="y")
    _stamp(ax, reduced)
    return ax


def plot_capacity_mix(annual: pd.DataFrame, scenario: int, ax=None, *,
                      technologies=None, reduced: str | None = None):
    """Installed generating capacity over time, stacked by technology."""
    import matplotlib.pyplot as plt

    ax = ax or plt.subplots(figsize=(8, 4.5))[1]
    techs = technologies or GENERATION
    cap = annual[(annual.scenario == scenario)
                 & (annual.quantity == "TotalAnnualCapacity")
                 & (annual.technology.isin(techs))]
    wide = cap.pivot_table(index="year", columns="technology", values="value",
                           aggfunc="sum").fillna(0.0)
    wide = wide.loc[:, wide.max() > 0]
    ax.stackplot([int(y) for y in wide.index], *[wide[c] for c in wide.columns],
                 labels=list(wide.columns))
    ax.set_xlabel("year")
    ax.set_ylabel("installed capacity (GW)")
    ax.set_title(f"Generating capacity, scenario {scenario}")
    ax.legend(fontsize=7, ncol=2, loc="upper left")
    ax.grid(alpha=0.3)
    _stamp(ax, reduced)
    return ax


def plot_timeslice_profile(timeslice: pd.DataFrame, scenario: int, year: str = "2050",
                           quantity: str = "Electricity Production", season: str = "SUMMER",
                           ax=None, *, reduced: str | None = None):
    """Hourly shape within one representative day - where the charging lever shows up."""
    import matplotlib.pyplot as plt

    ax = ax or plt.subplots(figsize=(8, 4.5))[1]
    d = timeslice[(timeslice.scenario == scenario) & (timeslice.year == int(year))
                  & (timeslice.quantity == quantity) & (timeslice.season == season)]
    if d.empty:
        raise ValueError(f"no rows for scenario {scenario}, {year}, {quantity}, {season}")
    hours = d.groupby("timeslice").value.sum()
    order = sorted(hours.index, key=lambda s: int("".join(c for c in s if c.isdigit())))
    ax.plot([int("".join(c for c in h if c.isdigit())) for h in order],
            [hours[h] for h in order], lw=2)
    ax.set_xlabel("hour of day")
    ax.set_ylabel(quantity.lower())
    ax.set_title(f"{quantity}, {season.lower()} day, {year} — scenario {scenario}")
    ax.grid(alpha=0.3)
    _stamp(ax, reduced)
    return ax

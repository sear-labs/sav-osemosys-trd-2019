"""Scenario levers, and their reconciliation against what GAMS actually applied.

The reconciliation tests skip when results/ is empty, because those outputs are
gitignored and need GAMS to produce. Everything else here runs from a clean clone.
"""
from __future__ import annotations

import csv
import pathlib

import pytest

from sav_osemosys import Instance
from sav_osemosys.parameters import Parameters, Scenario
from sav_osemosys.sets import build_indices

ROOT = pathlib.Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"

# The full Table 2 grid.
GRID = {
    1: Scenario(1, "70", "no", "optimized", 0.5),
    2: Scenario(2, "70", "no", "optimized", 2),
    3: Scenario(3, "70", "no", "optimized", 1),
    4: Scenario(4, "70", "no", "night", 1),
    5: Scenario(5, "none", "no", "n/a", "n/a"),
    6: Scenario(6, "70", "yes", "optimized", 0.5),
    7: Scenario(7, "70", "yes", "optimized", 2),
    8: Scenario(8, "70", "yes", "optimized", 1),
    9: Scenario(9, "70", "yes", "night", 1),
    10: Scenario(10, "none", "yes", "n/a", "n/a"),
}

# GAMS wrote levers.csv with Levers.nd = 8, so eight significant figures is the
# precision this comparison can honestly claim. A tighter tolerance would be
# measuring the print format rather than the values.
GAMS_PRINT_TOLERANCE = 1e-7


@pytest.fixture(scope="module")
def ix():
    return build_indices(Instance())


@pytest.fixture(scope="module")
def inst():
    return Instance()


def gams_levers(n: int) -> dict[str, str] | None:
    path = RESULTS / f"scenario-{n:02d}" / "levers.csv"
    if not path.is_file():
        return None
    rows = csv.reader(path.read_text(encoding="utf-8").splitlines()[1:])
    return {r[0].strip('"'): r[1].strip('"') for r in rows if len(r) > 1}


# ------------------------------------------------------------------ validation


def test_scenario_rejects_na_where_there_is_a_fleet():
    with pytest.raises(ValueError, match="no SAV fleet"):
        Scenario(99, sav="70", charging="n/a")
    with pytest.raises(ValueError, match="no SAV fleet"):
        Scenario(99, sav="70", dm="n/a")


def test_scenario_rejects_unknown_lever_values():
    for bad in (dict(sav="80"), dict(tax="maybe"), dict(charging="daytime")):
        with pytest.raises(ValueError):
            Scenario(99, **bad)


# ------------------------------------------------------------------- behaviour


def test_tax_is_twenty_dollars_escalating_five_percent(inst, ix):
    p = Parameters(inst, ix, GRID[8])
    e = ix.emissions[0]
    assert p.emissions_penalty[(e, "2015")] == pytest.approx(20.0)
    assert p.emissions_penalty[(e, "2050")] == pytest.approx(20.0 * 1.05 ** 35)
    # And it is indexed on the calendar year, so a later start still prices correctly.
    assert p.emissions_penalty[(e, "2016")] == pytest.approx(21.0)


def test_no_tax_scenario_prices_nothing(inst, ix):
    p = Parameters(inst, ix, GRID[3])
    assert all(v == 0.0 for v in p.emissions_penalty.values())


def test_no_sav_scenario_zeroes_the_fleet_and_restores_total_demand(inst, ix):
    p = Parameters(inst, ix, GRID[5])
    assert p.annual_demand[("FMT", "2050")] == 0.0
    assert p.annual_demand[("VMT", "2050")] == pytest.approx(13967.47174, abs=1e-3)


def test_demand_multiplier_scales_the_fleet_only(inst, ix):
    half, double = Parameters(inst, ix, GRID[1]), Parameters(inst, ix, GRID[2])
    assert double.annual_demand[("FMT", "2050")] == pytest.approx(
        4 * half.annual_demand[("FMT", "2050")])
    # Private travel is untouched by the multiplier.
    assert double.annual_demand[("VMT", "2050")] == pytest.approx(
        half.annual_demand[("VMT", "2050")])


def test_night_charging_closes_the_daytime_window_only(inst, ix):
    day, night = Parameters(inst, ix, GRID[4]), Parameters(inst, ix, GRID[3])
    for l in ix.low_v2g:
        assert day.capacity_factor[("EV_CHARGE_F", l, "2050")] == 0.0
    for l in ix.high_v2g:
        assert day.capacity_factor[("EV_CHARGE_F", l, "2050")] == pytest.approx(
            night.capacity_factor[("EV_CHARGE_F", l, "2050")])


def test_demand_split_assertion_holds(inst, ix):
    p = Parameters(inst, ix, GRID[3])
    assert p.demand_agreement_gap == pytest.approx(0.0, abs=1e-3)


# -------------------------------------------------------------- reconciliation


@pytest.mark.parametrize("n", sorted(GRID))
def test_python_levers_match_what_gams_applied(inst, ix, n):
    """The same four levers, computed independently, must give the same numbers.

    This runs before any constraint exists, so a divergence here is a parameter bug
    rather than a formulation bug - which is a much cheaper thing to find.
    """
    gams = gams_levers(n)
    if gams is None:
        pytest.skip(f"no GAMS results for scenario {n}; run scripts/run_scenarios.py")

    a = Parameters(inst, ix, GRID[n]).applied()
    comparisons = [
        ("tax first year", a["tax_first_year"], float(gams["tax_2015"])),
        ("tax last year", a["tax_last_year"], float(gams["tax_2050"])),
        ("VMT 2050", a["vmt_last_year"], float(gams["vmt_2050"])),
        ("FMT 2050", a["fmt_last_year"], float(gams["fmt_2050"])),
        ("charge factor day", a["charge_factor_day"],
         float(gams["charge_factor_day_W12"])),
        ("charge factor night", a["charge_factor_night"],
         float(gams["charge_factor_night_W1"])),
    ]
    for label, python, expected in comparisons:
        rel = abs(python - expected) / max(abs(expected), 1.0)
        assert rel <= GAMS_PRINT_TOLERANCE, (
            f"scenario {n} {label}: python {python!r} vs GAMS {expected!r} "
            f"(relative {rel:.2e})"
        )


def test_the_probe_samples_the_same_timeslice_gams_did(inst, ix):
    """Reconciliation is only meaningful if both sides answer the same question.

    GAMS samples W12 for day and W1 for night. Sampling "the first daytime slice"
    instead gives W6, which reads 0.894 where W12 reads 0.598 - a 30% gap that is
    purely an artefact of asking differently, and would look like a model error.
    """
    a = Parameters(inst, ix, GRID[3]).applied()
    assert a["day_probe"] == "W12"
    assert a["night_probe"] == "W1"

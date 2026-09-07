"""The instance loader, and the instance it loads.

These run with no solver and no licence. They are the first tests in this repository
that a stranger can run against a fresh clone, which is the point of the CSV export.
"""
from __future__ import annotations

import tempfile

import pytest

from sav_osemosys import Instance
import sav_osemosys.data as data


# The values below were established independently from the GAMS source before the CSV
# export existed, so they test the export rather than agreeing with it by construction.
VMT_2050_SAV = 4259.69675
FMT_2050_BASE = 9707.77499
VMT_2050_NO_SAV = 13967.47174


@pytest.fixture(scope="module")
def inst() -> Instance:
    return Instance()


def test_instance_is_found_locally(inst):
    assert inst.is_local, f"no local instance directory found; source was {inst.source}"


def test_set_cardinalities(inst):
    # The model's shape. If any of these move, every size estimate in the README is stale.
    assert len(inst.elements("YEAR")) == 36
    assert len(inst.elements("TIMESLICE")) == 72
    assert len(inst.elements("TECHNOLOGY")) == 51
    assert len(inst.elements("FUEL")) == 15
    assert len(inst.elements("STORAGE")) == 3
    assert inst.elements("YEAR")[0] == "2015"
    assert inst.elements("YEAR")[-1] == "2050"


def test_night_and_day_timeslices_partition_the_clock(inst):
    """LowV2G is daytime, HighV2G is night, and the night-only lever depends on it."""
    low = set(inst.elements("LowV2G"))
    high = set(inst.elements("HighV2G"))
    assert not (low & high), "a timeslice cannot be both day and night"
    assert low | high == set(inst.elements("TIMESLICE")), "the two do not cover the clock"
    assert len(high) == 27, f"night window is {len(high)} slices, expected 9 hours x 3 seasons"


def test_demand_split_reproduces_the_no_sav_row(inst):
    """VMT + base FMT must equal the undivided travel demand, in every year.

    This is the assumption the whole scenario grid rests on, checked here against the
    exported CSVs rather than against GAMS.
    """
    sad = inst.param("SpecifiedAnnualDemand", "FUEL", "YEAR")
    dm = inst.scalar("DM")
    assert dm != 0

    assert sad[("VMT", "2050")] == pytest.approx(VMT_2050_SAV)
    assert sad[("FMT", "2050")] / dm == pytest.approx(FMT_2050_BASE)
    total = sad[("VMT", "2050")] + sad[("FMT", "2050")] / dm
    assert total == pytest.approx(VMT_2050_NO_SAV, abs=1e-3)


def test_sav_share_reaches_about_seventy_percent(inst):
    """The paper's diffusion assumption: ~70% of travel demand is SAV by 2050."""
    sad = inst.param("SpecifiedAnnualDemand", "FUEL", "YEAR")
    dm = inst.scalar("DM")
    vmt, fmt = sad[("VMT", "2050")], sad[("FMT", "2050")] / dm
    assert 0.65 <= fmt / (vmt + fmt) <= 0.75


def test_export_carries_post_assignment_values(inst):
    """The CSVs must be what the model USES, not the raw tables it starts from.

    The data file lists EV_F capital cost as 38.8860 and then adds an autonomy premium
    on a later line. If the export ever captured the table instead of the computed
    parameter, this is where it shows.
    """
    capital = inst.param("CapitalCost", "TECHNOLOGY", "YEAR")
    extra = inst.param("AutoExtraCost", "YEAR")
    assert capital[("EV_F", "2015")] == pytest.approx(38.8860 + extra["2015"])
    assert extra["2015"] > 0, "the autonomy premium is zero; the export may be pre-assignment"


def test_no_carbon_price_and_no_cap_in_the_base_instance(inst):
    """The shipped instance is the unconstrained case; scenarios add the policy."""
    limit = inst.param("AnnualEmissionLimit", "YEAR")
    # The data file's "no cap" sentinel is 999,999,999. Annual CO2 in any scenario is
    # under 1e5, so anything above 1e8 is unreachable and therefore not a cap.
    assert min(limit.values()) >= 1e8, "the base instance carries a binding emissions cap"
    # EmissionsPenalty is zeroed by the data file, so it unloads with no records.
    assert not inst.has("EmissionsPenalty") or inst["EmissionsPenalty"].empty


def test_explicit_bad_path_is_refused_not_silently_replaced():
    """A caller who names a directory must get it or an error - never a different copy.

    Falling through to the repository's own data would mean someone testing a modified
    instance silently got main's numbers and was told nothing.
    """
    data.instance_dir.cache_clear()
    try:
        with pytest.raises((FileNotFoundError, NotADirectoryError)):
            data.instance_dir(tempfile.mkdtemp())
    finally:
        data.instance_dir.cache_clear()


def test_param_rejects_a_column_that_does_not_exist(inst):
    with pytest.raises(KeyError):
        inst.param("CapitalCost", "TECHNOLOGY", "NOT_A_COLUMN")


def test_manifest_matches_the_files_present(inst):
    """_manifest.csv is what the loader uses to recognise an instance directory."""
    manifest = inst["_manifest"]
    assert {"symbol", "kind", "records"} <= set(manifest.columns)
    missing = [s for s in manifest["symbol"] if not (inst._dir / f"{s}.csv").is_file()]
    assert not missing, f"manifest lists symbols with no CSV: {missing[:5]}"
    assert len(manifest) >= 100, f"manifest lists only {len(manifest)} symbols"

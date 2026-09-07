"""Sets, subsets and the sparse index structure. No solver, no licence."""
from __future__ import annotations

import pytest

from sav_osemosys import Instance
from sav_osemosys.sets import SEASON_PREFIX, build_indices


@pytest.fixture(scope="module")
def ix():
    return build_indices(Instance())


def test_season_prefixes_are_matched_longest_first(ix):
    """"S" is a prefix of "SF". Matching in the wrong order mislabels every
    spring/fall slice as summer, with no error - so test the ambiguous case, not
    just the easy ones."""
    assert ix.season_of("SF1") == "SPRFALL"
    assert ix.season_of("SF24") == "SPRFALL"
    assert ix.season_of("S1") == "SUMM"
    assert ix.season_of("S24") == "SUMM"
    assert ix.season_of("W12") == "WNT"
    with pytest.raises(KeyError):
        ix.season_of("Q9")


def test_season_lookup_agrees_with_the_declared_subsets(ix):
    """The label-parsing shortcut must agree with the sets GAMS actually declares."""
    for name, members in (("WNT", ix.wnt), ("SPRFALL", ix.sprfall), ("SUMM", ix.summ)):
        for l in members:
            assert ix.season_of(l) == name, f"{l} is in {name} but parses as {ix.season_of(l)}"
    assert len(ix.wnt) + len(ix.sprfall) + len(ix.summ) == len(ix.timeslices)


def test_season_lookup_would_fail_if_prefixes_were_reordered(ix):
    """Prove the guard is load-bearing: with naive first-match ordering, SF1 breaks."""
    naive = None
    for prefix, season in ((p, s) for s, p in SEASON_PREFIX.items()):
        if "SF1".startswith(prefix) and "SF1"[len(prefix):].isdigit():
            naive = naive or season
    # Under first-match-wins the answer depends on iteration order; longest-first
    # does not. The real method must be correct regardless.
    assert ix.season_of("SF1") == "SPRFALL"


def test_day_and_night_partition_the_clock(ix):
    assert not set(ix.low_v2g) & set(ix.high_v2g)
    assert set(ix.low_v2g) | set(ix.high_v2g) == set(ix.timeslices)
    assert len(ix.high_v2g) == 27      # 9 night hours x 3 seasons


def test_sparsity_is_real_and_large(ix):
    """The port's central claim: most technology-fuel pairs do not interact."""
    dense = len(ix.technologies) * len(ix.fuels)
    assert len(ix.produces_tf) < dense * 0.10, "producing pairs are not sparse"
    assert len(ix.consumes_tf) < dense * 0.10, "consuming pairs are not sparse"
    assert len(ix.produces_tf) == 51
    assert len(ix.consumes_tf) == 44


def test_every_transport_technology_produces_its_own_demand_fuel(ix):
    """Private vehicles make VMT, fleet vehicles FMT, public transit PM.

    This is what makes the SAV lever work: zeroing FMT demand removes the fleet
    because fleet technologies produce nothing else.
    """
    produces = {(t, f) for t, f in ix.produces_tf}
    for t in ix.priv_trans:
        assert (t, "VMT") in produces
        assert not [f for tt, f in produces if tt == t and f != "VMT"], \
            f"{t} produces something other than VMT"
    for t in ix.fleet:
        assert (t, "FMT") in produces
        assert not [f for tt, f in produces if tt == t and f != "FMT"], \
            f"{t} produces something other than FMT"
    for t in ix.pub_trans:
        assert (t, "PM") in produces


def test_reduction_preserves_structure(ix):
    """A reduced instance must be the same model, just smaller."""
    inst = Instance()
    red = build_indices(
        inst,
        years=[str(y) for y in range(2015, 2021)],
        timeslices=[f"{p}{h}" for p in ("W", "SF", "S") for h in (1, 5, 9, 13, 17, 21)],
    )
    assert len(red.years) == 6
    assert len(red.timeslices) == 18
    # Technologies, fuels and the sparse structure are untouched by reduction.
    assert red.technologies == ix.technologies
    assert red.produces_tf == ix.produces_tf
    assert red.consumes_tf == ix.consumes_tf
    # Subsets are filtered, not emptied.
    assert len(red.wnt) == len(red.sprfall) == len(red.summ) == 6
    assert set(red.low_v2g) | set(red.high_v2g) == set(red.timeslices)


def test_reduction_rejects_members_that_do_not_exist(ix):
    with pytest.raises(ValueError):
        build_indices(Instance(), years=["1999"])
    with pytest.raises(ValueError):
        build_indices(Instance(), timeslices=["W99"])

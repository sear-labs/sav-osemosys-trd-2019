"""Sets, subsets and the sparsity that makes this model tractable in Python.

GAMS generates variables over the full cross product of its sets. Most of that cross
product is structurally empty: a coal plant has no relationship with gasoline, yet
`ProductionByTechnology(y, l, "COALPP", "PET", r)` is generated all the same. Measured
on this instance, **51 of 765 technology-fuel pairs actually produce anything, and 44
consume** - 6.7% and 5.8%.

That is why the GAMS model reports 18.8M variables and a faithful Python port of the
same mathematics needs roughly 1.5M. Nothing is approximated: a variable that exists
only to be forced to zero is not part of the model, it is padding, and Gurobi's presolve
would remove it anyway. Building it sparsely just declines to create it in the first
place.

`Indices` below is where that decision lives, so the model file can read like the
published OSeMOSYS formulation without every constraint re-deriving which combinations
are real.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from sav_osemosys.data import Instance

# Timeslice naming: W1..W24 winter, SF1..SF24 spring/fall, S1..S24 summer. The number
# is the hour, so the season prefix and the hour are both recoverable from the label.
SEASON_PREFIX = {"WNT": "W", "SPRFALL": "SF", "SUMM": "S"}


@dataclass
class Indices:
    """The model's sets, its subsets, and the sparse index tuples built from them."""

    years: list[str]
    timeslices: list[str]
    technologies: list[str]
    fuels: list[str]
    storages: list[str]
    emissions: list[str]
    modes: list[str]
    regions: list[str]
    seasons: list[str]

    # Technology subsets the study's own equations index over.
    priv_trans: list[str]
    fleet: list[str]
    pub_trans: list[str]
    nicpp: list[str]              # non-intermittent plant, for the peak-demand constraint
    no_new_cap_2015: list[str]    # may not build in the first year

    # Timeslice subsets.
    wnt: list[str]
    sprfall: list[str]
    summ: list[str]
    low_v2g: list[str]            # daytime, hours 6-20
    high_v2g: list[str]           # night, hours 21-24 and 1-5

    # Sparse structure, derived from nonzero activity ratios.
    produces: list[tuple[str, str, str]] = field(default_factory=list)   # (t, f, m)
    consumes: list[tuple[str, str, str]] = field(default_factory=list)   # (t, f, m)
    produces_tf: list[tuple[str, str]] = field(default_factory=list)     # (t, f)
    consumes_tf: list[tuple[str, str]] = field(default_factory=list)     # (t, f)
    emits: list[tuple[str, str, str]] = field(default_factory=list)      # (t, e, m)

    @property
    def year_val(self) -> dict[str, int]:
        return {y: int(y) for y in self.years}

    def season_of(self, timeslice: str) -> str:
        """Map a timeslice label to its season.

        Longest prefix first, explicitly. "S" is a prefix of "SF", so checking in
        dictionary order happens to work today and would silently start returning
        SUMM for every spring/fall slice the moment someone reordered SEASON_PREFIX.
        That is a wrong answer with no error attached, so the ordering is enforced
        here rather than left to the literal's layout.
        """
        for prefix, season in sorted(
            ((p, s) for s, p in SEASON_PREFIX.items()), key=lambda kv: -len(kv[0])
        ):
            if timeslice.startswith(prefix) and timeslice[len(prefix):].isdigit():
                return season
        raise KeyError(f"cannot place timeslice {timeslice!r} in a season")

    def summary(self) -> str:
        dense_tf = len(self.technologies) * len(self.fuels)
        return (
            f"{len(self.years)} years x {len(self.timeslices)} timeslices x "
            f"{len(self.technologies)} technologies x {len(self.fuels)} fuels\n"
            f"  producing (t,f) pairs: {len(self.produces_tf)} of {dense_tf} dense "
            f"({len(self.produces_tf) / dense_tf:.1%})\n"
            f"  consuming (t,f) pairs: {len(self.consumes_tf)} of {dense_tf} dense "
            f"({len(self.consumes_tf) / dense_tf:.1%})"
        )


def _subset(inst: Instance, name: str, universe: list[str]) -> list[str]:
    """Read a GAMS subset, preserving the parent set's order rather than file order."""
    members = set(inst.elements(name))
    unknown = members - set(universe)
    if unknown:
        raise ValueError(f"subset {name} contains members not in its parent set: {sorted(unknown)}")
    return [x for x in universe if x in members]


def build_indices(
    inst: Instance,
    *,
    years: list[str] | None = None,
    timeslices: list[str] | None = None,
) -> Indices:
    """Read the sets, then derive which (technology, fuel, mode) combinations are real.

    `years` and `timeslices` restrict the model to a subset - the reduction the example
    notebook uses so an open-source solver can handle it. Restricting them here rather
    than in the model means the formulation is identical either way, which is the whole
    point: the reduced instance exercises the same code the full one does.
    """
    all_years = inst.elements("YEAR")
    all_timeslices = inst.elements("TIMESLICE")
    technologies = inst.elements("TECHNOLOGY")
    fuels = inst.elements("FUEL")

    if years is not None:
        unknown = set(years) - set(all_years)
        if unknown:
            raise ValueError(f"requested years not in the instance: {sorted(unknown)}")
        all_years = [y for y in all_years if y in set(years)]
    if timeslices is not None:
        unknown = set(timeslices) - set(all_timeslices)
        if unknown:
            raise ValueError(f"requested timeslices not in the instance: {sorted(unknown)}")
        all_timeslices = [l for l in all_timeslices if l in set(timeslices)]

    keep_ts = set(all_timeslices)

    def ts_subset(name: str) -> list[str]:
        return [l for l in _subset(inst, name, inst.elements("TIMESLICE")) if l in keep_ts]

    oar = inst["OutputActivityRatio"]
    iar = inst["InputActivityRatio"]
    ear = inst["EmissionActivityRatio"]
    year_set = set(all_years)

    def triples(df, cols) -> list[tuple[str, str, str]]:
        d = df[(df["Val"] != 0) & (df["YEAR"].astype(str).isin(year_set))]
        seen = d[cols].astype(str).drop_duplicates()
        return [tuple(row) for row in seen.itertuples(index=False, name=None)]

    produces = triples(oar, ["TECHNOLOGY", "FUEL", "MODE_OF_OPERATION"])
    consumes = triples(iar, ["TECHNOLOGY", "FUEL", "MODE_OF_OPERATION"])
    emits = triples(ear, ["TECHNOLOGY", "EMISSION", "MODE_OF_OPERATION"])

    return Indices(
        years=all_years,
        timeslices=all_timeslices,
        technologies=technologies,
        fuels=fuels,
        storages=inst.elements("STORAGE"),
        emissions=inst.elements("EMISSION"),
        modes=inst.elements("MODE_OF_OPERATION"),
        regions=inst.elements("REGION"),
        seasons=inst.elements("SEASON"),
        priv_trans=_subset(inst, "PrivTrans", technologies),
        fleet=_subset(inst, "Fleet", technologies),
        pub_trans=_subset(inst, "PubTrans", technologies),
        nicpp=_subset(inst, "NICPP", technologies),
        no_new_cap_2015=_subset(inst, "NoNewCap2015", technologies),
        wnt=ts_subset("WNT"),
        sprfall=ts_subset("SPRFALL"),
        summ=ts_subset("SUMM"),
        low_v2g=ts_subset("LowV2G"),
        high_v2g=ts_subset("HighV2G"),
        produces=produces,
        consumes=consumes,
        produces_tf=sorted({(t, f) for t, f, _ in produces}),
        consumes_tf=sorted({(t, f) for t, f, _ in consumes}),
        emits=emits,
    )

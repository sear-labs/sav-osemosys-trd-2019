"""Scenario levers, applied to the instance before the model is built.

These are the four columns of Table 2 in Jones and Leibowicz (2019), and they do here
exactly what `model/osemosys_scenario.gms` does in GAMS. Both read the same numbers and
both must produce the same objective; `scripts/reconcile.py` checks that they do.

The one subtlety is the demand multiplier. The GAMS data file applies its own `scalar DM`
to FMT before anything else runs, so the exported CSVs carry an already-multiplied row.
Recovering the base means dividing it back out - and the check that this is right is the
same one the GAMS driver makes: private VMT plus base FMT must equal the no-SAV travel
demand in every year.
"""
from __future__ import annotations

from dataclasses import dataclass

from sav_osemosys.data import Instance
from sav_osemosys.sets import Indices

# The paper's carbon price: $20/tCO2 in the base year, rising 5% a year.
TAX_BASE_RATE = 20.0
TAX_ESCALATION = 1.05

# The data file's "no cap" sentinel. E8_AnnualEmissionsLimit is unconditional, so the
# limit must stay unreachable rather than be zeroed - zeroing forces emissions to zero
# and reads as an infeasible model rather than as a mistake.
NO_EMISSION_CAP = 999_999_999.0

# Vehicle activity limits, from the study's own CarMiles/FleetMiles/PubMiles equations.
# Thousands of miles per vehicle per year.
MILES_PRIVATE = 15
MILES_FLEET = 92
MILES_PUBLIC = 15 * 20


@dataclass(frozen=True)
class Scenario:
    """One row of Table 2."""

    number: int | str
    sav: str = "70"            # "70" | "none"
    tax: str = "no"            # "yes" | "no"
    charging: str = "optimized"  # "optimized" | "night" | "n/a"
    dm: float | str = 1.0      # demand multiplier, or "n/a" where there is no fleet

    def __post_init__(self) -> None:
        if self.sav not in {"70", "none"}:
            raise ValueError(f"sav must be '70' or 'none', got {self.sav!r}")
        if self.tax not in {"yes", "no"}:
            raise ValueError(f"tax must be 'yes' or 'no', got {self.tax!r}")
        if self.charging not in {"optimized", "night", "n/a"}:
            raise ValueError(f"charging must be optimized|night|n/a, got {self.charging!r}")
        for field_name in ("charging", "dm"):
            if getattr(self, field_name) == "n/a" and self.sav != "none":
                raise ValueError(
                    f"{field_name}='n/a' is only valid where there is no SAV fleet, "
                    f"but sav={self.sav!r}"
                )
        if self.dm != "n/a":
            float(self.dm)

    @property
    def multiplier(self) -> float:
        """The multiplier to apply. Where there is no fleet this is inert."""
        return 1.0 if self.dm == "n/a" else float(self.dm)

    @property
    def charges_at_night_only(self) -> bool:
        return self.charging == "night"

    def label(self) -> str:
        return (f"scenario {self.number}: sav={self.sav}, tax={self.tax}, "
                f"charging={self.charging}, dm={self.dm}")


class Parameters:
    """Every parameter the model needs, with the scenario already applied.

    Keys are the plain tuples the constraints index by, so the model file reads like the
    published formulation rather than like DataFrame manipulation.
    """

    def __init__(self, inst: Instance, ix: Indices, scenario: Scenario) -> None:
        self.inst, self.ix, self.scenario = inst, ix, scenario
        self.region = ix.regions[0]
        self.start_year = int(inst.scalar("StartYear"))
        self.year_val = {y: int(y) for y in ix.years}
        self.first_year = min(self.year_val.values())
        self.last_year = max(self.year_val.values())

        self._load_base()
        self._apply_sav_and_demand()
        self._apply_tax()
        self._apply_charging()
        self._derive_fleet_size()

    # ---------------------------------------------------------------- base data
    def _load_base(self) -> None:
        inst, ix = self.inst, self.ix

        def p(name, *keys, default=0.0):
            try:
                raw = inst.param(name, *keys)
            except (FileNotFoundError, ConnectionError):
                raw = {}
            return _Defaulted(raw, default)

        self.year_split = p("YearSplit", "TIMESLICE", "YEAR")
        self.days_in_season = p("DaysInSeason", "TIMESLICE")
        self.time_slice_in_season = p("TimeSliceInSeason", "TIMESLICE", "SEASON")
        self.discount_rate = p("DiscountRate", "TECHNOLOGY")
        self.discount_rate_storage = p("DiscountRateStorage", "STORAGE")
        self.demand_response_discount = p("DemandResponseDiscountRate", "REGION")

        self.demand_profile = p("SpecifiedDemandProfile", "FUEL", "TIMESLICE", "YEAR")
        self.accumulated_demand = p("AccumulatedAnnualDemand", "FUEL", "YEAR")

        self.capacity_factor = p("CapacityFactor", "TECHNOLOGY", "TIMESLICE", "YEAR")
        self.availability = p("AvailabilityFactor", "TECHNOLOGY", "YEAR", default=1.0)
        self.capacity_to_activity = p("CapacityToActivityUnit", "TECHNOLOGY")
        self.peak_tagged = p("TechWithCapacityNeededToMeetPeakTS", "TECHNOLOGY")
        self.operational_life = p("OperationalLife", "TECHNOLOGY")
        self.residual_capacity = p("ResidualCapacity", "TECHNOLOGY", "YEAR")

        self.input_ratio = p("InputActivityRatio", "TECHNOLOGY", "FUEL",
                             "MODE_OF_OPERATION", "YEAR")
        self.output_ratio = p("OutputActivityRatio", "TECHNOLOGY", "FUEL",
                              "MODE_OF_OPERATION", "YEAR")
        self.emission_ratio = p("EmissionActivityRatio", "TECHNOLOGY", "EMISSION",
                                "MODE_OF_OPERATION", "YEAR")

        self.capital_cost = p("CapitalCost", "TECHNOLOGY", "YEAR")
        self.variable_cost = p("VariableCost", "TECHNOLOGY", "MODE_OF_OPERATION", "YEAR")
        self.fixed_cost = p("FixedCost", "TECHNOLOGY", "YEAR")

        self.to_storage = p("TechnologyToStorage", "TECHNOLOGY", "STORAGE",
                            "MODE_OF_OPERATION")
        self.from_storage = p("TechnologyFromStorage", "TECHNOLOGY", "STORAGE",
                              "MODE_OF_OPERATION")
        self.storage_life = p("OperationalStorageLife", "STORAGE")
        self.residual_storage = p("ResidualStorageCapacity", "YEAR", "STORAGE")
        self.min_storage_charge = p("MinStorageCharge", "STORAGE", "YEAR")
        self.capital_cost_storage = p("CapitalCostStorage", "YEAR", "STORAGE")
        self.storage_growth_rate = p("MaxCapacityGrowthRateStorage", "STORAGE")
        self.storage_startup = p("StartUpValueStorage", "STORAGE")

        self.max_capacity = p("TotalAnnualMaxCapacity", "TECHNOLOGY", "YEAR")
        self.min_capacity = p("TotalAnnualMinCapacity", "TECHNOLOGY", "YEAR")
        self.max_investment = p("TotalAnnualMaxCapacityInvestment", "TECHNOLOGY", "YEAR")
        self.min_investment = p("TotalAnnualMinCapacityInvestment", "TECHNOLOGY", "YEAR")
        self.growth_rate = p("MaxCapacityGrowthRate", "TECHNOLOGY")
        self.startup_value = p("StartUpValue", "TECHNOLOGY")

        self.activity_upper = p("TotalTechnologyAnnualActivityUpperLimit",
                                "TECHNOLOGY", "YEAR")
        self.activity_lower = p("TotalTechnologyAnnualActivityLowerLimit",
                                "TECHNOLOGY", "YEAR")
        self.period_activity_upper = p("TotalTechnologyModelPeriodActivityUpperLimit",
                                       "TECHNOLOGY")
        self.period_activity_lower = p("TotalTechnologyModelPeriodActivityLowerLimit",
                                       "TECHNOLOGY")

        self.reserve_tag_tech = p("ReserveMarginTagTechnology", "TECHNOLOGY", "YEAR")
        self.reserve_tag_fuel = p("ReserveMarginTagFuel", "FUEL", "YEAR")
        self.reserve_margin = p("ReserveMargin", "YEAR")

        self.re_tag_tech = p("RETagTechnology", "TECHNOLOGY", "YEAR")
        self.re_tag_fuel = p("RETagFuel", "FUEL", "YEAR")
        self.re_target = p("REMinProductionTarget", "YEAR")

        self.exogenous_emission = p("AnnualExogenousEmission", "EMISSION", "YEAR")
        self.nicpp_lower = p("NICPPlower", "YEAR")
        self.avg_speed = inst.scalar("AvgSpeed")

        self.dr_max = p("DemandResponseMaxLevel", "YEAR", "DR_TYPE", "FUEL", "TIMESLICE")
        self.dr_min = p("DemandResponseMinLevel", "YEAR", "DR_TYPE", "FUEL", "TIMESLICE")
        self.dr_cost = p("DemandResponseVarCost", "YEAR", "DR_TYPE", "FUEL")
        self.dr_tag = p("TagFuelWithDemandResponseCapability", "FUEL", "DR_TYPE")
        self.dr_types = inst.elements("DR_TYPE") if inst.has("DR_TYPE") else []

    # ------------------------------------------------- lever 1: SAV and demand
    def _apply_sav_and_demand(self) -> None:
        inst, ix = self.inst, self.ix
        sad = inst.param("SpecifiedAnnualDemand", "FUEL", "YEAR")
        data_dm = inst.scalar("DM")
        if data_dm == 0:
            raise ValueError("the instance's DM is zero, so the base FMT row is unrecoverable")

        base_vmt = {y: sad.get(("VMT", y), 0.0) for y in ix.years}
        # Divide out the multiplier the data file already applied.
        base_fmt = {y: sad.get(("FMT", y), 0.0) / data_dm for y in ix.years}
        no_sav = {y: base_vmt[y] + base_fmt[y] for y in ix.years}
        self.demand_agreement_gap = self._check_demand_split(no_sav)

        demand = {(f, y): sad.get((f, y), 0.0) for f in ix.fuels for y in ix.years}
        if self.scenario.sav == "none":
            for y in ix.years:
                demand[("VMT", y)] = no_sav[y]
                demand[("FMT", y)] = 0.0
        else:
            for y in ix.years:
                demand[("VMT", y)] = base_vmt[y]
                demand[("FMT", y)] = self.scenario.multiplier * base_fmt[y]
        self.annual_demand = _Defaulted(demand, 0.0)
        self.base_vmt, self.base_fmt, self.no_sav_vmt = base_vmt, base_fmt, no_sav

    def _check_demand_split(self, no_sav: dict[str, float]) -> float:
        """VMT + base FMT must equal the published no-SAV row, in every year.

        The same assertion the GAMS driver makes, for the same reason: it tests the
        demand-split hypothesis, the recovery of the base FMT row and the transcribed
        CSV all at once. Ten scenarios built on a wrong split would all solve.
        """
        import csv
        from pathlib import Path

        for base in (Path(__file__).resolve().parents[2], Path.cwd()):
            path = base / "scenarios" / "no-sav-vmt.csv"
            if path.is_file():
                rows = list(csv.reader(path.read_text(encoding="utf-8").splitlines()))
                published = {y: float(v) for y, v in zip(rows[0][1:], rows[1][1:])}
                shared = set(published) & set(no_sav)
                if not shared:
                    return 0.0
                gap = max(abs(no_sav[y] - published[y]) for y in shared)
                if gap > 1e-3:
                    raise AssertionError(
                        f"VMT + FMT departs from the published no-SAV row by {gap}; "
                        f"the demand-split assumption is wrong"
                    )
                return gap
        return float("nan")   # no local copy to check against; the GAMS driver still does

    # ------------------------------------------------------- lever 2: carbon tax
    def _apply_tax(self) -> None:
        """$20/tCO2 in the base year rising 5% a year, or nothing.

        Indexed on the calendar year rather than on position in the year set, so a
        reduced instance that starts later still gets the right price for its years.
        """
        penalty = {}
        for e in self.ix.emissions:
            for y in self.ix.years:
                if self.scenario.tax == "yes":
                    exponent = self.year_val[y] - self.start_year
                    penalty[(e, y)] = TAX_BASE_RATE * TAX_ESCALATION ** exponent
                else:
                    penalty[(e, y)] = 0.0
        self.emissions_penalty = _Defaulted(penalty, 0.0)
        self.emission_limit = _Defaulted(
            {(e, y): NO_EMISSION_CAP for e in self.ix.emissions for y in self.ix.years}, 0.0
        )

    # ---------------------------------------------------- lever 3: charging window
    def _apply_charging(self) -> None:
        """Night-only charging forbids the fleet charger from running in daylight.

        EV_CHARGE_F is the only technology feeding EV_BAT_F, so zeroing its daytime
        capacity factor is the whole lever.
        """
        if not self.scenario.charges_at_night_only:
            return
        blocked = set(self.ix.low_v2g)
        overrides = {
            ("EV_CHARGE_F", l, y): 0.0
            for l in blocked
            for y in self.ix.years
        }
        self.capacity_factor = _Overridden(self.capacity_factor, overrides)

    # ------------------------------------------------------------- derived values
    def _derive_fleet_size(self) -> None:
        """FleetSize is computed from the demands, so it is stale after the levers.

        VehicleVMTProduction divides by it, so a zero would be a division by zero a long
        way from its cause.
        """
        ix = self.ix
        self.fleet_size, self.fleet_size_fleet = {}, {}
        for y in ix.years:
            cf = self.capacity_factor[("ICE_PET", ix.timeslices[0], y)] or 1.0
            cf_f = self.capacity_factor[("ICE_PET_F", ix.timeslices[0], y)] or 1.0
            self.fleet_size[y] = max(
                1000 * ((self.demand_profile[("VMT", l, y)] * self.annual_demand[("VMT", y)])
                        / (self.year_split[(l, y)] * 8760)) / self.avg_speed * (1 / cf)
                for l in ix.timeslices
            )
            self.fleet_size_fleet[y] = max(
                1000 * ((self.demand_profile[("FMT", l, y)] * self.annual_demand[("FMT", y)])
                        / (self.year_split[(l, y)] * 8760)) / self.avg_speed * (1 / cf_f)
                for l in ix.timeslices
            )
        zero_years = [y for y, v in self.fleet_size.items() if v <= 0]
        if zero_years:
            raise ValueError(
                f"FleetSize is zero in {zero_years[:3]}: VehicleVMTProduction would "
                f"divide by zero"
            )

    # ------------------------------------------------------------------ reporting
    # The GAMS driver records its levers by sampling ONE daytime and ONE night-time
    # timeslice and taking the maximum over years. Reconciliation only means anything
    # if both sides answer the same question, so these name the same slices GAMS does
    # rather than "the first daytime slice", which is W6 and reads 0.894 where W12
    # reads 0.598 - a 30% gap that is entirely an artefact of asking differently.
    DAY_PROBE, NIGHT_PROBE = "W12", "W1"

    def _probe(self, preferred: str, pool: list[str]) -> str | None:
        """The slice GAMS samples, or the nearest available under reduction."""
        if preferred in pool:
            return preferred
        return pool[0] if pool else None

    def applied(self) -> dict[str, float]:
        """What the levers actually did - the observables a checker compares."""
        last = str(self.last_year)
        day = self._probe(self.DAY_PROBE, self.ix.low_v2g)
        night = self._probe(self.NIGHT_PROBE, self.ix.high_v2g)

        def over_years(slice_label: str | None) -> float:
            if slice_label is None:
                return float("nan")
            return max(self.capacity_factor[("EV_CHARGE_F", slice_label, y)]
                       for y in self.ix.years)

        return {
            "tax_first_year": self.emissions_penalty[(self.ix.emissions[0], self.ix.years[0])],
            "tax_last_year": self.emissions_penalty[(self.ix.emissions[0], self.ix.years[-1])],
            "vmt_last_year": self.annual_demand[("VMT", last)],
            "fmt_last_year": self.annual_demand[("FMT", last)],
            "charge_factor_day": over_years(day),
            "charge_factor_night": over_years(night),
            "demand_gap": self.demand_agreement_gap,
            "day_probe": day,
            "night_probe": night,
        }


class _Defaulted(dict):
    """A parameter that returns its GAMS default for keys with no record.

    GAMS parameters are sparse: an absent record is zero, not an error. Reproducing that
    here keeps the constraints readable - they index the parameter directly instead of
    guarding every lookup.
    """

    def __init__(self, data: dict, default: float) -> None:
        super().__init__(data)
        self.default = default

    def __missing__(self, key):
        return self.default


class _Overridden(_Defaulted):
    """A parameter with scenario overrides layered on top of the instance values."""

    def __init__(self, base: _Defaulted, overrides: dict) -> None:
        super().__init__({**base, **overrides}, base.default)

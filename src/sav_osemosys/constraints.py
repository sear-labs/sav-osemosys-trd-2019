"""Constraints, grouped exactly as `model/osemosys_equations.gms` groups them.

Each function below corresponds to one commented section of the GAMS file, and each
constraint keeps its OSeMOSYS name, so the two can be diffed by eye. Where GAMS uses a
`$` condition to switch a constraint on, that becomes a Python condition on the
comprehension; where it uses one, exactly one branch applies.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

from sav_osemosys.parameters import MILES_FLEET, MILES_PRIVATE, MILES_PUBLIC

if TYPE_CHECKING:  # pragma: no cover
    from sav_osemosys.model import BuiltModel


def add_constraints(b: "BuiltModel") -> None:
    _demand(b)
    _storage(b)
    _capacity_adequacy(b)
    _energy_balance(b)
    _accounting(b)
    _capital_and_salvage(b)
    _operating_costs(b)
    _capacity_limits(b)
    _activity_limits(b)
    _reserve_margin(b)
    _renewable_target(b)
    _emissions(b)
    _study_specific(b)
    _demand_response(b)


def _adjacency(b: "BuiltModel"):
    """Which technologies produce or consume each fuel."""
    producers, consumers = {}, {}
    for t, f in b.indices.produces_tf:
        producers.setdefault(f, []).append(t)
    for t, f in b.indices.consumes_tf:
        consumers.setdefault(f, []).append(t)
    return producers, consumers


def _modes_for(pairs, t, f):
    return [mo for (tt, ff, mo) in pairs if tt == t and ff == f]


# ##### Demand #################################################################

def _demand(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    D = p.dr_types
    m.addConstrs(
        ((p.annual_demand[(f, y)] * p.demand_profile[(f, l, y)]
          - gp.quicksum(p.dr_tag[(f, d)] * v["DemandResponseLevel"][y, d, f, l] for d in D))
         / p.year_split[(l, y)] == v["RateOfDemand"][y, l, f]
         for y in ix.years for l in ix.timeslices for f in ix.fuels),
        name="EQ_SpecifiedDemand1")


# ##### Storage ################################################################

def _storage(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, S, L, T, M = ix.years, ix.storages, ix.timeslices, ix.technologies, ix.modes

    charging = [(t, s, mo) for t in T for s in S for mo in M if p.to_storage[(t, s, mo)]]
    discharging = [(t, s, mo) for t in T for s in S for mo in M if p.from_storage[(t, s, mo)]]

    m.addConstrs((gp.quicksum(v["RateOfActivity"][y, l, t, mo] * p.to_storage[(t, s, mo)]
                              for (t, ss, mo) in charging if ss == s) * p.year_split[(l, y)]
                  == v["StorageCharge"][s, y, l]
                  for s in S for y in Y for l in L), name="S1_StorageCharge")
    m.addConstrs((gp.quicksum(v["RateOfActivity"][y, l, t, mo] * p.from_storage[(t, s, mo)]
                              for (t, ss, mo) in discharging if ss == s) * p.year_split[(l, y)]
                  == v["StorageDischarge"][s, y, l]
                  for s in S for y in Y for l in L), name="S2_StorageDischarge")
    m.addConstrs((v["NetStorageCharge"][s, y, l]
                  == v["StorageCharge"][s, y, l] - v["StorageDischarge"][s, y, l]
                  for s in S for y in Y for l in L), name="S3_NetStorageCharge")

    # S4, per season. GAMS writes StorageLevel(s,y,L--1,r) with the CIRCULAR lag
    # operator, so the first slice of a season follows the last. That closes the day,
    # and S7 below forces the round trip to net to zero.
    for season, slices in (("WNT", ix.wnt), ("SPRFALL", ix.sprfall), ("SUMM", ix.summ)):
        for s in S:
            for y in Y:
                for i, l in enumerate(slices):
                    previous = slices[i - 1]          # wraps at i == 0
                    m.addConstr(
                        v["StorageLevel"][s, y, l]
                        == v["NetStorageCharge"][s, y, l] + v["StorageLevel"][s, y, previous],
                        name=f"StorageLevelCalculation{season}[{s},{y},{l}]")

    m.addConstrs((v["StorageLevel"][s, y, l] / p.days_in_season[l] >= v["StorageLowerLimit"][y, s]
                  for s in S for y in Y for l in L), name="S5_StorageLowerLimit")
    m.addConstrs((v["StorageLevel"][s, y, l] / p.days_in_season[l] <= v["StorageUpperLimit"][y, s]
                  for s in S for y in Y for l in L), name="S6_StorageUpperLimit")
    m.addConstrs((v["AccumulatedStorageCapacity"][y, s] + p.residual_storage[(y, s)]
                  == v["StorageUpperLimit"][y, s] for y in Y for s in S),
                 name="SI1_StorageUpperLimit")
    m.addConstrs((p.min_storage_charge[(s, y)] * v["StorageUpperLimit"][y, s]
                  == v["StorageLowerLimit"][y, s] for y in Y for s in S),
                 name="SI2_StorageLowerLimit")
    m.addConstrs((v["AccumulatedStorageCapacity"][y, s]
                  == gp.quicksum(v["NewStorageCapacity"][yy, s] for yy in Y
                                 if 0 <= p.year_val[y] - p.year_val[yy] < p.storage_life[s])
                  for y in Y for s in S), name="SI3_TotalNewStorage")
    m.addConstrs((p.capital_cost_storage[(y, s)] * v["NewStorageCapacity"][y, s]
                  == v["CapitalInvestmentStorage"][y, s] for y in Y for s in S),
                 name="SI4_UndiscountedCapitalInvestmentStorage")
    m.addConstrs((v["CapitalInvestmentStorage"][y, s]
                  / (1 + p.discount_rate_storage[s]) ** (p.year_val[y] - p.start_year)
                  == v["DiscountedCapitalInvestmentStorage"][y, s] for y in Y for s in S),
                 name="SI5_DiscountingCapitalInvestmentStorage")

    # SI6 / SI7 / SI8: salvage value, branching on whether the asset outlives the
    # horizon and whether the discount rate is positive. Exactly one applies to each pair.
    for y in Y:
        for s in S:
            rate, life = p.discount_rate_storage[s], p.storage_life[s]
            outlives = p.year_val[y] + life - 1 > p.last_year
            capital = p.capital_cost_storage[(y, s)] * v["NewStorageCapacity"][y, s]
            if outlives and rate > 0:
                factor = 1 - (((1 + rate) ** (p.last_year - p.year_val[y] + 1) - 1)
                              / ((1 + rate) ** life - 1))
                m.addConstr(v["SalvageValueStorage"][y, s] == capital * factor,
                            name=f"SI6_SalvageValueStorage[{y},{s}]")
            elif outlives:
                # GAMS: (1 - smax(yy) - YearVal(y) + 1) / life. Transcribed as written,
                # parenthesisation included - it is only reachable at a zero discount
                # rate, which this instance never has.
                factor = (1 - p.last_year - p.year_val[y] + 1) / life
                m.addConstr(v["SalvageValueStorage"][y, s] == capital * factor,
                            name=f"SI7_SalvageValueStorage[{y},{s}]")
            else:
                m.addConstr(v["SalvageValueStorage"][y, s] == 0,
                            name=f"SI8_SalvageValueStorage[{y},{s}]")

    m.addConstrs((v["DiscountedSalvageValueStorage"][y, s]
                  == v["SalvageValueStorage"][y, s]
                  / (1 + p.discount_rate_storage[s]) ** (1 + p.last_year - p.first_year)
                  for y in Y for s in S), name="SI9_SalvageValueStorageDiscounted")
    m.addConstrs((v["TotalDiscountedStorageCost"][y, s]
                  == v["DiscountedCapitalInvestmentStorage"][y, s]
                  - v["DiscountedSalvageValueStorage"][y, s]
                  for y in Y for s in S), name="SI10_TotalDiscountedCostByStorage")

    # Storage addresses diurnal variation only: each season must net to zero.
    m.addConstrs((gp.quicksum(v["NetStorageCharge"][s, y, l] * p.time_slice_in_season[(l, ls)]
                              for l in L) == 0
                  for s in S for y in Y for ls in ix.seasons), name="S7_DiurnalStorage")

    for i, y in enumerate(Y):
        if i == 0:
            continue
        for s in S:
            if p.storage_growth_rate[s] < 1:
                m.addConstr(v["NewStorageCapacity"][y, s]
                            <= v["StorageUpperLimit"][Y[i - 1], s] * p.storage_growth_rate[s]
                            + p.storage_startup[s],
                            name=f"SI11_CapacityGrowthRateStorage[{y},{s}]")


# ##### Capacity adequacy ######################################################

def _capacity_adequacy(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, T, L, M = ix.years, ix.technologies, ix.timeslices, ix.modes

    m.addConstrs((v["AccumulatedNewCapacity"][y, t]
                  == gp.quicksum(v["NewCapacity"][yy, t] for yy in Y
                                 if 0 <= p.year_val[y] - p.year_val[yy] < p.operational_life[t])
                  for y in Y for t in T), name="CBa1_TotalNewCapacity")
    m.addConstrs((v["AccumulatedNewCapacity"][y, t] + p.residual_capacity[(t, y)]
                  == v["TotalCapacityAnnual"][y, t] for y in Y for t in T),
                 name="CBa2_TotalAnnualCapacity")
    m.addConstrs((gp.quicksum(v["RateOfActivity"][y, l, t, mo] for mo in M)
                  == v["RateOfTotalActivity"][y, l, t]
                  for y in Y for t in T for l in L),
                 name="CBa3_TotalActivityOfEachTechnology")
    m.addConstrs((v["RateOfTotalActivity"][y, l, t]
                  <= v["TotalCapacityAnnual"][y, t] * p.capacity_factor[(t, l, y)]
                  * p.capacity_to_activity[t]
                  for y in Y for l in L for t in T if p.peak_tagged[t] != 0),
                 name="CBa4_Constraint_Capacity")
    m.addConstrs((gp.quicksum(v["RateOfTotalActivity"][y, l, t] * p.year_split[(l, y)] for l in L)
                  <= gp.quicksum(v["TotalCapacityAnnual"][y, t] * p.capacity_factor[(t, l, y)]
                                 * p.availability[(t, y)] * p.capacity_to_activity[t] for l in L)
                  for y in Y for t in T), name="CBb1_PlannedMaintenance")


# ##### Energy balance #########################################################

def _energy_balance(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, L, F = ix.years, ix.timeslices, ix.fuels
    producers, consumers = _adjacency(b)

    m.addConstrs((v["RateOfActivity"][y, l, t, mo] * p.output_ratio[(t, f, mo, y)]
                  == v["RateOfProductionByTechnologyByMode"][y, l, t, mo, f]
                  for y in Y for l in L for (t, f, mo) in ix.produces),
                 name="EBa1_RateOfFuelProduction1")
    m.addConstrs((gp.quicksum(v["RateOfProductionByTechnologyByMode"][y, l, t, mo, f]
                              for mo in _modes_for(ix.produces, t, f))
                  == v["RateOfProductionByTechnology"][y, l, t, f]
                  for y in Y for l in L for (t, f) in ix.produces_tf),
                 name="EBa2_RateOfFuelProduction2")
    m.addConstrs((gp.quicksum(v["RateOfProductionByTechnology"][y, l, t, f]
                              for t in producers.get(f, []))
                  == v["RateOfProduction"][y, l, f]
                  for y in Y for l in L for f in F), name="EBa3_RateOfFuelProduction3")

    m.addConstrs((v["RateOfActivity"][y, l, t, mo] * p.input_ratio[(t, f, mo, y)]
                  == v["RateOfUseByTechnologyByMode"][y, l, t, mo, f]
                  for y in Y for l in L for (t, f, mo) in ix.consumes),
                 name="EBa4_RateOfFuelUse1")
    m.addConstrs((gp.quicksum(v["RateOfUseByTechnologyByMode"][y, l, t, mo, f]
                              for mo in _modes_for(ix.consumes, t, f))
                  == v["RateOfUseByTechnology"][y, l, t, f]
                  for y in Y for l in L for (t, f) in ix.consumes_tf),
                 name="EBa5_RateOfFuelUse2")
    m.addConstrs((gp.quicksum(v["RateOfUseByTechnology"][y, l, t, f]
                              for t in consumers.get(f, []))
                  == v["RateOfUse"][y, l, f]
                  for y in Y for l in L for f in F), name="EBa6_RateOfFuelUse3")

    m.addConstrs((v["RateOfProduction"][y, l, f] * p.year_split[(l, y)] == v["Production"][y, l, f]
                  for y in Y for l in L for f in F), name="EBa7_EnergyBalanceEachTS1")
    m.addConstrs((v["RateOfUse"][y, l, f] * p.year_split[(l, y)] == v["Use"][y, l, f]
                  for y in Y for l in L for f in F), name="EBa8_EnergyBalanceEachTS2")
    m.addConstrs((v["RateOfDemand"][y, l, f] * p.year_split[(l, y)] == v["Demand"][y, l, f]
                  for y in Y for l in L for f in F), name="EBa9_EnergyBalanceEachTS3")
    m.addConstrs((v["Production"][y, l, f] >= v["Demand"][y, l, f] + v["Use"][y, l, f]
                  for y in Y for l in L for f in F), name="EBa10_EnergyBalanceEachTS4")

    m.addConstrs((gp.quicksum(v["Production"][y, l, f] for l in L) == v["ProductionAnnual"][y, f]
                  for y in Y for f in F), name="EBb1_EnergyBalanceEachYear1")
    m.addConstrs((gp.quicksum(v["Use"][y, l, f] for l in L) == v["UseAnnual"][y, f]
                  for y in Y for f in F), name="EBb2_EnergyBalanceEachYear2")
    m.addConstrs((v["ProductionAnnual"][y, f]
                  >= v["UseAnnual"][y, f] + p.accumulated_demand[(f, y)]
                  for y in Y for f in F), name="EBb3_EnergyBalanceEachYear3")


# ##### Accounting #############################################################

def _accounting(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, L, T, M = ix.years, ix.timeslices, ix.technologies, ix.modes

    m.addConstrs((v["RateOfProductionByTechnology"][y, l, t, f] * p.year_split[(l, y)]
                  == v["ProductionByTechnology"][y, l, t, f]
                  for y in Y for l in L for (t, f) in ix.produces_tf),
                 name="Acc1_FuelProductionByTechnology")
    m.addConstrs((v["RateOfUseByTechnology"][y, l, t, f] * p.year_split[(l, y)]
                  == v["UseByTechnology"][y, l, t, f]
                  for y in Y for l in L for (t, f) in ix.consumes_tf),
                 name="Acc2_FuelUseByTechnology")
    m.addConstrs((gp.quicksum(v["RateOfActivity"][y, l, t, mo] * p.year_split[(l, y)] for l in L)
                  == v["TotalAnnualTechnologyActivityByMode"][y, t, mo]
                  for y in Y for t in T for mo in M), name="Acc3_AverageAnnualRateOfActivity")
    m.addConstrs((gp.quicksum(v["ProductionByTechnology"][y, l, t, f] for l in L)
                  == v["ProductionByTechnologyAnnual"][y, t, f]
                  for y in Y for (t, f) in ix.produces_tf),
                 name="RE1_FuelProductionByTechnologyAnnual")
    m.addConstrs((gp.quicksum(v["RateOfUseByTechnology"][y, l, t, f] * p.year_split[(l, y)]
                              for l in L)
                  == v["UseByTechnologyAnnual"][y, t, f]
                  for y in Y for (t, f) in ix.consumes_tf),
                 name="RE5_FuelUseByTechnologyAnnual")


# ##### Capital cost and salvage value #########################################

def _capital_and_salvage(b: "BuiltModel") -> None:
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, T = ix.years, ix.technologies

    m.addConstrs((p.capital_cost[(t, y)] * v["NewCapacity"][y, t] == v["CapitalInvestment"][y, t]
                  for y in Y for t in T), name="CC1_UndiscountedCapitalInvestment")
    m.addConstrs((v["CapitalInvestment"][y, t]
                  / (1 + p.discount_rate[t]) ** (p.year_val[y] - p.start_year)
                  == v["DiscountedCapitalInvestment"][y, t]
                  for y in Y for t in T), name="CC2_DiscountingCapitalInvestment")

    for y in Y:
        for t in T:
            rate, life = p.discount_rate[t], p.operational_life[t]
            outlives = p.year_val[y] + life - 1 > p.last_year
            capital = p.capital_cost[(t, y)] * v["NewCapacity"][y, t]
            if outlives and rate > 0:
                factor = 1 - (((1 + rate) ** (p.last_year - p.year_val[y] + 1) - 1)
                              / ((1 + rate) ** life - 1))
                m.addConstr(v["SalvageValue"][y, t] == capital * factor,
                            name=f"SV1_SalvageValue[{y},{t}]")
            elif outlives:
                factor = (1 - p.last_year - p.year_val[y] + 1) / life
                m.addConstr(v["SalvageValue"][y, t] == capital * factor,
                            name=f"SV2_SalvageValue[{y},{t}]")
            else:
                m.addConstr(v["SalvageValue"][y, t] == 0, name=f"SV3_SalvageValue[{y},{t}]")

    m.addConstrs((v["DiscountedSalvageValue"][y, t]
                  == v["SalvageValue"][y, t]
                  / (1 + p.discount_rate[t]) ** (1 + p.last_year - p.first_year)
                  for y in Y for t in T), name="SV4_SalvageValueDiscToStartYr")


# ##### Operating costs ########################################################

def _operating_costs(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, T, M = ix.years, ix.technologies, ix.modes

    m.addConstrs((gp.quicksum(v["TotalAnnualTechnologyActivityByMode"][y, t, mo]
                              * p.variable_cost[(t, mo, y)] for mo in M)
                  == v["AnnualVariableOperatingCost"][y, t]
                  for y in Y for t in T), name="OC1_OperatingCostsVariable")
    m.addConstrs((v["TotalCapacityAnnual"][y, t] * p.fixed_cost[(t, y)]
                  == v["AnnualFixedOperatingCost"][y, t]
                  for y in Y for t in T), name="OC2_OperatingCostsFixedAnnual")
    m.addConstrs((v["AnnualFixedOperatingCost"][y, t] + v["AnnualVariableOperatingCost"][y, t]
                  == v["OperatingCost"][y, t]
                  for y in Y for t in T), name="OC3_OperatingCostsTotalAnnual")
    m.addConstrs((v["OperatingCost"][y, t]
                  / (1 + p.discount_rate[t]) ** (p.year_val[y] - p.first_year + 0.5)
                  == v["DiscountedOperatingCost"][y, t]
                  for y in Y for t in T), name="OC4_DiscountedOperatingCostsTotalAnnual")

    m.addConstrs((v["DiscountedOperatingCost"][y, t] + v["DiscountedCapitalInvestment"][y, t]
                  + v["DiscountedTechnologyEmissionsPenalty"][y, t]
                  - v["DiscountedSalvageValue"][y, t] == v["TotalDiscountedCost"][y, t]
                  for y in Y for t in T), name="TDC1_TotalDiscountedCostByTechnology")


# ##### Capacity limits ########################################################

def _capacity_limits(b: "BuiltModel") -> None:
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, T = ix.years, ix.technologies

    m.addConstrs((v["TotalCapacityAnnual"][y, t] <= p.max_capacity[(t, y)]
                  for y in Y for t in T if p.max_capacity[(t, y)] < 99999),
                 name="TCC1_TotalAnnualMaxCapacity")
    m.addConstrs((v["TotalCapacityAnnual"][y, t] >= p.min_capacity[(t, y)]
                  for y in Y for t in T if p.min_capacity[(t, y)] > 0),
                 name="TCC2_TotalAnnualMinCapacity")
    m.addConstrs((v["NewCapacity"][y, t] <= p.max_investment[(t, y)]
                  for y in Y for t in T if p.max_investment[(t, y)] < 9999),
                 name="NCC1_TotalAnnualMaxNewCapacity")
    m.addConstrs((v["NewCapacity"][y, t] >= p.min_investment[(t, y)]
                  for y in Y for t in T if p.min_investment[(t, y)] > 0),
                 name="NCC2_TotalAnnualMinNewCapacity")


# ##### Activity limits ########################################################

def _activity_limits(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, T, L = ix.years, ix.technologies, ix.timeslices

    m.addConstrs((gp.quicksum(v["RateOfTotalActivity"][y, l, t] * p.year_split[(l, y)] for l in L)
                  == v["TotalTechnologyAnnualActivity"][y, t]
                  for y in Y for t in T), name="AAC1_TotalAnnualTechnologyActivity")
    m.addConstrs((v["TotalTechnologyAnnualActivity"][y, t] <= p.activity_upper[(t, y)]
                  for y in Y for t in T if p.activity_upper[(t, y)] < 9999),
                 name="AAC2_TotalAnnualTechnologyActivityUpperLimit")
    m.addConstrs((v["TotalTechnologyAnnualActivity"][y, t] >= p.activity_lower[(t, y)]
                  for y in Y for t in T if p.activity_lower[(t, y)] > 0),
                 name="AAC3_TotalAnnualTechnologyActivityLowerLimit")
    m.addConstrs((gp.quicksum(v["TotalTechnologyAnnualActivity"][y, t] for y in Y)
                  == v["TotalTechnologyModelPeriodActivity"][t] for t in T),
                 name="TAC1_TotalModelHorizenTechnologyActivity")
    m.addConstrs((v["TotalTechnologyModelPeriodActivity"][t] <= p.period_activity_upper[t]
                  for t in T if p.period_activity_upper[t] < 9999),
                 name="TAC2_TotalModelHorizenActivityUpperLimit")
    m.addConstrs((v["TotalTechnologyModelPeriodActivity"][t] >= p.period_activity_lower[t]
                  for t in T if p.period_activity_lower[t] > 0),
                 name="TAC3_TotalModelHorizenActivityLowerLimit")


# ##### Reserve margin #########################################################

def _reserve_margin(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, L, T, F = ix.years, ix.timeslices, ix.technologies, ix.fuels

    m.addConstrs((gp.quicksum(v["TotalCapacityAnnual"][y, t] * p.reserve_tag_tech[(t, y)]
                              * p.capacity_to_activity[t] for t in T)
                  == v["TotalCapacityInReserveMargin"][y] for y in Y),
                 name="RM1_ReserveMargin_TechnologiesIncluded")
    m.addConstrs((gp.quicksum(v["RateOfProduction"][y, l, f] * p.reserve_tag_fuel[(f, y)]
                              for f in F)
                  == v["DemandNeedingReserveMargin"][y, l]
                  for y in Y for l in L), name="RM2_ReserveMargin_FuelsIncluded")
    m.addConstrs((v["DemandNeedingReserveMargin"][y, l] * p.reserve_margin[y]
                  <= v["TotalCapacityInReserveMargin"][y]
                  for y in Y for l in L), name="RM3_ReserveMargin_Constraint")


# ##### Renewable production target ############################################

def _renewable_target(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, L, F = ix.years, ix.timeslices, ix.fuels

    m.addConstrs((gp.quicksum(v["ProductionByTechnologyAnnual"][y, t, f]
                              * p.re_tag_tech[(t, y)] for (t, f) in ix.produces_tf)
                  == v["TotalREProductionAnnual"][y] for y in Y), name="RE2_TechIncluded")
    m.addConstrs((gp.quicksum(v["RateOfDemand"][y, l, f] * p.year_split[(l, y)]
                              * p.re_tag_fuel[(f, y)] for l in L for f in F)
                  == v["RETotalDemandOfTargetFuelAnnual"][y] for y in Y),
                 name="RE3_FuelIncluded")
    m.addConstrs((p.re_target[y] * v["RETotalDemandOfTargetFuelAnnual"][y]
                  <= v["TotalREProductionAnnual"][y] for y in Y), name="RE4_EnergyConstraint")


# ##### Emissions ##############################################################

def _emissions(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, T, E, M = ix.years, ix.technologies, ix.emissions, ix.modes

    m.addConstrs((p.emission_ratio[(t, e, mo, y)]
                  * v["TotalAnnualTechnologyActivityByMode"][y, t, mo]
                  == v["AnnualTechnologyEmissionByMode"][y, t, e, mo]
                  for y in Y for (t, e, mo) in ix.emits),
                 name="E1_AnnualEmissionProductionByMode")
    emitting_modes = {}
    for t, e, mo in ix.emits:
        emitting_modes.setdefault((t, e), []).append(mo)
    m.addConstrs((gp.quicksum(v["AnnualTechnologyEmissionByMode"][y, t, e, mo]
                              for mo in emitting_modes.get((t, e), []))
                  == v["AnnualTechnologyEmission"][y, t, e]
                  for y in Y for t in T for e in E), name="E2_AnnualEmissionProduction")
    m.addConstrs((v["AnnualTechnologyEmission"][y, t, e] * p.emissions_penalty[(e, y)]
                  == v["AnnualTechnologyEmissionPenaltyByEmission"][y, t, e]
                  for y in Y for t in T for e in E),
                 name="E3_EmissionsPenaltyByTechAndEmission")
    m.addConstrs((gp.quicksum(v["AnnualTechnologyEmissionPenaltyByEmission"][y, t, e] for e in E)
                  == v["AnnualTechnologyEmissionsPenalty"][y, t]
                  for y in Y for t in T), name="E4_EmissionsPenaltyByTechnology")
    m.addConstrs((v["AnnualTechnologyEmissionsPenalty"][y, t]
                  / (1 + p.discount_rate[t]) ** (p.year_val[y] - p.first_year + 0.5)
                  == v["DiscountedTechnologyEmissionsPenalty"][y, t]
                  for y in Y for t in T), name="E5_DiscountedEmissionsPenalty")
    m.addConstrs((gp.quicksum(v["AnnualTechnologyEmission"][y, t, e] for t in T)
                  == v["AnnualEmissions"][y, e] for y in Y for e in E),
                 name="E6_EmissionsAccounting1")
    m.addConstrs((gp.quicksum(v["AnnualEmissions"][y, e] for y in Y)
                  == v["ModelPeriodEmissions"][e] for e in E), name="E7_EmissionsAccounting2")
    m.addConstrs((v["AnnualEmissions"][y, e] + p.exogenous_emission[(e, y)]
                  <= p.emission_limit[(e, y)]
                  for y in Y for e in E), name="E8_AnnualEmissionsLimit")


# ##### Added for this study ###################################################

def _study_specific(b: "BuiltModel") -> None:
    """The equations the paper adds on top of stock OSeMOSYS."""
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, L, T = ix.years, ix.timeslices, ix.technologies

    for i, y in enumerate(Y):
        if i == 0:
            continue
        for t in T:
            if p.growth_rate[t] < 1:
                m.addConstr(v["NewCapacity"][y, t]
                            <= v["TotalCapacityAnnual"][Y[i - 1], t] * p.growth_rate[t]
                            + p.startup_value[t],
                            name=f"NCC3_CapacityGrowthRate[{y},{t}]")

    first = Y[0]
    if first == "2015":
        m.addConstrs((v["NewCapacity"][first, t] == 0 for t in ix.no_new_cap_2015),
                     name="NoCapacity2015")

    # Miles a vehicle can travel in a year, by vehicle class.
    m.addConstrs((v["ProductionByTechnologyAnnual"][y, t, "VMT"]
                  <= v["TotalCapacityAnnual"][y, t] * MILES_PRIVATE
                  for y in Y for t in ix.priv_trans if (t, "VMT") in set(ix.produces_tf)),
                 name="CarMiles")
    m.addConstrs((v["ProductionByTechnologyAnnual"][y, t, "FMT"]
                  <= v["TotalCapacityAnnual"][y, t] * MILES_FLEET
                  for y in Y for t in ix.fleet if (t, "FMT") in set(ix.produces_tf)),
                 name="FleetMiles")
    m.addConstrs((v["ProductionByTechnologyAnnual"][y, t, "PM"]
                  <= v["TotalCapacityAnnual"][y, t] * MILES_PUBLIC
                  for y in Y for t in ix.pub_trans if (t, "PM") in set(ix.produces_tf)),
                 name="PubMiles")

    # Fossil plant must cover a share of peak demand.
    # GAMS sums RateOfUseByTechnology over EVERY technology. Requiring a technology to
    # both produce AND consume ELC drops seven real consumers - EV, EV_F, PHEV and the
    # rest - which loosens the constraint. Not binding at this optimum, but wrong.
    elc_consumers = [t for (t, f) in ix.consumes_tf if f == "ELC"]
    m.addConstrs((gp.quicksum(v["TotalCapacityAnnual"][y, t] for t in ix.nicpp)
                  >= p.nicpp_lower[y]
                  * (v["RateOfDemand"][y, l, "ELC"]
                     + gp.quicksum(v["RateOfUseByTechnology"][y, l, t, "ELC"]
                                   for t in elc_consumers))
                  / p.capacity_to_activity["COALPP"]
                  for y in Y for l in L), name="FFPowerPlantCapAtPeakDemand")

    # Vehicles draw their electricity through the discharge technologies.
    for driver, discharger in (("EV", "EV_DISCHARGE"), ("EV_F", "EV_DISCHARGE_F")):
        if (driver, "ELC") in set(ix.consumes_tf) and (discharger, "ELC") in set(ix.produces_tf):
            m.addConstrs((v["UseByTechnology"][y, l, driver, "ELC"]
                          == v["ProductionByTechnology"][y, l, discharger, "ELC"]
                          for y in Y for l in L), name=f"{driver}_Driving")

    # Vehicle-to-grid and charger capacity are tied to the vehicle fleet they serve.
    for v2g, charger, battery, vehicle in (
        ("V2G", "EV_CHARGE", "EV_BAT", "EV"),
        ("V2G_F", "EV_CHARGE_F", "EV_BAT_F", "EV_F"),
    ):
        m.addConstrs((v["NewCapacity"][y, v2g] <= 0.006 * v["NewCapacity"][y, vehicle]
                      for y in Y), name=f"V2GCapacityConstraint1[{v2g}]")
        m.addConstrs((v["NewCapacity"][y, charger] == 0.006 * v["NewCapacity"][y, vehicle]
                      for y in Y), name=f"V2GCapacityConstraint2[{charger}]")
        m.addConstrs((v["NewStorageCapacity"][y, battery]
                      == 0.000072 * v["NewCapacity"][y, vehicle]
                      for y in Y), name=f"V2GCapacityConstraint3[{battery}]")

    # Vehicle miles are produced in proportion to the fleet that exists.
    for t in ix.priv_trans:
        if (t, "VMT") not in set(ix.produces_tf):
            continue
        m.addConstrs((v["ProductionByTechnology"][y, l, t, "VMT"]
                      == v["TotalCapacityAnnual"][y, t] * p.annual_demand[("VMT", y)]
                      * p.demand_profile[("VMT", l, y)] / p.fleet_size[y]
                      for y in Y for l in L), name=f"VehicleVMTProduction[{t}]")


# ##### Demand response ########################################################

def _demand_response(b: "BuiltModel") -> None:
    import gurobipy as gp
    m, ix, p, v = b.model, b.indices, b.parameters, b.var
    Y, L, F, D = ix.years, ix.timeslices, ix.fuels, p.dr_types

    m.addConstrs((v["DemandResponseLevel"][y, d, f, l] <= p.dr_max[(y, d, f, l)]
                  for y in Y for d in D for f in F for l in L), name="DR1_LevelUpperLimit")
    m.addConstrs((v["DemandResponseLevel"][y, d, f, l] >= p.dr_min[(y, d, f, l)]
                  for y in Y for d in D for f in F for l in L), name="DR2_LevelLowerLimit")
    m.addConstrs((gp.quicksum(v["DemandResponseLevel"][y, d, f, l] * p.dr_cost[(y, d, f)]
                              for f in F for d in D)
                  == v["DemandResponseCost"][y, l] for y in Y for l in L), name="DR3_Cost")
    m.addConstrs((v["DemandResponseAnnualCost"][y]
                  == gp.quicksum(v["DemandResponseCost"][y, l] for l in L)
                  for y in Y), name="DR4_AnnualCost")
    m.addConstrs((v["DiscountedDemandResponseAnnualCost"][y]
                  == v["DemandResponseAnnualCost"][y]
                  / (1 + p.demand_response_discount[b.parameters.region])
                  ** (p.year_val[y] - p.start_year)
                  for y in Y), name="DR5_DiscountedAnnualCost")

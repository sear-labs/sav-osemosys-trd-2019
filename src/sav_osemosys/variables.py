"""Decision variables.

Named exactly as OSeMOSYS names them, so this file and `osemosys_equations.gms` can be
read side by side. All are non-negative except `z` and the two cost differences, which
are free.

The definitional variables - rates, annual totals, cost components - are kept rather than
substituted out. They are what makes the formulation legible against the published model,
and presolve eliminates them at no cost to the answer.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from sav_osemosys.model import BuiltModel


def add_variables(b: "BuiltModel") -> None:
    """Every decision variable, named as OSeMOSYS names it.

    All are non-negative except `z`, the objective, which is free. The definitional
    variables (rates, annual totals, cost components) are kept rather than substituted
    out: they are what makes the formulation readable against the published model, and
    presolve eliminates them at no cost to the answer.
    """
    import gurobipy as gp

    m, ix = b.model, b.indices
    Y, L, T, F, S, E, M = (ix.years, ix.timeslices, ix.technologies, ix.fuels,
                           ix.storages, ix.emissions, ix.modes)
    v = b.var

    def add(name, keys, lb=0.0):
        return m.addVars(keys, lb=lb, name=name)

    # -- activity -------------------------------------------------------------
    v["RateOfActivity"] = add("RateOfActivity", [(y, l, t, mo) for y in Y for l in L
                                                 for t in T for mo in M])
    v["RateOfTotalActivity"] = add("RateOfTotalActivity",
                                   [(y, l, t) for y in Y for l in L for t in T])
    v["TotalAnnualTechnologyActivityByMode"] = add(
        "TotalAnnualTechnologyActivityByMode",
        [(y, t, mo) for y in Y for t in T for mo in M])
    v["TotalTechnologyAnnualActivity"] = add("TotalTechnologyAnnualActivity",
                                             [(y, t) for y in Y for t in T])
    v["TotalTechnologyModelPeriodActivity"] = add("TotalTechnologyModelPeriodActivity",
                                                  list(T))

    # -- capacity -------------------------------------------------------------
    v["NewCapacity"] = add("NewCapacity", [(y, t) for y in Y for t in T])
    v["AccumulatedNewCapacity"] = add("AccumulatedNewCapacity",
                                      [(y, t) for y in Y for t in T])
    v["TotalCapacityAnnual"] = add("TotalCapacityAnnual", [(y, t) for y in Y for t in T])

    # -- production and use, over the pairs that exist ------------------------
    prod_ytlmf = [(y, l, t, mo, f) for y in Y for l in L for (t, f, mo) in ix.produces]
    use_ytlmf = [(y, l, t, mo, f) for y in Y for l in L for (t, f, mo) in ix.consumes]
    prod_ytlf = [(y, l, t, f) for y in Y for l in L for (t, f) in ix.produces_tf]
    use_ytlf = [(y, l, t, f) for y in Y for l in L for (t, f) in ix.consumes_tf]

    v["RateOfProductionByTechnologyByMode"] = add(
        "RateOfProductionByTechnologyByMode", prod_ytlmf)
    v["RateOfUseByTechnologyByMode"] = add("RateOfUseByTechnologyByMode", use_ytlmf)
    v["RateOfProductionByTechnology"] = add("RateOfProductionByTechnology", prod_ytlf)
    v["RateOfUseByTechnology"] = add("RateOfUseByTechnology", use_ytlf)
    v["ProductionByTechnology"] = add("ProductionByTechnology", prod_ytlf)
    v["UseByTechnology"] = add("UseByTechnology", use_ytlf)
    v["ProductionByTechnologyAnnual"] = add(
        "ProductionByTechnologyAnnual", [(y, t, f) for y in Y for (t, f) in ix.produces_tf])
    v["UseByTechnologyAnnual"] = add(
        "UseByTechnologyAnnual", [(y, t, f) for y in Y for (t, f) in ix.consumes_tf])

    ylf = [(y, l, f) for y in Y for l in L for f in F]
    for name in ("RateOfProduction", "RateOfUse", "RateOfDemand",
                 "Production", "Use", "Demand"):
        v[name] = add(name, ylf)
    for name in ("ProductionAnnual", "UseAnnual"):
        v[name] = add(name, [(y, f) for y in Y for f in F])

    # -- costs ----------------------------------------------------------------
    yt = [(y, t) for y in Y for t in T]
    for name in ("CapitalInvestment", "DiscountedCapitalInvestment",
                 "SalvageValue", "DiscountedSalvageValue",
                 "AnnualVariableOperatingCost", "AnnualFixedOperatingCost",
                 "OperatingCost", "DiscountedOperatingCost"):
        v[name] = add(name, yt)
    # Total discounted cost is a difference and can be negative.
    v["TotalDiscountedCost"] = add("TotalDiscountedCost", yt, lb=-gp.GRB.INFINITY)

    # -- emissions ------------------------------------------------------------
    v["AnnualTechnologyEmissionByMode"] = add(
        "AnnualTechnologyEmissionByMode",
        [(y, t, e, mo) for y in Y for (t, e, mo) in ix.emits])
    yte = [(y, t, e) for y in Y for t in T for e in E]
    v["AnnualTechnologyEmission"] = add("AnnualTechnologyEmission", yte)
    v["AnnualTechnologyEmissionPenaltyByEmission"] = add(
        "AnnualTechnologyEmissionPenaltyByEmission", yte)
    v["AnnualTechnologyEmissionsPenalty"] = add("AnnualTechnologyEmissionsPenalty", yt)
    v["DiscountedTechnologyEmissionsPenalty"] = add(
        "DiscountedTechnologyEmissionsPenalty", yt)
    v["AnnualEmissions"] = add("AnnualEmissions", [(y, e) for y in Y for e in E])
    v["ModelPeriodEmissions"] = add("ModelPeriodEmissions", list(E))

    # -- storage --------------------------------------------------------------
    syl = [(s, y, l) for s in S for y in Y for l in L]
    v["StorageCharge"] = add("StorageCharge", syl)
    v["StorageDischarge"] = add("StorageDischarge", syl)
    v["NetStorageCharge"] = add("NetStorageCharge", syl, lb=-gp.GRB.INFINITY)
    v["StorageLevel"] = add("StorageLevel", syl)
    ys = [(y, s) for y in Y for s in S]
    for name in ("NewStorageCapacity", "AccumulatedStorageCapacity",
                 "StorageUpperLimit", "StorageLowerLimit",
                 "CapitalInvestmentStorage", "DiscountedCapitalInvestmentStorage",
                 "SalvageValueStorage", "DiscountedSalvageValueStorage"):
        v[name] = add(name, ys)
    v["TotalDiscountedStorageCost"] = add("TotalDiscountedStorageCost", ys,
                                          lb=-gp.GRB.INFINITY)

    # -- reserve margin and renewable target ----------------------------------
    v["TotalCapacityInReserveMargin"] = add("TotalCapacityInReserveMargin", list(Y))
    v["DemandNeedingReserveMargin"] = add("DemandNeedingReserveMargin",
                                          [(y, l) for y in Y for l in L])
    v["TotalREProductionAnnual"] = add("TotalREProductionAnnual", list(Y))
    v["RETotalDemandOfTargetFuelAnnual"] = add("RETotalDemandOfTargetFuelAnnual", list(Y))

    # -- demand response ------------------------------------------------------
    D = b.parameters.dr_types
    v["DemandResponseLevel"] = add(
        "DemandResponseLevel",
        [(y, d, f, l) for y in Y for d in D for f in F for l in L])
    v["DemandResponseCost"] = add("DemandResponseCost", [(y, l) for y in Y for l in L])
    v["DemandResponseAnnualCost"] = add("DemandResponseAnnualCost", list(Y))
    v["DiscountedDemandResponseAnnualCost"] = add(
        "DiscountedDemandResponseAnnualCost", list(Y))

    v["z"] = m.addVar(lb=-gp.GRB.INFINITY, name="z")

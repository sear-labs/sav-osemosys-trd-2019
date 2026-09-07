"""The objective: total discounted system cost.

One equation in GAMS -

    cost.. z =e= sum((y,t,r), TotalDiscountedCost(y,t,r))
               + sum((y,r), DiscountedDemandResponseAnnualCost(y,r))
               + sum((y,s,r), TotalDiscountedStorageCost(y,s,r));

- and it is presented here in its three parts because at this scale a single summation
  over millions of terms tells a reader nothing about what the number is made of. That is
  a decision about *this* model's size, not a general rule: a smaller model is clearer as
  one expression.

`components()` returns the same split evaluated at the solution, which is what lets the
verification notebook reconstruct the published objective from its parts without a solver.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from sav_osemosys.model import BuiltModel


def add_objective(b: "BuiltModel") -> None:
    import gurobipy as gp

    m, ix, v = b.model, b.indices, b.var

    # Part 1: technology cost - capital, operating and emissions penalty, less salvage.
    technology_cost = gp.quicksum(
        v["TotalDiscountedCost"][y, t] for y in ix.years for t in ix.technologies)

    # Part 2: storage - capital less salvage. Storage carries no operating cost here.
    storage_cost = gp.quicksum(
        v["TotalDiscountedStorageCost"][y, s] for y in ix.years for s in ix.storages)

    # Part 3: demand response, paid for shifting load out of a timeslice.
    demand_response_cost = gp.quicksum(
        v["DiscountedDemandResponseAnnualCost"][y] for y in ix.years)

    m.addConstr(v["z"] == technology_cost + storage_cost + demand_response_cost, name="cost")
    m.setObjective(v["z"], gp.GRB.MINIMIZE)


def components(b: "BuiltModel") -> dict[str, float]:
    """The objective split into its parts, evaluated at the current solution.

    Reported rather than asserted: the parts must sum to the objective, and that identity
    is checked, but which part dominates is a result and differs by scenario.
    """
    ix, v = b.indices, b.var
    technology = sum(v["TotalDiscountedCost"][y, t].X
                     for y in ix.years for t in ix.technologies)
    storage = sum(v["TotalDiscountedStorageCost"][y, s].X
                  for y in ix.years for s in ix.storages)
    demand_response = sum(v["DiscountedDemandResponseAnnualCost"][y].X for y in ix.years)
    total = technology + storage + demand_response
    return {
        "technology": technology,
        "storage": storage,
        "demand_response": demand_response,
        "total": total,
        "objective": b.model.ObjVal,
        "residual": total - b.model.ObjVal,
    }


def cost_breakdown(b: "BuiltModel") -> dict[str, float]:
    """Technology cost decomposed further, for the verification notebook.

    This is the decomposition a reader can rebuild from the shipped solution and the
    instance CSVs, which is how the published objective is checked without a solver.
    """
    ix, v = b.indices, b.var
    yt = [(y, t) for y in ix.years for t in ix.technologies]
    return {
        "discounted_capital": sum(v["DiscountedCapitalInvestment"][y, t].X for y, t in yt),
        "discounted_operating": sum(v["DiscountedOperatingCost"][y, t].X for y, t in yt),
        "discounted_emissions_penalty": sum(
            v["DiscountedTechnologyEmissionsPenalty"][y, t].X for y, t in yt),
        "discounted_salvage": sum(v["DiscountedSalvageValue"][y, t].X for y, t in yt),
        "storage_capital": sum(v["DiscountedCapitalInvestmentStorage"][y, s].X
                               for y in ix.years for s in ix.storages),
        "storage_salvage": sum(v["DiscountedSalvageValueStorage"][y, s].X
                               for y in ix.years for s in ix.storages),
        "demand_response": sum(v["DiscountedDemandResponseAnnualCost"][y].X for y in ix.years),
    }

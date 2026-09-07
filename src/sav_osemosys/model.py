"""The OSeMOSYS ATX model in gurobipy.

A faithful port of `model/osemosys_equations.gms`. Variable and constraint names are the
OSeMOSYS ones so the two can be read side by side; the section headings below match the
headings in the GAMS file.

The port differs from GAMS in exactly one way, and it is not a modelling difference:
variables are created only over combinations that exist. GAMS generates
`ProductionByTechnology` for every (technology, fuel) pair, including (coal plant,
gasoline); 51 of 765 pairs actually produce. Declining to create a variable that can only
ever be zero is what presolve would do anyway. See `sets.Indices`.

Structure, which is also the order the walkthrough notebook presents it in:

    build()            assembles the whole model
      variables.py     decision variables
      constraints.py   grouped by OSeMOSYS section
      objective.py     total discounted cost, in its parts
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from sav_osemosys.constraints import add_constraints
from sav_osemosys.data import Instance
from sav_osemosys.objective import add_objective
from sav_osemosys.parameters import Parameters, Scenario
from sav_osemosys.sets import Indices, build_indices
from sav_osemosys.variables import add_variables

if TYPE_CHECKING:  # pragma: no cover
    import gurobipy as gp


@dataclass
class BuiltModel:
    """A built model plus the pieces needed to read its solution back."""

    model: "gp.Model"
    indices: Indices
    parameters: Parameters
    scenario: Scenario
    var: dict[str, object] = field(default_factory=dict)

    @property
    def objective_value(self) -> float:
        return self.model.ObjVal

    def size(self) -> str:
        m = self.model
        m.update()
        return (f"{m.NumVars:,} variables, {m.NumConstrs:,} constraints, "
                f"{m.NumNZs:,} nonzeros")


def build(
    inst: Instance | None = None,
    scenario: Scenario | None = None,
    *,
    indices: Indices | None = None,
    years: list[str] | None = None,
    timeslices: list[str] | None = None,
    env: "gp.Env | None" = None,
    name: str = "osemosys_atx",
) -> BuiltModel:
    """Build one scenario of the ATX model.

    `years` and `timeslices` restrict the instance, which is how the example notebook
    produces something an open-source solver can handle. The formulation is identical
    either way - the reduction is a smaller index set, not a different model.
    """
    import gurobipy as gp

    inst = inst or Instance()
    scenario = scenario or Scenario(0)
    ix = indices or build_indices(inst, years=years, timeslices=timeslices)
    par = Parameters(inst, ix, scenario)

    m = gp.Model(name, env=env) if env is not None else gp.Model(name)
    built = BuiltModel(model=m, indices=ix, parameters=par, scenario=scenario)

    add_variables(built)
    add_constraints(built)
    add_objective(built)
    m.update()
    return built



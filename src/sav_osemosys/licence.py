"""Find a Gurobi licence, wherever this is running. One copy, used everywhere.

Scripts and notebooks need the same thing, so they call the same function. Two copies of
credential-handling logic is the arrangement where one of them quietly stops matching the
other, and the one that breaks is the one nobody runs.

Lookup order, and why:

  1. ``GRB_WLSACCESSID`` / ``GRB_WLSSECRET`` / ``GRB_LICENSEID`` in the environment
  2. the same three as Colab secrets
  3. whatever Gurobi finds by itself - a ``gurobi.lic`` file, typically

Web License Service credentials come first because they are the only kind that works in a
container. A named-user academic licence is node-locked, so it works on a laptop and never
in Colab, where the machine differs every session.

**Never a literal.** A key committed to a repository is exposed the moment the repository
is shared, and deleting it later does not remove it from history.

Nothing here is required to use this project. The verification notebook needs no licence
at all, and the example notebook solves with HiGHS.
"""
from __future__ import annotations

import os
from dataclasses import dataclass

__all__ = ["Licence", "find_licence", "gurobi_env"]

KEYS = ("WLSACCESSID", "WLSSECRET", "LICENSEID")

# Past the 2,000-variable cap on the licence bundled with the pip package. Measured:
# 1,500 variables is accepted and 2,500 is refused, and the smallest useful version of
# this model is 4,726 - so the bundled licence cannot build it at any reduction.
PROBE_SIZE = 3000


@dataclass
class Licence:
    """What was found, and what it can do."""

    kind: str                 # "wls" | "local" | "none"
    source: str               # where the credentials came from
    usable: bool              # can it build a model past the size-limited cap?
    detail: str = ""

    def __str__(self) -> str:
        verdict = "usable" if self.usable else "NOT usable for this model"
        return f"Gurobi {self.kind} licence from {self.source}: {verdict}" + (
            f" ({self.detail})" if self.detail else "")


def _credentials() -> tuple[dict[str, str], str] | tuple[None, str]:
    found = {k: os.environ.get("GRB_" + k) for k in KEYS}
    if all(found.values()):
        return found, "environment variables"
    try:
        from google.colab import userdata  # type: ignore[import-not-found]

        found = {k: userdata.get("GRB_" + k) for k in KEYS}
        if all(found.values()):
            return found, "Colab secrets"
    except Exception:
        pass
    return None, "no WLS credentials found"


def gurobi_env(quiet: bool = True):
    """A Gurobi Env built from WLS credentials, or None to use the default licence.

    Returns None rather than raising when there are no credentials: "no WLS" is the normal
    case for someone with a `gurobi.lic` on their own machine, not an error.
    """
    creds, _ = _credentials()
    if creds is None:
        return None
    import gurobipy as gp

    params = {"WLSACCESSID": creds["WLSACCESSID"], "WLSSECRET": creds["WLSSECRET"],
              # Colab's userdata.get returns a string; LICENSEID must be an int.
              "LICENSEID": int(creds["LICENSEID"])}
    if quiet:
        params["OutputFlag"] = 0
    return gp.Env(params=params)


def find_licence() -> Licence:
    """Report what is available, having actually tried it.

    Builds a model past the size-limited cap rather than reading a version string,
    because the question is not "is gurobipy installed" but "can it build this model".
    """
    try:
        import gurobipy as gp
    except ImportError:
        return Licence("none", "gurobipy is not installed", usable=False,
                       detail="pip install gurobipy, or use HiGHS")

    creds, where = _credentials()
    kind = "wls" if creds else "local"
    env = None
    try:
        env = gurobi_env()
        model = gp.Model(env=env) if env is not None else gp.Model()
        model.Params.OutputFlag = 0
        x = model.addVars(PROBE_SIZE, ub=1.0)
        # Constraints AND a solve, both required. The size-limited licence does not
        # refuse addVars - it refuses at OPTIMIZE. A probe that only declares variables
        # reports "usable" under a licence that then rejects the real model, which is a
        # check agreeing with itself. Measured: addVars(3000) succeeds where
        # optimize() on 2,500 variables raises "Model too large".
        model.addConstrs((x[i] <= 1 for i in range(PROBE_SIZE)))
        model.setObjective(gp.quicksum(x.values()), gp.GRB.MAXIMIZE)
        model.optimize()
        usable = model.Status == gp.GRB.OPTIMAL
        model.dispose()
        if not usable:
            return Licence(kind, where if creds else "gurobi.lic or default", usable=False,
                           detail=f"probe of {PROBE_SIZE:,} variables did not solve")
        return Licence(kind, where if creds else "gurobi.lic or default", usable=True,
                       detail=f"solved {PROBE_SIZE:,} variables")
    except Exception as exc:
        message = str(exc).strip().splitlines()[0] if str(exc) else type(exc).__name__
        return Licence(kind, where if creds else "gurobi.lic or default", usable=False,
                       detail=message[:120])
    finally:
        if env is not None:
            try:
                env.dispose()
            except Exception:
                pass

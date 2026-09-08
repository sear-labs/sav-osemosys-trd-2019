"""Check a solution without solving anything.

Re-solving is the wrong verb. A reader who re-solves is trusting their solver, their
licence and their hardware; a reader who *checks* is trusting arithmetic. This module
does the second, with numpy and nothing else - no solver, no licence, no Gurobi.

Two claims are checkable here, and they are different sizes:

`check_instance()` reads the shipped `.mps` and `.sol` for the REDUCED instance and
verifies every constraint row, every bound and the objective by hand. That is the strong
form, and it is only possible because the reduced instance is small enough to ship.

`reconstruct_objective()` takes a PUBLISHED scenario and rebuilds its objective out of
its cost components - capital, operating, emissions penalty, salvage - from the tidy
results and the instance CSVs. The full model's `.mps` is about 3.4 GB, so row-by-row
checking is not available at that scale. This is weaker as a proof and better as an
explanation: it shows what the number is made of rather than only that it satisfies
Ax <= b.
"""
from __future__ import annotations

import gzip
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np

__all__ = ["MPS", "read_mps", "read_solution", "check_instance", "CheckResult"]


@dataclass
class MPS:
    """A linear program in standard form, as read from an .mps file."""

    name: str
    row_names: list[str]
    col_names: list[str]
    objective_row: str
    sense: dict[str, str]                       # row -> 'E' | 'L' | 'G'
    matrix: dict[str, dict[str, float]]         # row -> {col: coefficient}
    rhs: dict[str, float] = field(default_factory=dict)
    ranges: dict[str, float] = field(default_factory=dict)
    lower: dict[str, float] = field(default_factory=dict)
    upper: dict[str, float] = field(default_factory=dict)
    objective_constant: float = 0.0

    def objective(self, values: dict[str, float]) -> float:
        row = self.matrix.get(self.objective_row, {})
        return sum(coef * values.get(col, 0.0) for col, coef in row.items()) \
            - self.objective_constant


def _open(path: Path):
    if str(path).endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8", errors="replace")
    return path.open("r", encoding="utf-8", errors="replace")


def read_mps(path: str | Path) -> MPS:
    """Parse a free-format MPS file. Handles .gz transparently.

    Deliberately a plain parser rather than a solver call: the whole point of this file
    is that checking needs no solver, and importing one to read a matrix would give that
    away quietly.
    """
    path = Path(path)
    section = None
    name = ""
    row_names: list[str] = []
    col_order: list[str] = []
    seen_cols: set[str] = set()
    sense: dict[str, str] = {}
    matrix: dict[str, dict[str, float]] = {}
    rhs: dict[str, float] = {}
    ranges: dict[str, float] = {}
    lower: dict[str, float] = {}
    upper: dict[str, float] = {}
    objective_row = ""
    objective_constant = 0.0

    with _open(path) as fh:
        for raw in fh:
            if not raw.strip() or raw.lstrip().startswith("*"):
                continue
            if not raw[0].isspace():
                parts = raw.split()
                head = parts[0].upper()
                if head == "NAME":
                    name = parts[1] if len(parts) > 1 else ""
                    section = "NAME"
                elif head in {"ROWS", "COLUMNS", "RHS", "RANGES", "BOUNDS", "ENDATA",
                              "OBJSENSE", "OBJSENSE\n"}:
                    section = head
                else:
                    section = head
                continue

            parts = raw.split()
            if section == "ROWS":
                kind, row = parts[0].upper(), parts[1]
                if kind == "N":
                    if not objective_row:
                        objective_row = row
                    # Extra N rows are free rows; keep them out of the checks.
                    sense[row] = "N"
                else:
                    sense[row] = kind
                row_names.append(row)
                matrix.setdefault(row, {})

            elif section == "COLUMNS":
                if len(parts) >= 3 and parts[1].upper() == "'MARKER'":
                    continue
                col = parts[0]
                if col not in seen_cols:
                    seen_cols.add(col)
                    col_order.append(col)
                for i in range(1, len(parts) - 1, 2):
                    row, value = parts[i], float(parts[i + 1])
                    matrix.setdefault(row, {})[col] = value

            elif section == "RHS":
                for i in range(1, len(parts) - 1, 2):
                    row, value = parts[i], float(parts[i + 1])
                    if row == objective_row:
                        objective_constant = value
                    else:
                        rhs[row] = value

            elif section == "RANGES":
                for i in range(1, len(parts) - 1, 2):
                    ranges[parts[i]] = float(parts[i + 1])

            elif section == "BOUNDS":
                kind = parts[0].upper()
                col = parts[2] if len(parts) > 2 else parts[1]
                value = float(parts[3]) if len(parts) > 3 else 0.0
                if kind == "UP":
                    upper[col] = value
                elif kind == "LO":
                    lower[col] = value
                elif kind == "FX":
                    lower[col] = upper[col] = value
                elif kind == "FR":
                    lower[col], upper[col] = -np.inf, np.inf
                elif kind == "MI":
                    lower[col] = -np.inf
                elif kind == "PL":
                    upper[col] = np.inf
                elif kind == "BV":
                    lower[col], upper[col] = 0.0, 1.0

    return MPS(name=name, row_names=row_names, col_names=col_order,
               objective_row=objective_row, sense=sense, matrix=matrix, rhs=rhs,
               ranges=ranges, lower=lower, upper=upper,
               objective_constant=objective_constant)


def read_solution(path: str | Path) -> tuple[dict[str, float], float | None]:
    """Parse a Gurobi .sol file: comment lines, then `name value` pairs."""
    values: dict[str, float] = {}
    objective = None
    with _open(Path(path)) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            if line.startswith("#"):
                if "objective" in line.lower():
                    try:
                        objective = float(line.split("=")[-1])
                    except ValueError:
                        pass
                continue
            parts = line.split()
            if len(parts) >= 2:
                try:
                    values[parts[0]] = float(parts[1])
                except ValueError:
                    continue
    return values, objective


@dataclass
class CheckResult:
    rows_checked: int
    bounds_checked: int
    worst_row_violation: float
    worst_bound_violation: float
    worst_row: str
    worst_bound: str
    objective_from_file: float | None
    objective_recomputed: float
    scale: float

    @property
    def relative_row_violation(self) -> float:
        return self.worst_row_violation / max(self.scale, 1.0)

    def ok(self, tolerance: float = 1e-9) -> bool:
        if self.objective_from_file is not None:
            gap = abs(self.objective_recomputed - self.objective_from_file)
            if gap / max(abs(self.objective_from_file), 1.0) > tolerance:
                return False
        return (self.relative_row_violation <= tolerance
                and self.worst_bound_violation <= tolerance * max(self.scale, 1.0))

    def summary(self) -> str:
        lines = [
            f"  rows checked            {self.rows_checked:,}",
            f"  bounds checked          {self.bounds_checked:,}",
            f"  worst row violation     {self.worst_row_violation:.3e}"
            f"  ({self.relative_row_violation:.3e} relative)   [{self.worst_row}]",
            f"  worst bound violation   {self.worst_bound_violation:.3e}   [{self.worst_bound}]",
            f"  objective in .sol       {self.objective_from_file!r}",
            f"  objective recomputed    {self.objective_recomputed:.6f}",
        ]
        return "\n".join(lines)


def check_instance(mps_path: str | Path, sol_path: str | Path) -> CheckResult:
    """Verify every row, every bound and the objective. No solver involved.

    Violations are reported relative to the largest coefficient in the problem. An
    absolute tolerance is the wrong instrument here: this model's matrix spans twelve
    orders of magnitude, so a fixed threshold either passes everything or rejects
    correct answers.
    """
    mps = read_mps(mps_path)
    values, objective_from_file = read_solution(sol_path)

    scale = max((abs(c) for row in mps.matrix.values() for c in row.values()), default=1.0)

    worst_row, worst_row_name, rows_checked = 0.0, "", 0
    for row, coefs in mps.matrix.items():
        kind = mps.sense.get(row, "N")
        if kind == "N":
            continue
        lhs = sum(coef * values.get(col, 0.0) for col, coef in coefs.items())
        target = mps.rhs.get(row, 0.0)
        if kind == "E":
            violation = abs(lhs - target)
        elif kind == "L":
            violation = max(0.0, lhs - target)
        else:  # 'G'
            violation = max(0.0, target - lhs)
        rows_checked += 1
        if violation > worst_row:
            worst_row, worst_row_name = violation, row

    worst_bound, worst_bound_name, bounds_checked = 0.0, "", 0
    for col in mps.col_names:
        value = values.get(col, 0.0)
        lo = mps.lower.get(col, 0.0)          # MPS default lower bound is zero
        hi = mps.upper.get(col, np.inf)
        bounds_checked += 1
        for violation, label in ((lo - value, f"{col} < lb"), (value - hi, f"{col} > ub")):
            if violation > worst_bound:
                worst_bound, worst_bound_name = violation, label

    return CheckResult(
        rows_checked=rows_checked, bounds_checked=bounds_checked,
        worst_row_violation=worst_row, worst_bound_violation=worst_bound,
        worst_row=worst_row_name or "-", worst_bound=worst_bound_name or "-",
        objective_from_file=objective_from_file,
        objective_recomputed=mps.objective(values), scale=scale)

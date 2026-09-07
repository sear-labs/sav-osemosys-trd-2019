"""Load the model instance: local files first, then the published CSVs on GitHub.

Every artifact in this repository reads its data through here - the gurobipy model, the
GAMS reconciliation, and both notebooks - so there is exactly one copy of the instance
and no chance of two of them quietly disagreeing.

The lookup order is deliberate:

  1. an explicit path, if the caller passes one
  2. ``SAV_OSEMOSYS_DATA`` in the environment
  3. ``data/instance/`` found by walking up from this file, then from the working
     directory - the normal case for anyone who cloned the repository
  4. the raw CSVs on GitHub, cached under the user's cache directory

Step 4 is what lets a Colab notebook run with nothing checked out. It is last, not
first, so that someone editing the data locally sees their own edits rather than
silently testing against `main`.

Nothing here needs a solver or a licence.
"""
from __future__ import annotations

import os
import urllib.error
import urllib.request
from functools import lru_cache
from pathlib import Path

import pandas as pd

__all__ = ["Instance", "instance_dir", "load_symbol", "RAW_BASE"]

REPO = "sear-labs/sav-osemosys-trd-2019"
BRANCH = "main"
RAW_BASE = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}/data/instance"

_ENV_VAR = "SAV_OSEMOSYS_DATA"
_MARKER = "_manifest.csv"       # every valid instance directory carries this


def _cache_dir() -> Path:
    base = os.environ.get("XDG_CACHE_HOME") or os.environ.get("LOCALAPPDATA")
    root = Path(base) if base else Path.home() / ".cache"
    return root / "sav-osemosys" / BRANCH


def _looks_like_instance(path: Path) -> bool:
    return (path / _MARKER).is_file()


@lru_cache(maxsize=1)
def instance_dir(explicit: str | Path | None = None) -> Path | None:
    """Find a local instance directory, or None if there is not one.

    Returning None rather than raising is deliberate: "no local copy" is the normal
    state in Colab, not an error, and the caller falls through to the network.
    """
    # An explicitly requested location is honoured or refused - never silently
    # replaced by a different copy of the data. Falling through here would mean a
    # caller who pointed at a modified instance got `main`'s numbers instead and was
    # told nothing, which is the worst of the available behaviours.
    for source, value in ((f"the {_ENV_VAR} environment variable", os.environ.get(_ENV_VAR)),
                          ("the data_dir argument", explicit)):
        if not value:
            continue
        path = Path(value)
        if not path.is_dir():
            raise NotADirectoryError(f"{source} points at {path}, which is not a directory")
        if not _looks_like_instance(path):
            raise FileNotFoundError(
                f"{source} points at {path}, which has no {_MARKER} and so is not an "
                f"instance directory. Run scripts/export_instance.py to build one."
            )
        return path

    for start in (Path(__file__).resolve(), Path.cwd().resolve()):
        for parent in [start, *start.parents]:
            cand = parent / "data" / "instance"
            if cand.is_dir() and _looks_like_instance(cand):
                return cand
    return None


def _fetch(symbol: str) -> Path:
    """Download one symbol's CSV to the cache and return the local path."""
    cache = _cache_dir()
    cache.mkdir(parents=True, exist_ok=True)
    target = cache / f"{symbol}.csv"
    if target.is_file() and target.stat().st_size > 0:
        return target

    url = f"{RAW_BASE}/{symbol}.csv"
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            body = response.read()
    except urllib.error.HTTPError as exc:
        raise FileNotFoundError(
            f"no local instance data, and {url} returned HTTP {exc.code}.\n"
            f"If {symbol!r} is misspelled, check data/instance/_manifest.csv for the "
            f"symbol names. If the repository has not been pushed yet, clone it or set "
            f"{_ENV_VAR} to a local data/instance directory."
        ) from exc
    except urllib.error.URLError as exc:
        raise ConnectionError(
            f"no local instance data and {url} is unreachable ({exc.reason}). "
            f"Clone the repository, or set {_ENV_VAR} to a local data/instance directory."
        ) from exc

    target.write_bytes(body)
    return target


def load_symbol(symbol: str, *, data_dir: str | Path | None = None) -> pd.DataFrame:
    """Return one GAMS set or parameter as a DataFrame.

    Parameters carry a ``Val`` column; sets carry only their label columns.
    """
    local = instance_dir(data_dir)
    path = local / f"{symbol}.csv" if local else None
    if path is None or not path.is_file():
        if local is not None and path is not None and not path.is_file():
            # A local directory that lacks the symbol is a real error, not a reason to
            # silently read a different version of the data off the network.
            raise FileNotFoundError(
                f"{path} does not exist. The instance directory is {local}; "
                f"see its _manifest.csv for the symbols that are present."
            )
        path = _fetch(symbol)
    return pd.read_csv(path)


class Instance:
    """The model instance, loaded lazily one symbol at a time.

    ``inst["CapitalCost"]`` gives the raw table. The helpers below give the shapes the
    model actually wants, so the indexing convention lives in one place instead of
    being re-derived at every use.
    """

    def __init__(self, data_dir: str | Path | None = None) -> None:
        self._dir = instance_dir(data_dir)
        self._cache: dict[str, pd.DataFrame] = {}

    @property
    def source(self) -> str:
        return str(self._dir) if self._dir else f"{RAW_BASE} (cached in {_cache_dir()})"

    @property
    def is_local(self) -> bool:
        return self._dir is not None

    def __getitem__(self, symbol: str) -> pd.DataFrame:
        if symbol not in self._cache:
            self._cache[symbol] = load_symbol(symbol, data_dir=self._dir)
        return self._cache[symbol]

    def has(self, symbol: str) -> bool:
        try:
            self[symbol]
        except (FileNotFoundError, ConnectionError):
            return False
        return True

    # GAMS writes whichever name a symbol was DECLARED with, so a parameter declared
    # over an alias exports its column as that alias. Measured on this instance:
    # DemandResponseDiscountRate(r) exports as "r", not "REGION". Resolving aliases
    # here means callers name the set they mean and do not have to know which
    # declaration a symbol happened to use.
    _ALIASES = {
        "r": "REGION", "rr": "REGION",
        "y": "YEAR", "yy": "YEAR", "v": "YEAR",
        "l": "TIMESLICE", "ll": "TIMESLICE",
        "t": "TECHNOLOGY", "tt": "TECHNOLOGY",
        "f": "FUEL", "e": "EMISSION", "ee": "EMISSION",
        "m": "MODE_OF_OPERATION", "s": "STORAGE",
        "ls": "SEASON", "d": "DR_TYPE",
    }

    def _resolve_column(self, symbol: str, df: pd.DataFrame, wanted: str) -> str:
        if wanted in df.columns:
            return wanted
        # Several aliases map to one set (r and rr are both REGION), so collect every
        # alias of the wanted name rather than inverting the map, which would keep
        # only the last one and silently fail to resolve the others.
        aliases = [a for a, canonical in self._ALIASES.items() if canonical == wanted]
        for candidate in (*aliases, wanted.lower(), wanted.upper()):
            if candidate in df.columns:
                return candidate
        # A single unnamed dimension exports as Dim1.
        if wanted != "Val" and list(df.columns) == ["Dim1", "Val"]:
            return "Dim1"
        raise KeyError(
            f"{symbol} has no column {wanted!r} (nor an alias of it); "
            f"it has {list(df.columns)}"
        )

    def elements(self, set_name: str) -> list[str]:
        """The members of a GAMS set, in file order - which is the model's order."""
        df = self[set_name]
        return df.iloc[:, 0].astype(str).tolist()

    def scalar(self, name: str) -> float:
        """A zero-dimensional parameter, such as DM or AvgSpeed."""
        df = self[name]
        if len(df) != 1:
            raise ValueError(f"{name} has {len(df)} records; expected exactly 1")
        return float(df["Val"].iloc[0])

    def param(self, name: str, *keys: str) -> dict[tuple[str, ...] | str, float]:
        """A parameter as {key: value}, keyed by the columns named in ``keys``.

        With no keys, every column but ``Val`` is used, in file order. A single key
        gives plain string keys rather than one-tuples, because that is what reads
        well at the call site.
        """
        df = self[name]
        cols = list(keys) if keys else [c for c in df.columns if c != "Val"]
        cols = [self._resolve_column(name, df, c) for c in cols]
        values = df["Val"].astype(float).to_numpy()
        if len(cols) == 1:
            return dict(zip(df[cols[0]].astype(str), values))
        index = zip(*(df[c].astype(str) for c in cols))
        return dict(zip(index, values))

    def __repr__(self) -> str:
        where = "local" if self.is_local else "GitHub"
        return f"<Instance {where}: {self.source}>"

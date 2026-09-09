#!/usr/bin/env python
"""No committed file may carry an absolute path from the machine that wrote it.

    python scripts/check_no_machine_paths.py

This repository is heading for public release and a Zenodo DOI. A user's home directory
path in a committed file publishes their username; found once, in
``notebooks/01_model.ipynb``, by a peer session applying the same check to its own
repository and reporting the result back here. (Deliberately not quoted here: the
example this check itself would flag if this docstring named it.)

Three things this check exists to get right, each found the hard way:

**Enumerate with ``git ls-files -z``, not a whitespace split.** A path containing a
space breaks apart under ``.split()`` into fragments that do not exist; ``is_file()``
then returns False for each and the file is skipped with no message at all. This repo
has no such path today, so the bug was proven with a planted one rather than trusted
on the strength of today's filenames - see ``_prove_every_path_resolves`` below. A
"scanned N files" count cannot catch this: a skip and a scan look identical from the
summary line, which is exactly why every listed path is asserted to resolve rather
than merely counted.

**Read binary files too.** ``grep -I`` (and naive UTF-8 decoding) skips anything that
does not look like text, which in this repo is the two shipped ``.mps.gz``/``.sol.gz``
artifacts and five PNGs. Reading them as raw bytes and decompressing the ``.gz``
members before scanning is what makes a "zero hits" result mean anything.

**Prove the pattern can match before trusting that it did not.** A regex built to
match one-or-two literal backslashes is exactly the kind of thing that silently
matches nothing if a single character is wrong - three separate variants of this bit
during the review that produced this file, and two of the three reported success.
``_probe`` constructs a known match with the same machinery the real patterns use and
asserts it fires, every run, before the real sweep is trusted.

Limit, stated rather than implied: this reads raw bytes plus gzip members. A path
sitting inside a zlib-compressed PDF stream or a PNG ``zTXt`` chunk would not be seen.
Neither format is shipped by this repository today; if one ever is, this check does
not cover it.
"""
from __future__ import annotations

import gzip
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Built with chr(92), never a literal backslash in source: a Windows path written
# directly into a Python string is the trap recorded in this machine's own notes -
# `\U` and `\1` are escapes, not the characters they look like, and one of the two
# fails silently. re.escape() on the assembled separator, not on a hand-written
# backslash pair, is what keeps this from becoming a fourth variant of the same bug.
_BACKSLASH = re.escape(chr(92))

_PATTERNS = [
    re.compile(rb"[A-Za-z]:" + _BACKSLASH.encode() + rb"+Users" + _BACKSLASH.encode()
               + rb"+[A-Za-z0-9_.-]+"),
    re.compile(rb"/home/[a-z][a-z0-9_-]*/"),
    re.compile(rb"/Users/[A-Za-z0-9_.-]+/"),
]


def _probe() -> None:
    """The pattern must be shown capable of matching before its silence means anything."""
    sample = ("C:" + chr(92) + "Users" + chr(92) + "probe" + chr(92) + "leak.txt").encode()
    assert any(p.search(sample) for p in _PATTERNS), (
        "the machine-path pattern does not match its own probe string - "
        "fix the pattern before trusting any 'no matches' result"
    )


def _tracked_files() -> list[str]:
    out = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT,
                          capture_output=True, text=True, check=True)
    return [f for f in out.stdout.split("\0") if f]


def _prove_the_distinction_matters() -> None:
    """This repo has no tracked path with a space in it today, so the bug a naive
    whitespace split has cannot be demonstrated on the real tree. Demonstrate it on
    a synthetic one instead, so the -z enumeration below is known to be fixing a
    real failure mode rather than a hypothetical one."""
    synthetic = ["a.csv", "figures/gas share.png", "b.csv"]
    naive = " ".join(synthetic).split()
    assert "figures/gas share.png" not in naive, (
        "the synthetic spaced path survived a whitespace split - the demonstration "
        "itself is broken, not just the thing it demonstrates"
    )
    assert "figures/gas" in naive and "share.png" in naive, (
        "expected the whitespace split to fragment the spaced path into two pieces"
    )


def _every_listed_path_resolves(names: list[str]) -> None:
    """A path `git ls-files -z` names but the filesystem does not have is not a
    warning sign to skip past - it means enumeration and filesystem disagree, and
    silently continuing is the whitespace-split failure by another route."""
    for name in names:
        assert (ROOT / name).is_file(), (
            f"{name!r} was listed by git but does not resolve to a file"
        )


def sweep() -> str:
    _probe()
    _prove_the_distinction_matters()
    names = _tracked_files()
    _every_listed_path_resolves(names)

    hits: list[tuple[str, bytes]] = []
    for name in names:
        path = ROOT / name
        raw = path.read_bytes()
        blobs = [raw]
        if name.endswith(".gz"):
            try:
                blobs.append(gzip.decompress(raw))
            except OSError:
                pass  # not actually gzip; the raw-bytes scan above still covers it
        for blob in blobs:
            for pattern in _PATTERNS:
                for match in set(pattern.findall(blob)):
                    hits.append((name, match))

    assert not hits, "machine path(s) found in committed files:\n" + "\n".join(
        f"  {name}: {match.decode('utf-8', 'replace')}" for name, match in hits
    )
    return f"{len(names)} tracked files swept, 0 machine paths found"


def main() -> int:
    try:
        detail = sweep()
    except AssertionError as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        return 1
    print(f"ok   {detail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

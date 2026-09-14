"""No committed file carries an absolute path from the machine that wrote it.

This repository shipped one, and fixed it in PR #1: `notebooks/01_model.ipynb`
printed `Instance.source`, an absolute path, into committed output. The leaked
tag was never deposited - Zenodo was connected three days later - so the DOI is
clean.

The guard has existed here since that fix but was never wired into the suite, so
it only ran when somebody remembered to run it. `water-energy-coopt-scs-2021`,
which took this guard, wired it in properly; this file takes that back.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUARD = ROOT / "scripts" / "check_no_machine_paths.py"


def test_the_guard_script_exists():
    assert GUARD.exists(), f"{GUARD.name} is missing - the sweep is the whole protection"


def test_no_committed_file_carries_a_machine_path():
    result = subprocess.run([sys.executable, str(GUARD)], cwd=ROOT,
                            capture_output=True, text=True)
    assert result.returncode == 0, (
        "a committed file carries an absolute home path:\n"
        f"{result.stdout}{result.stderr}\n"
        "Fix it where the string is produced, not by normalising the artifact - "
        "a normaliser hides it from every reader who is not diffing bytes."
    )

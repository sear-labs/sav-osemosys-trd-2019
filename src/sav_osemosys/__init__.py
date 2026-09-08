"""The OSeMOSYS ATX energy-transportation model behind Jones and Leibowicz (2019).

Transportation Research Part D, doi:10.1016/j.trd.2019.05.005

The instance is plain CSV under data/instance/, readable with no licence and no solver.
`Instance` finds it locally or falls back to the copy published on GitHub, so the same
code runs from a clone and from a Colab notebook with nothing checked out.
"""
from sav_osemosys.data import Instance, RAW_BASE, instance_dir, load_symbol

__all__ = ["Instance", "RAW_BASE", "instance_dir", "load_symbol"]
__version__ = "1.0.0"

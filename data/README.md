# The model instance, in open form

`instance/` is every set and parameter the model uses, as CSV — 102 symbols, 171,945 rows,
written by `scripts/export_instance.py` straight out of GAMS.

**This exists so the instance can be read without a GAMS licence.** The parameters live inline
in `model/ATX_Integrated_Final_Fleet.gms`, a 1,889-line file, so until now looking at this
model's numbers required commercial software. These CSVs are what the Python port consumes and
what any reader can open.

They are *generated*, and committed deliberately (Part 1 rule 5): regenerating them needs GAMS,
which is exactly the dependency they exist to remove. `atx_instance.gdx` is the intermediate and
is gitignored — it is a binary GAMS artefact, and the CSVs are the open form of the same thing.

## One thing to know before using them

`SpecifiedAnnualDemand` for `FMT` is **already multiplied** by the data file's `scalar DM`,
which is 2. The data file applies it before the unload happens, so these CSVs carry the
`dm=2` state. `DM.csv` records the value used, and the base row is recovered by dividing —
which is what `model/osemosys_scenario.gms` does, so the GAMS driver and the Python port
start from identical numbers.

The check that this is right: private `VMT` plus base `FMT` must equal the no-SAV travel
demand in every year. It does, to 2.0e-4 — see `scenarios/no-sav-vmt.csv`.

## Regenerating

```bash
python scripts/export_instance.py     # needs GAMS once; the CSVs are the output
```

Nothing in `model/` is modified: the exporter includes the data file and unloads what that
file built, so these are the numbers the model actually uses rather than a transcription.

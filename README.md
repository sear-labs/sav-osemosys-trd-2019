# sav-osemosys

The OSeMOSYS ATX integrated energy–transportation model behind Jones and Leibowicz (2019),
*Transportation Research Part D* — [10.1016/j.trd.2019.05.005](https://doi.org/10.1016/j.trd.2019.05.005).

## This model was hard to find, so read this first

It existed in **seven divergent copies across five locations**, and the folder actually *named* after
the paper contained only `.bib` files — no code. Anyone asked to reproduce the paper started there and
stopped.

The copy here is the authoritative one: **138,734 bytes, dated 2018-05-30**. It wins because it is the
largest, it is the only copy that sat beside its own solver output, and its results files carry the
same date. The next-largest copy is 114,185 B and is a later variant; the smallest is 79,801 B.

## Reproduction status — verified 2026-09-05

Re-solved unmodified on GAMS 42.5 / CPLEX, eight years after the original run:

```
18,813,038 equations x 18,760,518 variables, 43,631,324 non-zeros   (LP)
Baseline    85,409.6403   Optimal
CO2 policy  86,679.7693   Optimal
```

Against `reference-output/`, over **11,448 comparable numeric cells**:

| | bit-identical |
|---|---|
| Baseline | **98.03%** |
| CO₂ policy | **97.44%** |

**The residual is degeneracy, not disagreement.** It concentrates exactly where a storage LP has
alternate optima:

| Section | cells differing |
|---|---|
| Storage levels (2050) | 33–56% |
| `NewCapacity` | 1.8% |
| Electricity production / use | 0.7–2.5% |
| `TotalAnnualCapacity` | 0.8% |
| **Total Storage Capacity** | **0%** |
| **New Storage Capacity** | **0%** |

Same cost, same totals, different dispatch schedule and build timing. Storage charge/discharge shifts
between timeslices at zero cost, so a modern CPLEX picks a different tie-break than the 2018 one did.

> **What this means for the paper's claims.** Cost and capacity totals reproduce. **Any statement
> naming a specific build year or a specific storage level does not** — it was never unique. Treat
> those as illustrative of one optimal solution rather than as the model's answer.

A further 315 rows have no counterpart because the bundled report writer emits **Year 2020** while the
reference CSVs were produced by one emitting **Year 2030**. That writer is not in this repository.

## Running it

```bash
gams model/osemosys_run.gms
python scripts/validate.py results/OSeMOSYS_ATX_Baseline_Results.csv
```

⚠️ **Set `solprint=off` before running.** `osemosys_run.gms` ships with `solprint=on`, which over
17.6M variables writes a listing that passed **4.7 GB and was still growing** when interrupted. Use a
`.gdx` unload to capture results instead. `.lst` files are gitignored for this reason.

A commercial LP solver is required — this is far beyond any free or size-limited licence.

## Data

**Self-contained.** All parameters are inline in `model/ATX_Integrated_Final_Fleet.gms`; the model
reads no external file. Sources are cited in the source itself: **NREL SAM**, the **EIA Power
Generator Database**, and the **NREL 2016 Annual Technology Baseline** — all public.

Parameter workbooks (`Parameters.xlsx` and others) exist alongside the originals on the lab Drive but
are **not included**: their provenance has not been verified and the model does not read them.

The bundled 2018 `.lst`/`.log` are also excluded. They are not a solve — the log shows the licence had
expired eleven days earlier and the job ran for 0.058 s, compiling the data file directly. **The CSVs
are the only reproduction target.**

## Attribution

`osemosys_run.gms` is headed **Benjamin D. Leibowicz**. **OSeMOSYS** itself is third-party open-source
work — Howells et al., *Energy Policy* 39(10), 2011 — and this repository is an application of it, not
a redistribution of the framework.

## How to cite

> Jones, Erick C., Jr., and Benjamin D. Leibowicz. "Contributions of shared autonomous vehicles to
> climate change mitigation." *Transportation Research Part D*, 2019. doi:10.1016/j.trd.2019.05.005

BibTeX: `author = {Jones, Jr., Erick C. and Leibowicz, Benjamin D.}` — the suffix is the middle field.

## Licence

MIT for this repository's contents — see `LICENSE`.

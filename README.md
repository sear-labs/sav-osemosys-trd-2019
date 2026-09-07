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

## Two reproduction claims, and they are not the same

Keeping these apart is what finally made this paper reproducible. **Claim 1** is that the model
reproduces the run saved beside it in 2018. **Claim 2** is that it reproduces the ten scenarios
published in the article. The first was true for years and was repeatedly mistaken for the second.

## Claim 1: the model's own 2018 run — verified 2026-09-05

Re-solved unmodified on GAMS 42.5 / CPLEX, eight years after the original run:

```
18,813,038 equations x 18,760,518 variables, 43,631,324 non-zeros   (LP)
Baseline    85,409.6403   Optimal
CO2 policy  86,679.7693   Optimal
```

Against `reference-output/`, over **14,149 comparable numeric cells**:

| | bit-identical |
|---|---|
| Baseline | **98.35%** |
| CO₂ policy | **97.77%** |
| `AnnualEmissions` alone | **100%** (864/864) |

**The residual is degeneracy, not disagreement.** It concentrates exactly where a storage LP has
alternate optima:

| Section | cells differing |
|---|---|
| Storage levels (2050) | 33–56% |
| `NewCapacity` | 1.8% |
| Electricity production / use | 0.7–2.5% |
| `TotalAnnualCapacity` | 0.8% |
| `AnnualGenerationByTechnology` | 0.4% / 1.2% |
| **Total Storage Capacity** | **0%** |
| **New Storage Capacity** | **0%** |
| **AnnualEmissions** | **0%** |

Same cost, same totals, different dispatch schedule and build timing. Storage charge/discharge shifts
between timeslices at zero cost, so a modern CPLEX picks a different tie-break than the 2018 one did.

> **What this means for the model's own claims.** Cost and capacity totals reproduce. **Any statement
> naming a specific build year or a specific storage level does not** — it was never unique. Treat
> those as illustrative of one optimal solution rather than as the model's answer.

A further 315 rows have no counterpart because the bundled report writer emits **Year 2020** while the
reference CSVs were produced by one emitting **Year 2030**. That writer is not in this repository.

**Scenario 2 of the grid below is this same run**, and doubles as the regression test on the
rebuild: same demands, same absent tax, same charging paradigm. It returns `85,409.6403` and
validates at 98.35%, matching the tables above section for section. If the scenario driver ever
breaks, that is where it shows.

## Claim 2: the paper's ten published scenarios — verified 2026-09-06

**The paper runs ten scenarios. The 2018 run file runs two, and under the wrong policy
instrument.** That is why this paper resisted reproduction for years: the saved run was being
compared against published carbon-tax results while it applied an emissions *cap*.

Table 2 of the paper crosses SAV diffusion (70% by 2050 / none), carbon tax (yes / no), SAV
charging (optimized / night-only) and a travel-demand multiplier (0.5 / 1 / 2). The scenarios were
run in 2018 by hand-editing the driver between runs, so only the last state survived — and all five
surviving copies of `osemosys_run.gms` carry that same last state. Finding a better copy was never
going to help.

The grid now lives in [`scenarios/table2.csv`](scenarios/table2.csv) and is driven by
`model/osemosys_scenario.gms`. **Adding or changing a scenario is an edit to the CSV, never to the
GAMS.** The 2018 `osemosys_run.gms` is kept verbatim as the artifact and is not modified.

### The ten scenarios — solved 2026-09-06, GAMS 42.5 / CPLEX

| # | SAV | tax | charging | dm | objective | gas 2035 | gas peak | year |
|---|---|---|---|---|---|---|---|---|
| 1 | 70% | no | optimized | 0.5 | 66,113.20 | 80.6% | 80.6% | 2035 |
| 2 | 70% | no | optimized | 2 | 85,409.64 | 77.7% | 78.0% | 2036 |
| 3 | 70% | no | optimized | 1 | 72,412.33 | 79.6% | 79.6% | 2035 |
| 4 | 70% | no | night only | 1 | 75,110.56 | 80.0% | 80.0% | 2035 |
| 5 | none | no | n/a | n/a | 92,091.39 | 80.5% | 80.5% | 2035 |
| 6 | 70% | **yes** | optimized | 0.5 | 71,267.76 | 14.2% | 55.7% | **2021** |
| 7 | 70% | **yes** | optimized | 2 | 90,819.95 | 13.7% | 56.9% | **2021** |
| 8 | 70% | **yes** | optimized | 1 | 77,638.36 | 14.0% | 55.6% | **2021** |
| 9 | 70% | **yes** | night only | 1 | 80,451.63 | 13.6% | 55.9% | **2021** |
| 10 | none | **yes** | n/a | n/a | 97,883.08 | 14.3% | 55.7% | **2021** |

43.8 minutes for all ten, run sequentially.

### The acceptance test — and it passes

The paper prints **no cost figures at all**: Fig. 10 gives objective values as bar heights only,
with no table, so not one number in the objective column above can be checked against the article.
The electricity mix is the only published quantity this model can be held to, and the paper states
two figures. Against a generation-only denominator (storage, V2G and charging also produce ELC and
are excluded):

| Paper | Central case | Result |
|---|---|---|
| No tax: natural gas "accounts for **80%** of electricity produced" in 2035 | scenario 3 | **79.6%** — off by 0.4 |
| Carbon tax: natural gas "peaks at **56%**" share in **2021** | scenario 8 | **55.6% in 2021** — off by 0.4, year exact |

**All five taxed scenarios peak in 2021**, at 55.6–56.9%, straddling the published 56%. All four
SAV no-tax scenarios land at 77.7–80.6% in 2035, straddling the published 80%.

**The peak year is the load-bearing evidence.** The old cap run peaks at 54.6% in **2025** — right
magnitude, four years late, which is exactly what a cap ramping linearly to 2050 does compared with
a tax that bites immediately. Enabling the tax moves the peak to 2021, and it stays there across
every taxed case regardless of demand multiplier or charging paradigm. That is a signature, not a
coincidence.

### Two things worth knowing about the 2018 file

**The saved 2018 run is scenario 2, not the central case.** The data file carries `scalar DM /2/`,
so what reproduces at 98.35% above is the `dm=2` corner of the grid — and at 77.7% it is the
*worst* match to the paper's 80% of any no-tax scenario. The central case (`dm=1`, scenario 3)
gives 79.6%. Do not read the shipped state as the headline case.

**The paper's tax is already in the data file, built and then discarded.**
`ATX_Integrated_Final_Fleet.gms` constructs `EmissionsPenalty` at $20/tCO₂ projected forward at 5%
a year — exactly the published policy — and then zeroes it on the very next line. The run file
carries the same pair commented out, below the cap. The scenario driver restores it rather than
reinventing it.

## Running it

```bash
python scripts/test_offline.py                 # everything that needs no solver, ~1 s
python scripts/run_scenarios.py                # all ten scenarios, ~44 min
python scripts/check_results.py                # the grid, the levers and the acceptance test
```

Scenarios are independent, so an interrupted run resumes:

```bash
python scripts/run_scenarios.py --only 4,9     # just these two
```

The 2018 driver still runs unchanged, and `validate.py` compares any output against the reference:

```bash
gams model/osemosys_run.gms
python scripts/validate.py results/scenario-02/scenario-02.csv reference-output/OSeMOSYS_ATX_Baseline_Results.csv
```

⚠️ **`solprint=off`, always.** `osemosys_run.gms` ships with `solprint=on`, which over 17.6M
variables writes a listing that passed **4.7 GB and was still growing** when interrupted. The
scenario driver sets it off, and `test_offline.py` fails if that is ever undone.

⚠️ **One solve at a time.** A solve peaks near 16 GB on a 32 GB machine. `run_scenarios.py` is
sequential deliberately.

⚠️ **`execute_unload` is restricted** to the reported symbols. Unrestricted it writes every symbol
in an 18.7M-variable model — 954 MB per scenario, 9.5 GB across the grid. Restricted it is 56 MB.

A commercial LP solver is required — this is far beyond any free or size-limited licence, which is
also why there is no CI. `scripts/test_offline.py` is the suite CI would run if it could.

## How the rebuild is kept honest

Ten scenarios that were quietly the *same* scenario would all solve and all report success, so "the
run succeeded" is not evidence that anything was applied. Four checks exist for that:

- **The demand agreement assertion**, in `osemosys_scenario.gms`. The SAV cases split one travel
  demand into private VMT and fleet FMT; the no-SAV case is that demand undivided. The driver
  asserts `VMT + FMT` equals the no-SAV row in every year — which tests the split hypothesis, the
  recovery of the base FMT row, and the transcribed CSV, all at once. Measured agreement: 2.0e-4
  against a 1e-3 tolerance.
- **The lever check**, in `check_results.py`. Every run records what its levers actually did to
  `results/scenario-NN/levers.csv`; the checker re-derives what they should have been from the grid
  and compares. The levers are confirmed from the outputs, never from the inputs the runner was
  handed.
- **The fleet check.** For the no-SAV cases `NewCapacity` must be zero for all six fleet
  technologies in all 36 years, and non-zero for the SAV cases. This tests `NewCapacity`, not
  `TotalAnnualCapacity`: the 2015 column carries inherited stock — 180 thousand `ICE_PET_F`, 2
  thousand `EV_F` — that exists whatever the scenario says and is retired in the first period.
- **Two cost invariants**, which hold by optimisation rather than by energy policy: a carbon tax
  cannot lower total cost, and night-only charging cannot beat optimized charging. Both compare
  scenarios differing in exactly one lever, so a violation means the solve or the lever is wrong,
  not that the model has said something interesting. *(That no-SAV costs more than SAV is a
  **result**, not a theorem — the two have different demand structures — so it is reported and not
  asserted.)*

Every one of these has been watched to fail: defect injected, check red, defect removed, check
green. A guard that has only ever passed is indistinguishable from one that cannot fail.

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

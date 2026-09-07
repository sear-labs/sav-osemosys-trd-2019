# sav-osemosys-trd-2019 conventions

The portable standard governs this repo. Read it before working here:

    https://github.com/sear-labs/code-standard    canonical - the same from any machine
    a local clone, if you have one                faster; e.g. C:\Users\<you>\dev\repo\ops\code-standard

Check the branch before quoting a clone, and pull after. Read it first and last.

---

# Part 11 - This project specifically

## What this is

The OSeMOSYS ATX integrated energy-transportation model behind Jones and Leibowicz
(2019), *Transportation Research Part D*, doi:10.1016/j.trd.2019.05.005.

Two upstreams, both credited in the README: `osemosys_run.gms` is headed **Leibowicz**,
and **OSeMOSYS** itself is third-party open-source work (Howells et al., *Energy Policy*
39(10), 2011). This repository is an application of OSeMOSYS, not a redistribution of it.

## Two reproduction claims, and they are not the same

Keep these apart in anything you write. Conflating them is the mistake that made this
paper look irreproducible for years.

| Claim | Evidence | Where |
|---|---|---|
| Reproduces the model's own 2018 run | 98.35% of 14,149 cells bit-identical | `reference-output/`, `scripts/validate.py` |
| Reproduces the **published** scenarios | the ten Table 2 cases, checked against the paper's two electricity-mix figures | `scenarios/table2.csv`, `scripts/check_results.py` |

The paper prints **no cost figures** - Fig. 10 gives objective values as bar heights
only. So an objective value can never be checked against the article directly, and the
electricity mix is the only published number this model can be held to.

## The model is fine; the scenario configuration was what went missing

The scenarios were run in 2018 by hand-editing the driver between runs, so only the last
state survived. All five surviving copies of `osemosys_run.gms` run **two** solves under
an emissions **cap**; the paper runs **ten** under a carbon **tax**. Comparing a cap run
against published tax results is why it kept coming out "slightly off".

`model/osemosys_run.gms` is the 2018 driver and is kept verbatim as the artifact.
`model/osemosys_scenario.gms` is the rebuilt one. Do not fix the old one.

## Exemptions from the standard, and why

- **No CI.** Every solve needs a commercial LP solver under a five-user departmental
  licence. `scripts/test_offline.py` covers everything that does not need GAMS, and is
  the suite CI would run if it could.
- **Configuration is not fully outside code** (Part 1 rule 2). The scenario grid is, in
  `scenarios/table2.csv`. The model's parameters are inline in a 1,889-line GAMS data
  file, because that file is the 2018 artifact and extracting them would destroy the
  thing being reproduced.
- **Degenerate LP.** Cost and capacity totals reproduce; storage dispatch and build
  timing do not, because the LP has alternate optima there. Never assert a specific
  build year or storage level - see Part 6, *Non-reproducible prose*.

## Traps particular to this repo

- **`solprint=off`, always.** Over 17.6M variables, `solprint=on` writes a listing that
  passed **4.7 GB and was still growing** when interrupted. The 2018 driver ships with
  it on.
- **Restrict `execute_unload`.** Unrestricted, the GDX is 954 MB per scenario.
- **One solve at a time.** A solve peaks near 16 GB on a 32 GB machine, so the scenarios
  are run sequentially. They are independent; resume with `--only`.
- **The licence file is never committed.** It lives in OneDrive and is *not* matched by
  the global gitignore's `*.lic`; this repo's `.gitignore` names `gamslice.txt`
  explicitly.
- **The bundled 2018 `.lst`/`.log` are not a solve.** The licence had expired eleven days
  earlier and the job ran 0.058 s. The CSVs are the only reproduction target.
- **`validate.py` parses a variable number of label fields.** `AnnualGenerationByTechnology`
  and `AnnualEmissions` rows carry a fourth (the fuel). Assuming three silently dropped
  19% of the comparison.

## The solver is a parameter, and HiGHS does not currently work

`--solver` on `run_scenarios.py` sets `option lp=`. Default `cplex`, which is what the 2018
run and the 98.35% reproduction used.

**Measured 2026-09-07: GAMS 42.5's bundled HiGHS 1.5.1 did not solve scenario 3 in 6.8 hours.**
CPLEX solves it in 94 seconds. HiGHS reached objective 16,005 against the true 72,412.33 after
1.1M simplex iterations, with primal infeasibility *rising* over the run - 1.8e6 at iteration 0
to 5.8e11 at 1.1M. That is numerical trouble, not slow progress.

**Do not read this as "HiGHS cannot do it."** Three things about that run were unfavourable and
none has been tried yet:

- the log says `Solving LP without presolve or with basis` - **presolve was off**, on an
  18.8M-row LP. Likely the single biggest lever.
- `Using EKK dual simplex solver - serial` - single-threaded.
- dual simplex rather than **IPM**, which usually wins on a huge degenerate LP.

The matrix range is `[1e-6, 4.32e6]`, twelve orders of magnitude. Poor scaling is exactly where
commercial presolve and scaling earn their licence fee, so this model is a hard case for an
open-source solver rather than a typical one.

GAMS 42.5 bundles a 2023 HiGHS; current HiGHS is several major versions on. Retest with presolve
on, IPM, and a current build before concluding anything.

## How the scenario driver stays honest

The checks, and why each exists, are in the README under *How the rebuild is kept honest*. Do not
restate them here - read them there. Two things about them belong in this file:

**Scenario 2 is the regression test.** SAV 70% / no tax / optimized / dm=2 is exactly the shipped
model's first solve, so the driver must return `85,409.6403` and validate at 98.35% against
`reference-output/`. If it does not, the rebuild has broken something.

**Every guard has been watched to fail** - defect injected, check red, defect removed, check green.
If you add one, do the same; a guard that has only ever passed is indistinguishable from one that
cannot fail. Two traps bit while doing this and will bite again: a `sed` substitution that matched
nothing and reported success, and `exit=$?` after a pipeline reporting `tail`'s status rather than
the command's. Assert the match, and capture the status on the next line.

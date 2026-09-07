* Scenario driver for the ten cases in Table 2 of Jones and Leibowicz (2019),
* Transportation Research Part D, doi:10.1016/j.trd.2019.05.005.
*
* The shipped osemosys_run.gms runs two solves under an emissions CAP. The paper
* runs ten under a carbon TAX. This file runs exactly one scenario per invocation,
* with the four Table 2 levers supplied on the command line:
*
*   gams osemosys_scenario.gms --SCENARIO=8 --SAV=70 --TAX=yes
*                              --CHARGING=optimized --DM=1
*                              --NOSAVCSV=... --RESULTSFILE=... --GDXFILE=...
*
* The grid lives in scenarios/table2.csv. Nothing scenario-specific is hardcoded
* here: this file knows how to apply a lever, not which levers a case wants.
*
* Underlying model: Benjamin D. Leibowicz. OSeMOSYS: Howells et al., Energy Policy
* 39(10), 2011.

$if not set SCENARIO    $abort 'SCENARIO not set'
$if not set SAV         $abort 'SAV not set (70 | none)'
$if not set TAX         $abort 'TAX not set (yes | no)'
$if not set CHARGING    $abort 'CHARGING not set (optimized | night)'
$if not set DM          $abort 'DM not set'
$if not set NOSAVCSV    $abort 'NOSAVCSV not set'
$if not set RESULTSFILE $abort 'RESULTSFILE not set'
$if not set GDXFILE     $abort 'GDXFILE not set'
$if not set LEVERSFILE  $abort 'LEVERSFILE not set'

$include ATX_Integrated_Final_Fleet.gms
$include osemosys_equations.gms


* ##### Recover the base demand rows #####
*
* The data file applies its own scalar DM to FMT before control reaches here, so
* the FMT row in memory is already multiplied. Divide it back out to recover the
* unmultiplied row, then reapply this scenario's multiplier below.

abort$(DM = 0)
  'the data file scalar DM is zero, so the base FMT row cannot be recovered';

parameter BaseVMT(REGION,YEAR);
parameter BaseFMT(REGION,YEAR);
BaseVMT(r,y) = SpecifiedAnnualDemand(r,"VMT",y);
BaseFMT(r,y) = SpecifiedAnnualDemand(r,"FMT",y) / DM;

* The no-SAV travel demand: one row, transcribed from the commented-out *ATX.VMT
* line in the data file by scripts/extract_no_sav_row.py.
table NoSavVMT(REGION,YEAR)
$ondelim
$include "%NOSAVCSV%"
$offdelim
;

* ##### The agreement assertion #####
*
* The SAV cases split one travel demand into private VMT and fleet FMT; the no-SAV
* case is that demand undivided. If that is right, VMT + FMT must equal the no-SAV
* row in every year. This check therefore tests three things at once: that the
* split hypothesis holds, that the DM division above recovered the true base row,
* and that the transcribed CSV matches the data file. Any one of them being wrong
* fails here rather than producing ten plausible and wrong scenarios.

scalar demand_gap;
demand_gap = smax((r,y), abs(BaseVMT(r,y) + BaseFMT(r,y) - NoSavVMT(r,y)));
display demand_gap;
abort$(demand_gap > 1e-3)
  'VMT + FMT does not equal the no-SAV row: the demand split assumption is wrong',
  demand_gap;

abort$(card(NoSavVMT) <> card(YEAR))
  'the no-SAV CSV does not cover every model year', NoSavVMT;


* ##### Lever 1: SAV diffusion #####

$ifThen.sav %SAV% == none
SpecifiedAnnualDemand(r,"VMT",y) = NoSavVMT(r,y);
SpecifiedAnnualDemand(r,"FMT",y) = 0;
$else.sav
SpecifiedAnnualDemand(r,"VMT",y) = BaseVMT(r,y);
SpecifiedAnnualDemand(r,"FMT",y) = %DM% * BaseFMT(r,y);
$endIf.sav


* ##### Lever 2: carbon tax #####
*
* $20/tCO2 in the base year rising 5% annually. The data file builds exactly this
* two lines before it zeroes it; the shipped run file carries the same pair
* commented out. This restores it rather than reinventing it.

$ifThen.tax %TAX% == yes
EmissionsPenalty(r,e,"2015") = 20;
EmissionsPenalty(r,e,y) = EmissionsPenalty(r,e,"2015")*(1.05)**(ord(y)-1);
$else.tax
EmissionsPenalty(r,e,y) = 0;
$endIf.tax

* No emissions cap. The paper's policy is the tax above; the cap in the shipped run
* file appears in no published scenario. E8_AnnualEmissionsLimit is unconditional,
* so the limit must stay effectively infinite rather than be zeroed - zeroing it
* would force emissions to zero and read as an infeasible model.
AnnualEmissionLimit(r,e,y) = 999999999;


* ##### Lever 3: SAV charging paradigm #####
*
* Optimized is the data file's own availability-based factor: fleet EVs may charge
* in any hour they are not driving. Night Only forbids daytime charging - LowV2G is
* hours 6-20, HighV2G is hours 21-24 and 1-5.

$ifThen.chg %CHARGING% == night
CapacityFactor(r,"EV_CHARGE_F",LowV2G,y) = 0;
$endIf.chg


* ##### Re-derive what depends on the demands just changed #####
*
* FleetSize is computed at the foot of the data file from SpecifiedAnnualDemand, so
* it is stale after any of the levers above. FleetSizeFleet is recomputed for the
* same reason although its only consumer, VehicleFMTProduction, is commented out in
* the equations file.

FleetSize(y,r) = smax(l,1000*(((SpecifiedDemandProfile(r,"VMT",l,y)*SpecifiedAnnualDemand(r,"VMT",y))/(YearSplit(l,y)*8760))/AvgSpeed)*(1/CapacityFactor(r,"ICE_PET","W1",y)));
FleetSizeFleet(y,r) = smax(l,1000*(((SpecifiedDemandProfile(r,"FMT",l,y)*SpecifiedAnnualDemand(r,"FMT",y))/(YearSplit(l,y)*8760))/AvgSpeed)*(1/CapacityFactor(r,"ICE_PET_F","W1",y)));

* VehicleVMTProduction divides by FleetSize, so a zero would be a division by zero
* reported as a domain error a long way from its cause.
abort$(smin((y,r), FleetSize(y,r)) <= 0)
  'FleetSize is zero in some year: VehicleVMTProduction would divide by zero',
  FleetSize;


* ##### Record what the levers actually did #####
*
* A lever that silently did nothing looks exactly like a lever that worked, and ten
* scenarios that are quietly the same scenario would still all solve and all report
* success. These are the observables that distinguish the ten cases; they are written
* per run so a checker can confirm the grid from the outputs rather than from the
* inputs it was given. W12 is an hour inside the daytime window LowV2G, W1 an hour
* inside the night window HighV2G.

scalar tax_2015, tax_2050, vmt_2050, fmt_2050, chg_day, chg_night;
tax_2015  = smax((r,e), EmissionsPenalty(r,e,"2015"));
tax_2050  = smax((r,e), EmissionsPenalty(r,e,"2050"));
vmt_2050  = smax(r, SpecifiedAnnualDemand(r,"VMT","2050"));
fmt_2050  = smax(r, SpecifiedAnnualDemand(r,"FMT","2050"));
chg_day   = smax((r,y), CapacityFactor(r,"EV_CHARGE_F","W12",y));
chg_night = smax((r,y), CapacityFactor(r,"EV_CHARGE_F","W1",y));
display tax_2015, tax_2050, vmt_2050, fmt_2050, chg_day, chg_night;

FILE Levers /'%LEVERSFILE%'/;
PUT Levers;
Levers.pc = 5;
Levers.nd = 8;
put "lever","value" /;
put "scenario", %SCENARIO% /;
put "requested_sav", "%SAV%" /;
put "requested_tax", "%TAX%" /;
put "requested_charging", "%CHARGING%" /;
put "requested_dm", %DM% /;
put "tax_2015", tax_2015 /;
put "tax_2050", tax_2050 /;
put "vmt_2050", vmt_2050 /;
put "fmt_2050", fmt_2050 /;
put "charge_factor_day_W12", chg_day /;
put "charge_factor_night_W1", chg_night /;
put "demand_gap", demand_gap /;
putclose;


* ##### Solve #####
*
* solprint=off is not optional. With 17.6M variables solprint=on writes a listing
* that passed 4.7 GB and was still growing when interrupted. optcr/optca are zeroed
* so that a switch to a MIP formulation cannot silently return a gapped answer.

model osemosys /all/;
option limrow=0, limcol=0, solprint=off, resLim=100000, lp=cplex, optcr=0, optca=0;
solve osemosys minimizing z using lp;

abort$(osemosys.modelstat <> 1)
  'solve did not return an optimal solution',
  osemosys.modelstat, osemosys.solvestat;


* ##### Results #####

$include Results_Scenario.gms
* Unload the reported quantities only. An unrestricted execute_unload writes every
* symbol in an 18.7M-variable model - measured at 954 MB per scenario, 9.5 GB across
* the grid - almost all of it internal vintage variables that nothing reads. These
* are the same symbols the results writer reports, plus the parameters that define
* which scenario this was.
execute_unload "%GDXFILE%",
  z, TotalCapacityAnnual, NewCapacity, ProductionByTechnologyAnnual,
  ProductionByTechnology, UseByTechnology, AnnualTechnologyEmission, AnnualEmissions,
  StorageLevel, NewStorageCapacity, AccumulatedStorageCapacity,
  SpecifiedAnnualDemand, EmissionsPenalty, AnnualEmissionLimit, CapacityFactor;

* Benjamin D. Leibowicz
* Graduate Program in Operations Research and Industrial Engineering
* The University of Texas at Austin

* OSeMOSYS run file

* Load database
$include ATX_Integrated_Final_Fleet.gms
$include osemosys_equations.gms

model osemosys /all/;
option limrow=0, limcol=0, solprint=on, resLim=100000, lp=cplex;
solve osemosys minimizing z using lp;










$include Results_Baseline.gms
execute_unload  "Baseline_Results.gdx";



scalar apol Model End fraction of base case emissions /0.1/;
AnnualEmissionLimit(r,e,y) = sum((tt,ee,rr),AnnualTechnologyEmission.L("2015",tt,ee,rr)) - (sum((tt,ee,rr),AnnualTechnologyEmission.L("2015",tt,ee,rr))*(1-apol)/35)*(ord(y)-1);

*EmissionsPenalty(r,e,"2015") = 20;
*EmissionsPenalty(r,e,y) = EmissionsPenalty(r,e,"2015")*(1.05)**(ord(y)-1);
solve osemosys minimizing z using lp;
$include Results_CO2_Policy.gms
execute_unload "Policy_Results.gdx";



* Benjamin D. Leibowicz
* Graduate Program in Operations Research and Industrial Engineering
* The University of Texas at Austin

* OSeMOSYS database for the ATX electricity system

*Modified by Max Brozynski for Austin, TX

* ##### SETS #####

set YEAR / 2015*2050 /;
alias (y,yy,v,YEAR);

set TECHNOLOGY
* Power plants
/ COALPP, CCPP, CTPP, NUCPP, HYDROPP, WINDPP, SOLPP, BIOPP, CCCCSPP, IGCCCCSPP, H2FUELCELL,
* Electricity Storage,
BATTERY, EV_CHARGE, V2G, EV_DISCHARGE, EV_CHARGE_F, V2G_F, EV_DISCHARGE_F
* Fuel purchasing
BUYCOAL, BUYURN, BUYBIO, BUYGAS, BUYPET, BUYDSL, BUYBIO_DSL,
* Renewable resource potentials
SOLPOT, WINDPOT, HYDROPOT,
* Private Transportation
ICE_PET, ICE_DSL, PHEV, HYBRID, H2V, EV,
*Fleet Transportation
ICE_PET_F, ICE_DSL_F, PHEV_F, HYBRID_F, H2V_F, EV_F
* Public Transportation
ICE_PET_PUB, ICE_DSL_PUB, CNG_PUB, EV_PUB, PHEV_PUB, HYBRID_PUB, BIO_DSL_PUB,
* Hydrogen Production Technologies
ELCTROL, GASREF, BIOGAS, COALGAS /

*Subsets
PP(TECHNOLOGY) / COALPP, CCPP, CTPP, NUCPP, HYDROPP, WINDPP, SOLPP, BIOPP, CCCCSPP, IGCCCCSPP, H2FUELCELL/
Trans(TECHNOLOGY) / ICE_PET, ICE_DSL, PHEV, HYBRID, H2V, EV, ICE_PET_F, ICE_DSL_F, PHEV_F, HYBRID_F, H2V_F, EV_F
ICE_PET_PUB, ICE_DSL_PUB, CNG_PUB, EV_PUB, PHEV_PUB, HYBRID_PUB, BIO_DSL_PUB /
PrivTrans(TECHNOLOGY) / ICE_PET, ICE_DSL, PHEV, HYBRID, H2V, EV/
Fleet(TECHNOLOGY) / ICE_PET_F, ICE_DSL_F, PHEV_F, HYBRID_F, H2V_F, EV_F/
PubTrans(TECHNOLOGY) / ICE_PET_PUB, ICE_DSL_PUB, CNG_PUB, EV_PUB, PHEV_PUB, HYBRID_PUB, BIO_DSL_PUB/
NICPP(TECHNOLOGY) /COALPP, CCPP, CTPP, NUCPP, HYDROPP, BIOPP, CCCCSPP, IGCCCCSPP, H2FUELCELL, BATTERY, V2G/
AllTechButPrivTrans(TECHNOLOGY) /COALPP, CCPP, CTPP, NUCPP, HYDROPP, WINDPP, SOLPP, BIOPP, CCCCSPP, IGCCCCSPP,
H2FUELCELL, BATTERY, EV_CHARGE, V2G, EV_DISCHARGE, EV_CHARGE_F, V2G_F, EV_DISCHARGE_F, BUYCOAL, BUYURN, BUYBIO, BUYGAS, BUYPET, BUYDSL, BUYBIO_DSL,
SOLPOT, WINDPOT, HYDROPOT,ELCTROL, GASREF, BIOGAS, COALGAS, ICE_PET, ICE_DSL, PHEV, HYBRID, H2V, ICE_PET_F, ICE_DSL_F, PHEV_F, HYBRID_F, H2V_F,
ICE_PET_PUB, ICE_DSL_PUB, CNG_PUB, PHEV_PUB, HYBRID_PUB, BIO_DSL_PUB /
NoNewCap2015(TECHNOLOGY) / COALPP, CCPP, CTPP, NUCPP, HYDROPP, WINDPP, SOLPP, BIOPP, CCCCSPP, IGCCCCSPP, H2FUELCELL,
BATTERY, EV_CHARGE, V2G, EV_DISCHARGE,
EV_CHARGE_F, V2G_F, EV_DISCHARGE_F,
ICE_PET, ICE_DSL, PHEV, HYBRID, H2V, EV,
ICE_PET_F, ICE_DSL_F, PHEV_F, HYBRID_F, H2V_F, EV_F,
ICE_PET_PUB, ICE_DSL_PUB, CNG_PUB, EV_PUB, PHEV_PUB, HYBRID_PUB, BIO_DSL_PUB,
ELCTROL, GASREF, BIOGAS, COALGAS /;

alias (t,tt,TECHNOLOGY);
alias (p,PrivTrans);
alias (ft, Fleet);
alias (a ,AllTechButPrivTrans);
alias (tr,Trans);


* Summary of Set: TECHNOLOGY
* # Power plants #
* COALPP = Coal power plant
* CCPP = Gas fired combined cycle power plant
* CTPP = Gas fired combustion turbine power plant
* NUCPP = Nuclear power plant
* HYDROPP = Hydro power plant
* WINDPP = Wind power plant
* SOLPP = Solar photovoltaic power plant
* BIOPP = Biomass power plant
* CCCCSPP = Gas fired combined cycle with CCS power plant
* IGCCCCSPP = Integrated coal gasification combined cycle with CCS power plant
* H2FUELCELL = H2 Fuel Cell technology
* # Storage #
* BATTERY = typical battery that consumes and generates electricity
* V2G = vehicle to grid technology (capacity constrained by capacity of EVs)
* # Fuel purchasing #
* BUYCOAL = Buy coal
* BUYURN = Buy uranium
* BUYBIO = Buy biomass
* BUYGAS = Buy natural gas
* BUYPET = Buy gasoline (petrol)
* BUYDSL = Buy diesel fuel
* BUYBIO_DSL = Buy biodiesel fuel
* # Renewable resource potentials #
* SOLPOT = Solar resource potential
* WINDPOT = Wind resource potential
* HYDROPOT = Hydro resource potential
* # Private Transportation #
* ICE_PET = Internal Combustion Engine Vehicle that uses gasoline (includes "flexible fuel" vehicles)
* ICE_DSL = Internal Combustion Engine Vehicle that uses diesel fuel
* PHEV = Plug-in hybrid vehicle
* HYBRID = Hybrid Vehicle (gasoline only)
* H2V = Hydrogen-powered vehicle
* EV = electric vehicle
* # Vehicle-to-grid #
* #Fleet Transportation#
* ICE_PET_F = Internal Combustion Engine Vehicle that uses gasoline (includes "flexible fuel" vehicles)
* ICE_DSL_F = Internal Combustion Engine Vehicle that uses diesel fuel
* PHEV_F = Plug-in hybrid vehicle
* HYBRID_F = Hybrid Vehicle (gasoline only)
* H2V_F = Hydrogen-powered vehicle
* EV_F = electric vehicle
* # Public Transportation #
* ICE_PET_PUB = Internal Combustion Engine Vehicle that uses gasoline (includes "flexible fuel" vehicles)
* ICE_DSL_PUB = Internal Combustion Engine Vehicle that uses diesel fuel
* CNG_PUB = Compressed Natural Gas powered vehicle
* EV_PUB = Electric Vehicle
* PHEV_PUB = Plug in hybrid vehicle
* HYBRID_PUB = Hybrid vehicle
* BIO_DSL_PUB = Biodiesel powered vehicle
* # Hydrogen Production
* ELECTROL = Electrolysis
* GASREF = Steam reforming of natural gas
* BIOGAS = Gasification of biomass (w/o CCS)
* COALGAS = Gasification of coal (w/o CCS)

*$OnText
set TIMESLICE / W1*W24, SF1*SF24, S1*S24/
*Slice = 1 hour

*Subsets
WNT(TIMESLICE) /W1*W24/
SPRFALL(TIMESLICE) /SF1*SF24/
SUMM(TIMESLICE) /S1*S24/

Hour1(TIMESLICE) /W1,SF1,S1/
Hour2(TIMESLICE) /W2,SF2,S2/
Hour3(TIMESLICE) /W3,SF3,S3/
Hour4(TIMESLICE) /W4,SF4,S4/
Hour5(TIMESLICE) /W5,SF5,S5/
Hour6(TIMESLICE) /W6,SF6,S6/
Hour7(TIMESLICE) /W7,SF7,S7/
Hour8(TIMESLICE) /W8,SF8,S8/
Hour9(TIMESLICE) /W9,SF9,S9/
Hour10(TIMESLICE) /W10,SF10,S10/
Hour11(TIMESLICE) /W11,SF11,S11/
Hour12(TIMESLICE) /W12,SF12,S12/
Hour13(TIMESLICE) /W13,SF13,S13/
Hour14(TIMESLICE) /W14,SF14,S14/
Hour15(TIMESLICE) /W15,SF15,S15/
Hour16(TIMESLICE) /W16,SF16,S16/
Hour17(TIMESLICE) /W17,SF17,S17/
Hour18(TIMESLICE) /W18,SF18,S18/
Hour19(TIMESLICE) /W19,SF19,S19/
Hour20(TIMESLICE) /W20,SF20,S20/
Hour21(TIMESLICE) /W21,SF21,S21/
Hour22(TIMESLICE) /W22,SF22,S22/
Hour23(TIMESLICE) /W23,SF23,S23/
Hour24(TIMESLICE) /W24,SF24,S24/

LowV2G(TIMESLICE) / W6,SF6,S6,W7,SF7,S7,W8,SF8,S8,W9,SF9,S9,W10,SF10,S10,
         W11,SF11,S11,W12,SF12,S12,W13,SF13,S13,W14,SF14,S14,W15,SF15,S15,W16,SF16,S16,
         W17,SF17,S17,W18,SF18,S18,W19,SF19,S19,W20,SF20,S20 /
HighV2G(TIMESLICE) / W21,SF21,S21,W22,SF22,S22,W23,SF23,S23,W24,SF24,S24,
         W1,SF1,S1,W2,SF2,S2,W3,SF3,S3,W4,SF4,S4,W5,SF5,S5 /;



alias (l,ll,TIMESLICE);
* Summary of Set: TIMESLICE


set FUEL / ELC, COAL, GAS, HYDRO, URN, BIO, WIND, SOL, PET, DSL, BIO_DSL, H2, VMT, FMT, PM /

*Subsets
TransportFuel(FUEL) /VMT, FMT, PM/;
alias (f,FUEL);
* Summary of Set: FUEL
* ELC = Electricity
* COAL = Coal
* GAS = Gas (for use in PP and CNG vehicles)
* HYDRO = Hydro
* URN = Uranium
* BIO = Biomass
* WIND = Wind
* SOL = Solar
* PET = (Petrol) Gasoline for ICE, HYBRID. Units: Millions of Gallons
* DSL = Diesel fuel for ICE. Units: Millions of Gallons
* BIO_DSL = Bio-diesel fuel for use in bio-diesel vehicles. Units: Millions of Gallons
* H2 = Hydrogen Gas. Units: Millions of GGEs
* VMT = (Demand) Vehicle Miles Traveled. Units: Millions of Miles
* FMT = (Demand) Fleet Miles Traveled. Units: Millions of Miles
* PM = (Demand) Passenger - Miles. Units: Millions of Miles

set EMISSION / CO2 /;
alias (e,ee,EMISSION);
* Summary of Set: EMISSION
* CO2 = Carbon dioxide

set MODE_OF_OPERATION / 1, 2/;
alias (m,MODE_OF_OPERATION);
* Summary of Set: MODE_OF_OPERATION
* 1 = Electricity generation
* 2 = Electricity consumption for storage (Charging)

set REGION / ATX /;
alias (r,rr,REGION);

set STORAGE /BAT, EV_BAT, EV_BAT_F/;
alias (s,STORAGE);
* Summary of Set: STORAGE
* BAT = Lithium-ion battery capacity
* BAT_V2g = Car battery (lithium-ion) battery capacity


set SEASON / WINTER, SPR_FALL, SUMMER/;
alias(ls,SEASON);

* ##### Parameters #####

* ##### Global #####

parameter StartYear / 2015 /;

parameter YearSplit(TIMESLICE,YEAR);
* Fraction of the year in each timeslice, sum to 1
* Units: Fraction
YearSplit(WNT,YEAR) = (1/24)*(89/365);
YearSplit(SPRFALL,YEAR) = (1/24)*((93+90)/365);
YearSplit(SUMM,YEAR) = (1/24)*(93/365);


parameter TimeSliceInSeason(TIMESLICE,SEASON);
* Assignment of timeslices to seasons for diurnal storage
TimeSliceInSeason(WNT,"WINTER") = 1;
TimeSliceInSeason(WNT,"SPR_FALL") = 0;
TimeSliceInSeason(WNT,"SUMMER") = 0;

TimeSliceInSeason(SPRFALL,"WINTER") = 0;
TimeSliceInSeason(SPRFALL,"SPR_FALL") = 1;
TimeSliceInSeason(SPRFALL,"SUMMER") = 0;

TimeSliceInSeason(SUMM,"WINTER") = 0;
TimeSliceInSeason(SUMM,"SPR_FALL") = 0;
TimeSliceInSeason(SUMM,"SUMMER") = 1;

parameter DaysInSeason(TIMESLICE);
* # of days in each season, used for determining storage levels
DaysInSeason(WNT) = 89;
DaysInSeason(SPRFALL) = 93+90;
DaysInSeason(SUMM) = 93;



parameter DiscountRate(REGION,TECHNOLOGY);
DiscountRate(REGION,TECHNOLOGY) = 0.05;


* ##### Demands #####

table SpecifiedAnnualDemand(REGION,FUEL,YEAR)
* Total annual demand for demands that are timeslice-dependent
* Units: PJ (ELC, GAS), Millions Miles (VMT, PM, FM)
* Data Source: See Data spreadsheet

                 2015               2016               2017               2018               2019               2020               2021               2022               2023               2024               2025              2026               2027               2028               2029               2030               2031               2032               2033               2034               2035               2036               2037               2038               2039               2040               2041               2042               2043               2044               2045               2046               2047               2048               2049               2050
ATX.ELC          82.19109387        82.00759672        83.42519755        84.85160618        87.20556128        88.81377255        90.18773768        91.62532427        93.05529826        94.49578657        95.9009422        97.39097936        99.14401699        100.9286093        102.7453243        104.5947401        106.4774454        108.3940394        110.3451321        112.3313445        114.3533087        116.4116683        118.5070783        120.6402057        122.8117294        125.0223406        127.2727427        129.5636521        131.8957978        134.2699221        136.6867807        139.1471428        141.6517914        144.2015236        146.797151         149.4394998
ATX.VMT          9500.85062         9377.52992         9225.98291         9045.09493         8834.67014         8595.65385         8330.29085         8042.17808         7736.17931         7418.19002         7094.76943        6772.68516         6458.43610         6157.82299         5875.62399         5615.40699         5379.48255         5168.97680         4983.98957         4823.79926         4687.07993         4572.10550         4476.92526         4399.50419         4337.82750         4289.97289         4254.15614         4228.75569         4212.32199         4203.57607         4201.40131         4204.83107         4213.03432         4225.30064         4241.02557         4259.69675
*ATX.VMT          10641.808          10724.8139         10808.46745        10892.77349        10977.73712        11063.36347        11149.65771        11236.62504        11324.27071        11412.60003        11501.61831       11591.33093        11681.74331        11772.86091        11864.68922        11957.2338         12050.50022        12144.49412        12239.22118        12334.6871         12430.89766        12527.85867        12625.57596        12724.05546        12823.30309        12923.32485        13024.12679        13125.71498        13228.09555        13331.2747         13435.25864        13540.05366        13645.66608        13752.10227        13859.36867        13967.47174
ATX.FMT          1140.957177        1347.283978        1582.484533        1847.678563        2143.066985        2467.709624        2819.366864        3194.446963        3588.091408        3994.410009        4406.848881       4818.645766        5223.307214        5615.037916        5989.065237        6341.826812        6671.017672        6975.51733         7255.23161         7510.887848        7743.817729        7955.753165        8148.650703        8324.551261        8485.475589        8633.35196         8769.970647        8896.959281        9015.773561        9127.698625        9233.857327        9335.222587        9432.631759        9526.80163         9618.343095        9707.77499
ATX.PM           183.570715         185.0025666        186.4455866        187.8998622        189.3654811        190.8425318        192.3311036        193.8312862        195.3431702        196.866847         198.4024084       199.9499472        201.5095567        203.0813313        204.6653657        206.2617555        207.8705972        209.4919879        211.1260254        212.7728084        214.4324363        216.1050093        217.7906284        219.4893953        221.2014125        222.9267836        224.6656125        226.4180043        228.1840647        229.9639004        231.7576188        233.5653282        235.3871378        237.2231575        239.0734981        240.9382714;

*SpecifiedAnnualDemand(r,"FMT",y) = 0;

scalar DM /2/;

SpecifiedAnnualDemand(r,"FMT",y) = DM * SpecifiedAnnualDemand(r,"FMT",y);

parameter SpecifiedDemandProfile(REGION,FUEL,TIMESLICE,YEAR);
* Fraction of the total annual demand occurring in each timeslice
* Units: Fraction
* Data Source: See data spreadsheet

SpecifiedDemandProfile(r,f,l,y) = 0;
*ELC
SpecifiedDemandProfile(r,"ELC","W4",YEAR) = 0.0081269159814074;
SpecifiedDemandProfile(r,"ELC","W5",YEAR) = 0.00818805296206696;
SpecifiedDemandProfile(r,"ELC","W3",YEAR) = 0.00820311433283876;
SpecifiedDemandProfile(r,"ELC","W2",YEAR) = 0.00841409137009381;
SpecifiedDemandProfile(r,"ELC","W6",YEAR) = 0.00844855621354717;
SpecifiedDemandProfile(r,"ELC","W1",YEAR) = 0.00881209077445789;
SpecifiedDemandProfile(r,"ELC","W7",YEAR) = 0.00911006750907696;
SpecifiedDemandProfile(r,"ELC","W17",YEAR) = 0.0092684216889391;
SpecifiedDemandProfile(r,"ELC","W16",YEAR) = 0.00929110449701335;
SpecifiedDemandProfile(r,"ELC","S6",YEAR) = 0.00931350123576554;
SpecifiedDemandProfile(r,"ELC","W18",YEAR) = 0.00937770270725529;
SpecifiedDemandProfile(r,"ELC","W15",YEAR) = 0.00941569606486843;
SpecifiedDemandProfile(r,"ELC","S5",YEAR) = 0.0094335180937913;
SpecifiedDemandProfile(r,"ELC","W24",YEAR) = 0.00948167400456741;
SpecifiedDemandProfile(r,"ELC","S7",YEAR) = 0.00954132976322534;
SpecifiedDemandProfile(r,"ELC","W14",YEAR) = 0.00958575604080087;
SpecifiedDemandProfile(r,"ELC","S4",YEAR) = 0.00977097083757978;
SpecifiedDemandProfile(r,"ELC","W19",YEAR) = 0.00977516239144087;
SpecifiedDemandProfile(r,"ELC","W13",YEAR) = 0.00980035812690779;
SpecifiedDemandProfile(r,"ELC","W12",YEAR) = 0.010021320856274;
SpecifiedDemandProfile(r,"ELC","S8",YEAR) = 0.0100213270338048;
SpecifiedDemandProfile(r,"ELC","W23",YEAR) = 0.0100709926545032;
SpecifiedDemandProfile(r,"ELC","W8",YEAR) = 0.0100995362108464;
SpecifiedDemandProfile(r,"ELC","W11",YEAR) = 0.0102041196633245;
SpecifiedDemandProfile(r,"ELC","S9",YEAR) = 0.010254374451314;
SpecifiedDemandProfile(r,"ELC","S3",YEAR) = 0.010306049050825;
SpecifiedDemandProfile(r,"ELC","W10",YEAR) = 0.0103412376915389;
SpecifiedDemandProfile(r,"ELC","W22",YEAR) = 0.0104177838465335;
SpecifiedDemandProfile(r,"ELC","W20",YEAR) = 0.0104345056929535;
SpecifiedDemandProfile(r,"ELC","W9",YEAR) = 0.0104787356977286;
SpecifiedDemandProfile(r,"ELC","W21",YEAR) = 0.0105419500357659;
SpecifiedDemandProfile(r,"ELC","S10",YEAR) = 0.0108140705967118;
SpecifiedDemandProfile(r,"ELC","S2",YEAR) = 0.0110806328557676;
SpecifiedDemandProfile(r,"ELC","S11",YEAR) = 0.0116576187113313;
SpecifiedDemandProfile(r,"ELC","S1",YEAR) = 0.0121407019136297;
SpecifiedDemandProfile(r,"ELC","S12",YEAR) = 0.0126125263345721;
SpecifiedDemandProfile(r,"ELC","S24",YEAR) = 0.0133904150512906;
SpecifiedDemandProfile(r,"ELC","S13",YEAR) = 0.013546476548267;
SpecifiedDemandProfile(r,"ELC","S14",YEAR) = 0.0143997653977014;
SpecifiedDemandProfile(r,"ELC","S23",YEAR) = 0.0144717207758439;
SpecifiedDemandProfile(r,"ELC","SF5",YEAR) = 0.0145915320530283;
SpecifiedDemandProfile(r,"ELC","SF6",YEAR) = 0.0146519139020302;
SpecifiedDemandProfile(r,"ELC","SF4",YEAR) = 0.0148875402357804;
SpecifiedDemandProfile(r,"ELC","S22",YEAR) = 0.0149819799379714;
SpecifiedDemandProfile(r,"ELC","S15",YEAR) = 0.0151582476360959;
SpecifiedDemandProfile(r,"ELC","SF7",YEAR) = 0.0154505234045412;
SpecifiedDemandProfile(r,"ELC","SF3",YEAR) = 0.0154679767554694;
SpecifiedDemandProfile(r,"ELC","S21",YEAR) = 0.0155246710021878;
SpecifiedDemandProfile(r,"ELC","S16",YEAR) = 0.0157159101860119;
SpecifiedDemandProfile(r,"ELC","S20",YEAR) = 0.0161314999537668;
SpecifiedDemandProfile(r,"ELC","S17",YEAR) = 0.0161465478133629;
SpecifiedDemandProfile(r,"ELC","S18",YEAR) = 0.0163738449958081;
SpecifiedDemandProfile(r,"ELC","S19",YEAR) = 0.0163767245078411;
SpecifiedDemandProfile(r,"ELC","SF2",YEAR) = 0.0164489318452153;
SpecifiedDemandProfile(r,"ELC","SF8",YEAR) = 0.0170280662662261;
SpecifiedDemandProfile(r,"ELC","SF9",YEAR) = 0.0176895226012784;
SpecifiedDemandProfile(r,"ELC","SF1",YEAR) = 0.0179156945916863;
SpecifiedDemandProfile(r,"ELC","SF10",YEAR) = 0.0180075082288978;
SpecifiedDemandProfile(r,"ELC","SF11",YEAR) = 0.0187230090074772;
SpecifiedDemandProfile(r,"ELC","SF12",YEAR) = 0.0195170531799759;
SpecifiedDemandProfile(r,"ELC","SF24",YEAR) = 0.0197197180450751;
SpecifiedDemandProfile(r,"ELC","SF13",YEAR) = 0.0202353969486849;
SpecifiedDemandProfile(r,"ELC","SF14",YEAR) = 0.0209040288998419;
SpecifiedDemandProfile(r,"ELC","SF23",YEAR) = 0.0213942971187149;
SpecifiedDemandProfile(r,"ELC","SF15",YEAR) = 0.0215579821022833;
SpecifiedDemandProfile(r,"ELC","SF16",YEAR) = 0.0220962154791736;
SpecifiedDemandProfile(r,"ELC","SF22",YEAR) = 0.0223948914503962;
SpecifiedDemandProfile(r,"ELC","SF17",YEAR) = 0.022580781095761;
SpecifiedDemandProfile(r,"ELC","SF21",YEAR) = 0.0226099128687166;
SpecifiedDemandProfile(r,"ELC","SF18",YEAR) = 0.0229405628390174;
SpecifiedDemandProfile(r,"ELC","SF20",YEAR) = 0.0229864928128649;
SpecifiedDemandProfile(r,"ELC","SF19",YEAR) = 0.023127076568646;



*VMT
SpecifiedDemandProfile(r,"VMT","SF1",YEAR) = 0.001867134;
SpecifiedDemandProfile(r,"VMT","SF2",YEAR) = 0.000629468;
SpecifiedDemandProfile(r,"VMT","SF3",YEAR) = 0.000579962;
SpecifiedDemandProfile(r,"VMT","SF4",YEAR) = 0.000310976;
SpecifiedDemandProfile(r,"VMT","SF5",YEAR) = 0.005580134;
SpecifiedDemandProfile(r,"VMT","SF6",YEAR) = 0.0086989;
SpecifiedDemandProfile(r,"VMT","SF7",YEAR) = 0.024150876;
SpecifiedDemandProfile(r,"VMT","SF8",YEAR) = 0.03331832;
SpecifiedDemandProfile(r,"VMT","SF9",YEAR) = 0.027853764;
SpecifiedDemandProfile(r,"VMT","SF10",YEAR) = 0.03384141;
SpecifiedDemandProfile(r,"VMT","SF11",YEAR) = 0.031585434;
SpecifiedDemandProfile(r,"VMT","SF12",YEAR) = 0.03312393;
SpecifiedDemandProfile(r,"VMT","SF13",YEAR) = 0.035656318;
SpecifiedDemandProfile(r,"VMT","SF14",YEAR) = 0.033082766;
SpecifiedDemandProfile(r,"VMT","SF15",YEAR) = 0.033715138;
SpecifiedDemandProfile(r,"VMT","SF16",YEAR) = 0.03616031;
SpecifiedDemandProfile(r,"VMT","SF17",YEAR) = 0.041161338;
SpecifiedDemandProfile(r,"VMT","SF18",YEAR) = 0.038377996;
SpecifiedDemandProfile(r,"VMT","SF19",YEAR) = 0.031471262;
SpecifiedDemandProfile(r,"VMT","SF20",YEAR) = 0.017976816;
SpecifiedDemandProfile(r,"VMT","SF21",YEAR) = 0.013160278;
SpecifiedDemandProfile(r,"VMT","SF22",YEAR) = 0.009801708;
SpecifiedDemandProfile(r,"VMT","SF23",YEAR) = 0.005230134;
SpecifiedDemandProfile(r,"VMT","SF24",YEAR) = 0.002665628;

SpecifiedDemandProfile(r,"VMT","W1",YEAR) = 0.000933567;
SpecifiedDemandProfile(r,"VMT","W2",YEAR) = 0.000314734;
SpecifiedDemandProfile(r,"VMT","W3",YEAR) = 0.000289981;
SpecifiedDemandProfile(r,"VMT","W4",YEAR) = 0.000155488;
SpecifiedDemandProfile(r,"VMT","W5",YEAR) = 0.002790067;
SpecifiedDemandProfile(r,"VMT","W6",YEAR) = 0.00434945;
SpecifiedDemandProfile(r,"VMT","W7",YEAR) = 0.012075438;
SpecifiedDemandProfile(r,"VMT","W8",YEAR) = 0.01665916;
SpecifiedDemandProfile(r,"VMT","W9",YEAR) = 0.013926882;
SpecifiedDemandProfile(r,"VMT","W10",YEAR) = 0.016920705;
SpecifiedDemandProfile(r,"VMT","W11",YEAR) = 0.015792717;
SpecifiedDemandProfile(r,"VMT","W12",YEAR) = 0.016561965;
SpecifiedDemandProfile(r,"VMT","W13",YEAR) = 0.017828159;
SpecifiedDemandProfile(r,"VMT","W14",YEAR) = 0.016541383;
SpecifiedDemandProfile(r,"VMT","W15",YEAR) = 0.016857569;
SpecifiedDemandProfile(r,"VMT","W16",YEAR) = 0.018080155;
SpecifiedDemandProfile(r,"VMT","W17",YEAR) = 0.020580669;
SpecifiedDemandProfile(r,"VMT","W18",YEAR) = 0.019188998;
SpecifiedDemandProfile(r,"VMT","W19",YEAR) = 0.015735631;
SpecifiedDemandProfile(r,"VMT","W20",YEAR) = 0.008988408;
SpecifiedDemandProfile(r,"VMT","W21",YEAR) = 0.006580139;
SpecifiedDemandProfile(r,"VMT","W22",YEAR) = 0.004900854;
SpecifiedDemandProfile(r,"VMT","W23",YEAR) = 0.002615067;
SpecifiedDemandProfile(r,"VMT","W24",YEAR) = 0.001332814;

SpecifiedDemandProfile(r,"VMT","S1",YEAR) = 0.000933567;
SpecifiedDemandProfile(r,"VMT","S2",YEAR) = 0.000314734;
SpecifiedDemandProfile(r,"VMT","S3",YEAR) = 0.000289981;
SpecifiedDemandProfile(r,"VMT","S4",YEAR) = 0.000155488;
SpecifiedDemandProfile(r,"VMT","S5",YEAR) = 0.002790067;
SpecifiedDemandProfile(r,"VMT","S6",YEAR) = 0.00434945;
SpecifiedDemandProfile(r,"VMT","S7",YEAR) = 0.012075438;
SpecifiedDemandProfile(r,"VMT","S8",YEAR) = 0.01665916;
SpecifiedDemandProfile(r,"VMT","S9",YEAR) = 0.013926882;
SpecifiedDemandProfile(r,"VMT","S10",YEAR) = 0.016920705;
SpecifiedDemandProfile(r,"VMT","S11",YEAR) = 0.015792717;
SpecifiedDemandProfile(r,"VMT","S12",YEAR) = 0.016561965;
SpecifiedDemandProfile(r,"VMT","S13",YEAR) = 0.017828159;
SpecifiedDemandProfile(r,"VMT","S14",YEAR) = 0.016541383;
SpecifiedDemandProfile(r,"VMT","S15",YEAR) = 0.016857569;
SpecifiedDemandProfile(r,"VMT","S16",YEAR) = 0.018080155;
SpecifiedDemandProfile(r,"VMT","S17",YEAR) = 0.020580669;
SpecifiedDemandProfile(r,"VMT","S18",YEAR) = 0.019188998;
SpecifiedDemandProfile(r,"VMT","S19",YEAR) = 0.015735631;
SpecifiedDemandProfile(r,"VMT","S20",YEAR) = 0.008988408;
SpecifiedDemandProfile(r,"VMT","S21",YEAR) = 0.006580139;
SpecifiedDemandProfile(r,"VMT","S22",YEAR) = 0.004900854;
SpecifiedDemandProfile(r,"VMT","S23",YEAR) = 0.002615067;
SpecifiedDemandProfile(r,"VMT","S24",YEAR) = 0.001332814;

*FMT
SpecifiedDemandProfile(r,"FMT","SF1",YEAR) = 0.001867134;
SpecifiedDemandProfile(r,"FMT","SF2",YEAR) = 0.000629468;
SpecifiedDemandProfile(r,"FMT","SF3",YEAR) = 0.000579962;
SpecifiedDemandProfile(r,"FMT","SF4",YEAR) = 0.000310976;
SpecifiedDemandProfile(r,"FMT","SF5",YEAR) = 0.005580134;
SpecifiedDemandProfile(r,"FMT","SF6",YEAR) = 0.0086989;
SpecifiedDemandProfile(r,"FMT","SF7",YEAR) = 0.024150876;
SpecifiedDemandProfile(r,"FMT","SF8",YEAR) = 0.03331832;
SpecifiedDemandProfile(r,"FMT","SF9",YEAR) = 0.027853764;
SpecifiedDemandProfile(r,"FMT","SF10",YEAR) = 0.03384141;
SpecifiedDemandProfile(r,"FMT","SF11",YEAR) = 0.031585434;
SpecifiedDemandProfile(r,"FMT","SF12",YEAR) = 0.03312393;
SpecifiedDemandProfile(r,"FMT","SF13",YEAR) = 0.035656318;
SpecifiedDemandProfile(r,"FMT","SF14",YEAR) = 0.033082766;
SpecifiedDemandProfile(r,"FMT","SF15",YEAR) = 0.033715138;
SpecifiedDemandProfile(r,"FMT","SF16",YEAR) = 0.03616031;
SpecifiedDemandProfile(r,"FMT","SF17",YEAR) = 0.041161338;
SpecifiedDemandProfile(r,"FMT","SF18",YEAR) = 0.038377996;
SpecifiedDemandProfile(r,"FMT","SF19",YEAR) = 0.031471262;
SpecifiedDemandProfile(r,"FMT","SF20",YEAR) = 0.017976816;
SpecifiedDemandProfile(r,"FMT","SF21",YEAR) = 0.013160278;
SpecifiedDemandProfile(r,"FMT","SF22",YEAR) = 0.009801708;
SpecifiedDemandProfile(r,"FMT","SF23",YEAR) = 0.005230134;
SpecifiedDemandProfile(r,"FMT","SF24",YEAR) = 0.002665628;

SpecifiedDemandProfile(r,"FMT","W1",YEAR) = 0.000933567;
SpecifiedDemandProfile(r,"FMT","W2",YEAR) = 0.000314734;
SpecifiedDemandProfile(r,"FMT","W3",YEAR) = 0.000289981;
SpecifiedDemandProfile(r,"FMT","W4",YEAR) = 0.000155488;
SpecifiedDemandProfile(r,"FMT","W5",YEAR) = 0.002790067;
SpecifiedDemandProfile(r,"FMT","W6",YEAR) = 0.00434945;
SpecifiedDemandProfile(r,"FMT","W7",YEAR) = 0.012075438;
SpecifiedDemandProfile(r,"FMT","W8",YEAR) = 0.01665916;
SpecifiedDemandProfile(r,"FMT","W9",YEAR) = 0.013926882;
SpecifiedDemandProfile(r,"FMT","W10",YEAR) = 0.016920705;
SpecifiedDemandProfile(r,"FMT","W11",YEAR) = 0.015792717;
SpecifiedDemandProfile(r,"FMT","W12",YEAR) = 0.016561965;
SpecifiedDemandProfile(r,"FMT","W13",YEAR) = 0.017828159;
SpecifiedDemandProfile(r,"FMT","W14",YEAR) = 0.016541383;
SpecifiedDemandProfile(r,"FMT","W15",YEAR) = 0.016857569;
SpecifiedDemandProfile(r,"FMT","W16",YEAR) = 0.018080155;
SpecifiedDemandProfile(r,"FMT","W17",YEAR) = 0.020580669;
SpecifiedDemandProfile(r,"FMT","W18",YEAR) = 0.019188998;
SpecifiedDemandProfile(r,"FMT","W19",YEAR) = 0.015735631;
SpecifiedDemandProfile(r,"FMT","W20",YEAR) = 0.008988408;
SpecifiedDemandProfile(r,"FMT","W21",YEAR) = 0.006580139;
SpecifiedDemandProfile(r,"FMT","W22",YEAR) = 0.004900854;
SpecifiedDemandProfile(r,"FMT","W23",YEAR) = 0.002615067;
SpecifiedDemandProfile(r,"FMT","W24",YEAR) = 0.001332814;

SpecifiedDemandProfile(r,"FMT","S1",YEAR) = 0.000933567;
SpecifiedDemandProfile(r,"FMT","S2",YEAR) = 0.000314734;
SpecifiedDemandProfile(r,"FMT","S3",YEAR) = 0.000289981;
SpecifiedDemandProfile(r,"FMT","S4",YEAR) = 0.000155488;
SpecifiedDemandProfile(r,"FMT","S5",YEAR) = 0.002790067;
SpecifiedDemandProfile(r,"FMT","S6",YEAR) = 0.00434945;
SpecifiedDemandProfile(r,"FMT","S7",YEAR) = 0.012075438;
SpecifiedDemandProfile(r,"FMT","S8",YEAR) = 0.01665916;
SpecifiedDemandProfile(r,"FMT","S9",YEAR) = 0.013926882;
SpecifiedDemandProfile(r,"FMT","S10",YEAR) = 0.016920705;
SpecifiedDemandProfile(r,"FMT","S11",YEAR) = 0.015792717;
SpecifiedDemandProfile(r,"FMT","S12",YEAR) = 0.016561965;
SpecifiedDemandProfile(r,"FMT","S13",YEAR) = 0.017828159;
SpecifiedDemandProfile(r,"FMT","S14",YEAR) = 0.016541383;
SpecifiedDemandProfile(r,"FMT","S15",YEAR) = 0.016857569;
SpecifiedDemandProfile(r,"FMT","S16",YEAR) = 0.018080155;
SpecifiedDemandProfile(r,"FMT","S17",YEAR) = 0.020580669;
SpecifiedDemandProfile(r,"FMT","S18",YEAR) = 0.019188998;
SpecifiedDemandProfile(r,"FMT","S19",YEAR) = 0.015735631;
SpecifiedDemandProfile(r,"FMT","S20",YEAR) = 0.008988408;
SpecifiedDemandProfile(r,"FMT","S21",YEAR) = 0.006580139;
SpecifiedDemandProfile(r,"FMT","S22",YEAR) = 0.004900854;
SpecifiedDemandProfile(r,"FMT","S23",YEAR) = 0.002615067;
SpecifiedDemandProfile(r,"FMT","S24",YEAR) = 0.001332814;



*PM
SpecifiedDemandProfile(r,"PM","SF1",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","SF2",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","SF3",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","SF4",YEAR) = 0.00000729672966224772;
SpecifiedDemandProfile(r,"PM","SF5",YEAR) = 0.00282411679096896;
SpecifiedDemandProfile(r,"PM","SF6",YEAR) = 0.0125443327226761;
SpecifiedDemandProfile(r,"PM","SF7",YEAR) = 0.0380635446243817;
SpecifiedDemandProfile(r,"PM","SF8",YEAR) = 0.0546324276701657;
SpecifiedDemandProfile(r,"PM","SF9",YEAR) = 0.0105229284394025;
SpecifiedDemandProfile(r,"PM","SF10",YEAR) = 0.0251543360123124;
SpecifiedDemandProfile(r,"PM","SF11",YEAR) = 0.0158938731587481;
SpecifiedDemandProfile(r,"PM","SF12",YEAR) = 0.0440912541227508;
SpecifiedDemandProfile(r,"PM","SF13",YEAR) = 0.0120043156182486;
SpecifiedDemandProfile(r,"PM","SF14",YEAR) = 0.010851314112771;
SpecifiedDemandProfile(r,"PM","SF15",YEAR) = 0.0215201968485589;
SpecifiedDemandProfile(r,"PM","SF16",YEAR) = 0.0747077472590436;
SpecifiedDemandProfile(r,"PM","SF17",YEAR) = 0.0357867416675025;
SpecifiedDemandProfile(r,"PM","SF18",YEAR) = 0.0711502270406004;
SpecifiedDemandProfile(r,"PM","SF19",YEAR) = 0.019703140402109;
SpecifiedDemandProfile(r,"PM","SF20",YEAR) = 0.0104426644131178;
SpecifiedDemandProfile(r,"PM","SF21",YEAR) = 0.027445745563943;
SpecifiedDemandProfile(r,"PM","SF22",YEAR) = 0.00859640791259204;
SpecifiedDemandProfile(r,"PM","SF23",YEAR) = 0.00178057936585206;
SpecifiedDemandProfile(r,"PM","SF24",YEAR) = 0.00227680952459265;
SpecifiedDemandProfile(r,"PM","S1",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","S2",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","S3",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","S4",YEAR) = 0.00000364836483112386;
SpecifiedDemandProfile(r,"PM","S5",YEAR) = 0.00141205839548448;
SpecifiedDemandProfile(r,"PM","S6",YEAR) = 0.00627216636133805;
SpecifiedDemandProfile(r,"PM","S7",YEAR) = 0.0190317723121908;
SpecifiedDemandProfile(r,"PM","S8",YEAR) = 0.0273162138350828;
SpecifiedDemandProfile(r,"PM","S9",YEAR) = 0.00526146421970126;
SpecifiedDemandProfile(r,"PM","S10",YEAR) = 0.0125771680061562;
SpecifiedDemandProfile(r,"PM","S11",YEAR) = 0.00794693657937405;
SpecifiedDemandProfile(r,"PM","S12",YEAR) = 0.0220456270613754;
SpecifiedDemandProfile(r,"PM","S13",YEAR) = 0.00600215780912428;
SpecifiedDemandProfile(r,"PM","S14",YEAR) = 0.0054256570563855;
SpecifiedDemandProfile(r,"PM","S15",YEAR) = 0.0107600984242794;
SpecifiedDemandProfile(r,"PM","S16",YEAR) = 0.0373538736295218;
SpecifiedDemandProfile(r,"PM","S17",YEAR) = 0.0178933708337513;
SpecifiedDemandProfile(r,"PM","S18",YEAR) = 0.0355751135203002;
SpecifiedDemandProfile(r,"PM","S19",YEAR) = 0.00985157020105452;
SpecifiedDemandProfile(r,"PM","S20",YEAR) = 0.0052213322065589;
SpecifiedDemandProfile(r,"PM","S21",YEAR) = 0.0137228727819715;
SpecifiedDemandProfile(r,"PM","S22",YEAR) = 0.00429820395629602;
SpecifiedDemandProfile(r,"PM","S23",YEAR) = 0.000890289682926031;
SpecifiedDemandProfile(r,"PM","S24",YEAR) = 0.00113840476229632;
SpecifiedDemandProfile(r,"PM","W1",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","W2",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","W3",YEAR) = 0;
SpecifiedDemandProfile(r,"PM","W4",YEAR) = 0.00000364836483112386;
SpecifiedDemandProfile(r,"PM","W5",YEAR) = 0.00141205839548448;
SpecifiedDemandProfile(r,"PM","W6",YEAR) = 0.00627216636133805;
SpecifiedDemandProfile(r,"PM","W7",YEAR) = 0.0190317723121908;
SpecifiedDemandProfile(r,"PM","W8",YEAR) = 0.0273162138350828;
SpecifiedDemandProfile(r,"PM","W9",YEAR) = 0.00526146421970126;
SpecifiedDemandProfile(r,"PM","W10",YEAR) = 0.0125771680061562;
SpecifiedDemandProfile(r,"PM","W11",YEAR) = 0.00794693657937405;
SpecifiedDemandProfile(r,"PM","W12",YEAR) = 0.0220456270613754;
SpecifiedDemandProfile(r,"PM","W13",YEAR) = 0.00600215780912428;
SpecifiedDemandProfile(r,"PM","W14",YEAR) = 0.0054256570563855;
SpecifiedDemandProfile(r,"PM","W15",YEAR) = 0.0107600984242794;
SpecifiedDemandProfile(r,"PM","W16",YEAR) = 0.0373538736295218;
SpecifiedDemandProfile(r,"PM","W17",YEAR) = 0.0178933708337513;
SpecifiedDemandProfile(r,"PM","W18",YEAR) = 0.0355751135203002;
SpecifiedDemandProfile(r,"PM","W19",YEAR) = 0.00985157020105452;
SpecifiedDemandProfile(r,"PM","W20",YEAR) = 0.0052213322065589;
SpecifiedDemandProfile(r,"PM","W21",YEAR) = 0.0137228727819715;
SpecifiedDemandProfile(r,"PM","W22",YEAR) = 0.00429820395629602;
SpecifiedDemandProfile(r,"PM","W23",YEAR) = 0.000890289682926031;
SpecifiedDemandProfile(r,"PM","W24",YEAR) = 0.00113840476229632;


parameter AccumulatedAnnualDemand(REGION,FUEL,YEAR);
* Demand that can be satisfied at any time of the year
* Units: PJ
AccumulatedAnnualDemand(REGION,FUEL,YEAR) = 0;

* ##### Technology #####

* ##### Performance #####

parameter CapacityToActivityUnit(REGION,TECHNOLOGY);
* Level of production for one unit of capacity operating all hours of the year
* Should be 31.536 for all power plants, Units: PJ/GW-YR
CapacityToActivityUnit(r,"COALPP") = 31.536;
CapacityToActivityUnit(r,"CCPP") = 31.536;
CapacityToActivityUnit(r,"CTPP") = 31.536;
CapacityToActivityUnit(r,"NUCPP") = 31.536;
CapacityToActivityUnit(r,"HYDROPP") = 31.536;
CapacityToActivityUnit(r,"WINDPP") = 31.536;
CapacityToActivityUnit(r,"SOLPP") = 31.536;
CapacityToActivityUnit(r,"BIOPP") = 31.536;
CapacityToActivityUnit(r,"CCCCSPP") = 31.536;
CapacityToActivityUnit(r,"IGCCCCSPP") = 31.536;
CapacityToActivityUnit(r,"H2FUELCELL") = 31.536;
CapacityToActivityUnit(r,"BATTERY") = 31.536;
CapacityToActivityUnit(r,"EV_CHARGE") = 31.536;
CapacityToActivityUnit(r,"V2G") = 31.536;
CapacityToActivityUnit(r,"EV_DISCHARGE") = 31.536;
CapacityToActivityUnit(r,"EV_CHARGE_F") = 31.536;
CapacityToActivityUnit(r,"V2G_F") = 31.536;
CapacityToActivityUnit(r,"EV_DISCHARGE_F") = 31.536;
CapacityToActivityUnit(r,"BUYCOAL") = 1;
CapacityToActivityUnit(r,"BUYURN") = 1;
CapacityToActivityUnit(r,"BUYBIO") = 1;
CapacityToActivityUnit(r,"BUYGAS") = 1;
CapacityToActivityUnit(r,"BUYPET") = 1;
CapacityToActivityUnit(r,"BUYDSL") = 1;
CapacityToActivityUnit(r,"BUYBIO_DSL") = 1;
CapacityToActivityUnit(r,"SOLPOT") = 1;
CapacityToActivityUnit(r,"WINDPOT") = 1;
CapacityToActivityUnit(r,"HYDROPOT") = 1;
CapacityToActivityUnit(r,"ELCTROL") = 1;
CapacityToActivityUnit(r,"GASREF") = 1;
CapacityToActivityUnit(r,"BIOGAS") = 1;
CapacityToActivityUnit(r,"COALGAS") = 1;

CapacityToActivityUnit(r,PrivTrans) = 300;
CapacityToActivityUnit(r,Fleet) = 300;
CapacityToActivityUnit(r,PubTrans) = 60000;

table TechWithCapacityNeededToMeetPeakTS(REGION,TECHNOLOGY)
* Timeslice-dependent technologies (i.e. power plants and intermittent resource potentials)
* Units: 1=yes, 0=no
                COALPP  CCPP    CTPP    NUCPP   HYDROPP WINDPP  SOLPP   BIOPP   CCCCSPP IGCCCCSPP       H2FUELCELL      BATTERY EV_CHARGE  V2G   EV_DISCHARGE EV_CHARGE_F  V2G_F   EV_DISCHARGE_F             BUYCOAL BUYURN  BUYBIO  BUYGAS  BUYPET  BUYDSL  BUYBIO_DSL      SOLPOT  WINDPOT HYDROPOT        ICE_PET ICE_DSL PHEV    HYBRID  H2V     EV    ICE_PET_F   ICE_DSL_F PHEV_F    HYBRID_F  H2V_F     EV_F      ICE_PET_PUB     ICE_DSL_PUB     CNG_PUB EV_PUB  PHEV_PUB        HYBRID_PUB      BIO_DSL_PUB     ELCTROL GASREF  BIOGAS  COALGAS
ATX             1       1       1       1       1       1       1       1       1       1               1               1       1          1     1            1            1       1                          0       0       0       0       0       0       0               1       1       1               1       1       1       1       1       1     1           1         1         1         1         1         1               1               1       1       1               1               1               1       1       1       1;

parameter CapacityFactor(REGION,TECHNOLOGY,TIMESLICE,YEAR);
* Maximum fraction of time a technology can run in a given timeslice
* Units: Fraction
* Data Source: ATX Hourly Wind Generation 2015 spreadsheet
*              NREL SAM simulations matched to ATX 2013 Solar Generation Report
CapacityFactor(REGION,TECHNOLOGY,TIMESLICE,YEAR) = 1;

CapacityFactor(REGION,"WINDPP","S1",YEAR)=0.421940048920701;
CapacityFactor(REGION,"WINDPP","S10",YEAR)=0.240762417108401;
CapacityFactor(REGION,"WINDPP","S11",YEAR)=0.23795846183021;
CapacityFactor(REGION,"WINDPP","S12",YEAR)=0.207409916334389;
CapacityFactor(REGION,"WINDPP","S13",YEAR)=0.184513837363673;
CapacityFactor(REGION,"WINDPP","S14",YEAR)=0.183265951521965;
CapacityFactor(REGION,"WINDPP","S15",YEAR)=0.194233165753076;
CapacityFactor(REGION,"WINDPP","S16",YEAR)=0.209487686497363;
CapacityFactor(REGION,"WINDPP","S17",YEAR)=0.225019042248393;
CapacityFactor(REGION,"WINDPP","S18",YEAR)=0.242181192881873;
CapacityFactor(REGION,"WINDPP","S19",YEAR)=0.265254376184866;
CapacityFactor(REGION,"WINDPP","S2",YEAR)=0.424557542256419;
CapacityFactor(REGION,"WINDPP","S20",YEAR)=0.284401787588128;
CapacityFactor(REGION,"WINDPP","S21",YEAR)=0.291272455481603;
CapacityFactor(REGION,"WINDPP","S22",YEAR)=0.318443145339716;
CapacityFactor(REGION,"WINDPP","S23",YEAR)=0.375286788603648;
CapacityFactor(REGION,"WINDPP","S24",YEAR)=0.409475914126758;
CapacityFactor(REGION,"WINDPP","S3",YEAR)=0.411907681803507;
CapacityFactor(REGION,"WINDPP","S4",YEAR)=0.392025289767139;
CapacityFactor(REGION,"WINDPP","S5",YEAR)=0.370254310037974;
CapacityFactor(REGION,"WINDPP","S6",YEAR)=0.347132345237156;
CapacityFactor(REGION,"WINDPP","S7",YEAR)=0.321084964455319;
CapacityFactor(REGION,"WINDPP","S8",YEAR)=0.300496443928252;
CapacityFactor(REGION,"WINDPP","S9",YEAR)=0.258165782883365;
CapacityFactor(REGION,"WINDPP","SF1",YEAR)=0.397222030991548;
CapacityFactor(REGION,"WINDPP","SF10",YEAR)=0.277878534633585;
CapacityFactor(REGION,"WINDPP","SF11",YEAR)=0.27702908339997;
CapacityFactor(REGION,"WINDPP","SF12",YEAR)=0.274354489009195;
CapacityFactor(REGION,"WINDPP","SF13",YEAR)=0.267240525006084;
CapacityFactor(REGION,"WINDPP","SF14",YEAR)=0.262093952733291;
CapacityFactor(REGION,"WINDPP","SF15",YEAR)=0.263622380469561;
CapacityFactor(REGION,"WINDPP","SF16",YEAR)=0.265843770928248;
CapacityFactor(REGION,"WINDPP","SF17",YEAR)=0.272253398672232;
CapacityFactor(REGION,"WINDPP","SF18",YEAR)=0.278928628380842;
CapacityFactor(REGION,"WINDPP","SF19",YEAR)=0.287940153731159;
CapacityFactor(REGION,"WINDPP","SF2",YEAR)=0.39413669938338;
CapacityFactor(REGION,"WINDPP","SF20",YEAR)=0.294715060788283;
CapacityFactor(REGION,"WINDPP","SF21",YEAR)=0.307134465649365;
CapacityFactor(REGION,"WINDPP","SF22",YEAR)=0.341478844882979;
CapacityFactor(REGION,"WINDPP","SF23",YEAR)=0.37123526864833;
CapacityFactor(REGION,"WINDPP","SF24",YEAR)=0.388819601633356;
CapacityFactor(REGION,"WINDPP","SF3",YEAR)=0.38888819158734;
CapacityFactor(REGION,"WINDPP","SF4",YEAR)=0.3779471545372;
CapacityFactor(REGION,"WINDPP","SF5",YEAR)=0.362450055666877;
CapacityFactor(REGION,"WINDPP","SF6",YEAR)=0.347544736971119;
CapacityFactor(REGION,"WINDPP","SF7",YEAR)=0.332665287651547;
CapacityFactor(REGION,"WINDPP","SF8",YEAR)=0.324702411513672;
CapacityFactor(REGION,"WINDPP","SF9",YEAR)=0.309536726587553;
CapacityFactor(REGION,"WINDPP","W1",YEAR)=0.359922700450525;
CapacityFactor(REGION,"WINDPP","W10",YEAR)=0.314500291703212;
CapacityFactor(REGION,"WINDPP","W11",YEAR)=0.289623316822789;
CapacityFactor(REGION,"WINDPP","W12",YEAR)=0.291545720341076;
CapacityFactor(REGION,"WINDPP","W13",YEAR)=0.296646850674743;
CapacityFactor(REGION,"WINDPP","W14",YEAR)=0.301585967006647;
CapacityFactor(REGION,"WINDPP","W15",YEAR)=0.305905135632711;
CapacityFactor(REGION,"WINDPP","W16",YEAR)=0.303432397881838;
CapacityFactor(REGION,"WINDPP","W17",YEAR)=0.294891210072673;
CapacityFactor(REGION,"WINDPP","W18",YEAR)=0.280494110604493;
CapacityFactor(REGION,"WINDPP","W19",YEAR)=0.278388924144773;
CapacityFactor(REGION,"WINDPP","W2",YEAR)=0.358889254568368;
CapacityFactor(REGION,"WINDPP","W20",YEAR)=0.313043955871751;
CapacityFactor(REGION,"WINDPP","W21",YEAR)=0.342120670396165;
CapacityFactor(REGION,"WINDPP","W22",YEAR)=0.361098997834631;
CapacityFactor(REGION,"WINDPP","W23",YEAR)=0.367531491975539;
CapacityFactor(REGION,"WINDPP","W24",YEAR)=0.36638061648956;
CapacityFactor(REGION,"WINDPP","W3",YEAR)=0.354439756816395;
CapacityFactor(REGION,"WINDPP","W4",YEAR)=0.349760263663603;
CapacityFactor(REGION,"WINDPP","W5",YEAR)=0.346309391267891;
CapacityFactor(REGION,"WINDPP","W6",YEAR)=0.349830476412177;
CapacityFactor(REGION,"WINDPP","W7",YEAR)=0.345248893681992;
CapacityFactor(REGION,"WINDPP","W8",YEAR)=0.344346613916764;
CapacityFactor(REGION,"WINDPP","W9",YEAR)=0.341577660122632;

CapacityFactor(REGION,"SOLPP","W2",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W14",YEAR)=0.542259080394186;
CapacityFactor(REGION,"SOLPP","W3",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W15",YEAR)=0.471194006922349;
CapacityFactor(REGION,"SOLPP","W4",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W16",YEAR)=0.367070511819184;
CapacityFactor(REGION,"SOLPP","W5",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W17",YEAR)=0.209152608710027;
CapacityFactor(REGION,"SOLPP","W6",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W18",YEAR)=0.0520924541420947;
CapacityFactor(REGION,"SOLPP","W7",YEAR)=0.00000482412367388025;
CapacityFactor(REGION,"SOLPP","W19",YEAR)=0.00193548183921163;
CapacityFactor(REGION,"SOLPP","W8",YEAR)=0.0185474943854163;
CapacityFactor(REGION,"SOLPP","W20",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W9",YEAR)=0.143948494448176;
CapacityFactor(REGION,"SOLPP","W21",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W10",YEAR)=0.311712047536093;
CapacityFactor(REGION,"SOLPP","W22",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W11",YEAR)=0.442146306966387;
CapacityFactor(REGION,"SOLPP","W23",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W12",YEAR)=0.514405990213522;
CapacityFactor(REGION,"SOLPP","W24",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W1",YEAR)=0;
CapacityFactor(REGION,"SOLPP","W13",YEAR)=0.558268681561589;

CapacityFactor(REGION,"SOLPP","SF2",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF14",YEAR)=0.612184980204616;
CapacityFactor(REGION,"SOLPP","SF3",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF15",YEAR)=0.538173478213686;
CapacityFactor(REGION,"SOLPP","SF4",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF16",YEAR)=0.430925103093794;
CapacityFactor(REGION,"SOLPP","SF5",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF17",YEAR)=0.272234558705263;
CapacityFactor(REGION,"SOLPP","SF6",YEAR)=0.000524357601834511;
CapacityFactor(REGION,"SOLPP","SF18",YEAR)=0.104865284486111;
CapacityFactor(REGION,"SOLPP","SF7",YEAR)=0.0142406482944532;
CapacityFactor(REGION,"SOLPP","SF19",YEAR)=0.0164671456511778;
CapacityFactor(REGION,"SOLPP","SF8",YEAR)=0.10345387615395;
CapacityFactor(REGION,"SOLPP","SF20",YEAR)=0.000721430210291512;
CapacityFactor(REGION,"SOLPP","SF9",YEAR)=0.265069480242676;
CapacityFactor(REGION,"SOLPP","SF21",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF10",YEAR)=0.425085398001233;
CapacityFactor(REGION,"SOLPP","SF22",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF11",YEAR)=0.543888030326368;
CapacityFactor(REGION,"SOLPP","SF23",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF12",YEAR)=0.604910228105802;
CapacityFactor(REGION,"SOLPP","SF24",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF1",YEAR)=0;
CapacityFactor(REGION,"SOLPP","SF13",YEAR)=0.639765655679236;

CapacityFactor(REGION,"SOLPP","S2",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S14",YEAR)=0.639749862637586;
CapacityFactor(REGION,"SOLPP","S3",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S15",YEAR)=0.579001447105316;
CapacityFactor(REGION,"SOLPP","S4",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S16",YEAR)=0.486444494028708;
CapacityFactor(REGION,"SOLPP","S5",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S17",YEAR)=0.349830810397828;
CapacityFactor(REGION,"SOLPP","S6",YEAR)=0.00253068501952125;
CapacityFactor(REGION,"SOLPP","S18",YEAR)=0.184746350622116;
CapacityFactor(REGION,"SOLPP","S7",YEAR)=0.0340274453937761;
CapacityFactor(REGION,"SOLPP","S19",YEAR)=0.0501918425538674;
CapacityFactor(REGION,"SOLPP","S8",YEAR)=0.150056484958515;
CapacityFactor(REGION,"SOLPP","S20",YEAR)=0.00591525424035196;
CapacityFactor(REGION,"SOLPP","S9",YEAR)=0.310864209781154;
CapacityFactor(REGION,"SOLPP","S21",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S10",YEAR)=0.461123245067174;
CapacityFactor(REGION,"SOLPP","S22",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S11",YEAR)=0.571446871353298;
CapacityFactor(REGION,"SOLPP","S23",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S12",YEAR)=0.627302840809919;
CapacityFactor(REGION,"SOLPP","S24",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S1",YEAR)=0;
CapacityFactor(REGION,"SOLPP","S13",YEAR)=0.660176056431684;


CapacityFactor(r,"EV_CHARGE",l,y) = 1-CapacityFactor(r,"EV",l,y)*SpecifiedDemandProfile(r,"VMT",l,y)/0.041161338;
*Placeholder
CapacityFactor(r,"V2G",LowV2G,y) = 0.333 * (1-CapacityFactor(r,"EV",LowV2G,y)*SpecifiedDemandProfile(r,"VMT",LowV2G,y)/0.041161338);
CapacityFactor(r,"V2G",HighV2G,y) = 0.667 * (1-CapacityFactor(r,"EV",HighV2G,y)*SpecifiedDemandProfile(r,"VMT",HighV2G,y)/0.041161338);

CapacityFactor(r,"EV_DISCHARGE",l,y) = 1;
CapacityFactor(r,PrivTrans,l,y) = 0.1;

CapacityFactor(r,"EV_CHARGE_F",l,y) = 1-CapacityFactor(r,"EV_F",l,y)*SpecifiedDemandProfile(r,"FMT",l,y)/0.041161338;
*Placeholder
CapacityFactor(r,"V2G_F",LowV2G,y) = 0.333 * (1-CapacityFactor(r,"EV_F",LowV2G,y)*SpecifiedDemandProfile(r,"FMT",LowV2G,y)/0.041161338);
CapacityFactor(r,"V2G_F",HighV2G,y) = 0.667 * (1-CapacityFactor(r,"EV_F",HighV2G,y)*SpecifiedDemandProfile(r,"FMT",HighV2G,y)/0.041161338);

CapacityFactor(r,"EV_DISCHARGE_F",l,y) = 1;
CapacityFactor(r,Fleet,l,y) = 0.95;

parameter AvailabilityFactor(REGION,TECHNOLOGY,YEAR);
* Maximum fraction of time a technology can run in a year (omits planned outages)
* Units: Fraction
AvailabilityFactor(REGION,TECHNOLOGY,YEAR) = 1;

parameter OperationalLife(REGION,TECHNOLOGY);
* Lifetime of the technology
* Units: Years
* Data Source: AEO assumes a 30-year cost recovery period for all technologies
*Note shortened operational life of Fleet due to higher use
*Also lengethed operational life of public vehicles due to their 12 year life cycle

OperationalLife(r,"COALPP") = 30;
OperationalLife(r,"CCPP") = 30;
OperationalLife(r,"CTPP") = 30;
OperationalLife(r,"NUCPP") = 30;
OperationalLife(r,"HYDROPP") = 30;
OperationalLife(r,"WINDPP") = 30;
OperationalLife(r,"SOLPP") = 30;
OperationalLife(r,"BIOPP") = 30;
OperationalLife(r,"CCCCSPP") = 30;
OperationalLife(r,"IGCCCCSPP") = 30;
OperationalLife(r,"H2FUELCELL") = 30;
OperationalLife(r,"BATTERY") = 10;
OperationalLife(r,"EV_CHARGE") = 10;
OperationalLife(r,"V2G") = 10;
OperationalLife(r,"EV_DISCHARGE") = 10;
OperationalLife(r,"EV_CHARGE_F") = 8;
OperationalLife(r,"V2G_F") = 8;
OperationalLife(r,"EV_DISCHARGE_F") = 8;
OperationalLife(r,"BUYCOAL") = 1;
OperationalLife(r,"BUYURN") = 1;
OperationalLife(r,"BUYBIO") = 1;
OperationalLife(r,"BUYGAS") = 1;
OperationalLife(r,"BUYPET") = 1;
OperationalLife(r,"BUYDSL") = 1;
OperationalLife(r,"BUYBIO_DSL") = 1;
OperationalLife(r,"SOLPOT") = 1;
OperationalLife(r,"WINDPOT") = 1;
OperationalLife(r,"HYDROPOT") = 1;
OperationalLife(r,"ICE_PET") = 10;
OperationalLife(r,"ICE_DSL") = 10;
OperationalLife(r,"PHEV") = 10;
OperationalLife(r,"HYBRID") = 10;
OperationalLife(r,"H2V") = 10;
OperationalLife(r,"EV") = 10;
OperationalLife(r,"ICE_PET_F") = 5;
OperationalLife(r,"ICE_DSL_F") = 5;
OperationalLife(r,"PHEV_F") = 5;
OperationalLife(r,"HYBRID_F") = 5;
OperationalLife(r,"H2V_F") = 5;
OperationalLife(r,"EV_F") = 5;
OperationalLife(r,"ICE_PET_PUB") = 12;
OperationalLife(r,"ICE_DSL_PUB") = 12;
OperationalLife(r,"CNG_PUB") = 12;
OperationalLife(r,"EV_PUB") = 12;
OperationalLife(r,"PHEV_PUB") = 12;
OperationalLife(r,"HYBRID_PUB") = 12;
OperationalLife(r,"BIO_DSL_PUB") = 12;
OperationalLife(r,"ELCTROL") = 30;
OperationalLife(r,"GASREF") = 30;
OperationalLife(r,"BIOGAS") = 30;
OperationalLife(r,"COALGAS") = 30;

table ResidualCapacity(REGION,TECHNOLOGY,YEAR)
* Capacity built prior to the model timeframe that is still operating in each period
* Units: GW, Thousands of Units (vehicles)
* Data Source: EIA Power Generator Database restricted to ATX area
                   2015
ATX.COALPP         0.602
ATX.CCPP           0.57
ATX.CTPP           0.9316
ATX.NUCPP          0.436
ATX.HYDROPP        0
ATX.WINDPP         0.85
ATX.SOLPP          0.52
ATX.BIOPP          0.013
ATX.CCCCSPP        0
ATX.IGCCCCSPP      0
ATX.H2FUELCELL     0
ATX.BATTERY        0
ATX.EV_CHARGE      0.003
ATX.V2G            0
ATX.EV_DISCHARGE   1000
ATX.EV_CHARGE_F    0.003
ATX.V2G_F          0
ATX.EV_DISCHARGE_F 1000
ATX.BUYCOAL        0
ATX.BUYURN         0
ATX.BUYBIO         0
ATX.BUYGAS         0
ATX.BUYPET         0
ATX.BUYDSL         0
ATX.BUYBIO_DSL     0
ATX.SOLPOT         0
ATX.WINDPOT        0
ATX.HYDROPOT       0
ATX.ICE_PET        906
ATX.ICE_DSL        68
ATX.PHEV           0.5
ATX.HYBRID         9
ATX.H2V            0
ATX.EV             0.5
ATX.ICE_PET_F      0.9
ATX.ICE_DSL_F      0
ATX.PHEV_F         0.04
ATX.HYBRID_F       0.05
ATX.H2V_F          0
ATX.EV_F           0.01
ATX.ICE_PET_PUB    0
ATX.ICE_DSL_PUB    0.364
ATX.CNG_PUB        0
ATX.EV_PUB         0
ATX.PHEV_PUB       0
ATX.HYBRID_PUB     0
ATX.BIO_DSL_PUB    0
ATX.ELCTROL        0
ATX.GASREF         0
ATX.BIOGAS         0
ATX.COALGAS        0;


* Retire residual capacity linearly over operational life
ResidualCapacity(r,PP,"2015") = 1.22*ResidualCapacity(r,PP,"2015");
ResidualCapacity(r,PrivTrans,"2015") = 1*ResidualCapacity(r,PrivTrans,"2015");
*This value is necessary due to feasiblity might cause slight errors
ResidualCapacity(r,Fleet,"2015") = 200*ResidualCapacity(r,Fleet,"2015");
*ResidualCapacity(r,Fleet,"2015") = 0;

ResidualCapacity(r,PubTrans,"2015") = 1.69*ResidualCapacity(r,PubTrans,"2015");
ResidualCapacity(r,t,y) = max(0,ResidualCapacity(r,t,"2015") - ResidualCapacity(r,t,"2015")/OperationalLife(r,t)*(ord(y)-1));

table InputActivityRatio(REGION,TECHNOLOGY,FUEL,MODE_OF_OPERATION,YEAR)
* Interpreted as the inverse of conversion efficiency for power generation
* Units: Ratio, ICE, HYBRID: Millions of Gallons/Millions of Miles, EV,H2: PJ/Millions of Miles
* Data Source: AEO Assumptions Table 8.2

                                                 2015          2016          2017          2018          2019          2020          2021          2022          2023          2024          2025          2026          2027          2028          2029          2030          2031          2032          2033          2034          2035          2036          2037          2038          2039          2040          2041          2042          2043          2044          2045          2046          2047          2048          2049          2050
ATX.COALPP.COAL.1                                2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790        2.5790
ATX.CCPP.GAS.1                                   1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850        1.8850
ATX.CTPP.GAS.1                                   2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580        2.8580
ATX.NUCPP.URN.1                                  3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710        3.0710
ATX.HYDROPP.HYDRO.1                              2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890
ATX.WINDPP.WIND.1                                2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890
ATX.SOLPP.SOL.1                                  2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890        2.7890
ATX.BIOPP.BIO.1                                  3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570        3.9570
ATX.CCCCSPP.GAS.1                                2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050        2.2050
ATX.IGCCCCSPP.COAL.1                             3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360        3.1360
ATX.H2FUELCELL.H2.1                              16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635        16.635
ATX.BATTERY.ELC.2                                1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111
ATX.EV_CHARGE.ELC.1                              1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111
ATX.V2G.ELC.1                                    1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111
ATX.EV_DISCHARGE.ELC.1                           1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000
ATX.EV_CHARGE_F.ELC.1                            1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111
ATX.V2G_F.ELC.1                                  1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111        1.1111
ATX.EV_DISCHARGE_F.ELC.1                         1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000        1.0000;
*ATX.ICE_PET.PET.1                                0.0455        0.0448        0.0441        0.0434        0.0427        0.0420        0.0414        0.0407        0.0401        0.0395        0.0389        0.0383        0.0377        0.0371        0.0365        0.0360        0.0354        0.0349        0.0343        0.0338        0.0333        0.0327        0.0322        0.0317        0.0312        0.0308        0.0303        0.0298        0.0294        0.0289        0.0285        0.0280        0.0276        0.0272        0.0267        0.0263
*ATX.ICE_DSL.DSL.1                                0.0286        0.0282        0.0277        0.0273        0.0269        0.0265        0.0261        0.0257        0.0253        0.0249        0.0245        0.0242        0.0238        0.0234        0.0231        0.0227        0.0224        0.0220        0.0217        0.0214        0.0210        0.0207        0.0204        0.0201        0.0198        0.0195        0.0192        0.0189        0.0186        0.0183        0.0181        0.0178        0.0175        0.0172        0.0170        0.0167
*ATX.PHEV.ELC.1                                   0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009
*ATX.PHEV.PET.1                                   0.0250        0.0246        0.0242        0.0239        0.0235        0.0232        0.0228        0.0225        0.0221        0.0218        0.0214        0.0211        0.0208        0.0205        0.0202        0.0199        0.0196        0.0193        0.0190        0.0187        0.0184        0.0181        0.0178        0.0176        0.0173        0.0170        0.0168        0.0165        0.0163        0.0160        0.0158        0.0155        0.0153        0.0151        0.0148        0.0146
*ATX.HYBRID.PET.1                                 0.0250        0.0246        0.0242        0.0239        0.0235        0.0232        0.0228        0.0225        0.0221        0.0218        0.0214        0.0211        0.0208        0.0205        0.0202        0.0199        0.0196        0.0193        0.0190        0.0187        0.0184        0.0181        0.0178        0.0176        0.0173        0.0170        0.0168        0.0165        0.0163        0.0160        0.0158        0.0155        0.0153        0.0151        0.0148        0.0146
*ATX.H2V.H2.1                                     0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149
*ATX.EV.ELC.1                                     0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009
*ATX.ICE_PET_F.PET.1                              0.0455        0.0448        0.0441        0.0434        0.0427        0.0420        0.0414        0.0407        0.0401        0.0395        0.0389        0.0383        0.0377        0.0371        0.0365        0.0360        0.0354        0.0349        0.0343        0.0338        0.0333        0.0327        0.0322        0.0317        0.0312        0.0308        0.0303        0.0298        0.0294        0.0289        0.0285        0.0280        0.0276        0.0272        0.0267        0.0263
*ATX.ICE_DSL_F.DSL.1                              0.0286        0.0282        0.0277        0.0273        0.0269        0.0265        0.0261        0.0257        0.0253        0.0249        0.0245        0.0242        0.0238        0.0234        0.0231        0.0227        0.0224        0.0220        0.0217        0.0214        0.0210        0.0207        0.0204        0.0201        0.0198        0.0195        0.0192        0.0189        0.0186        0.0183        0.0181        0.0178        0.0175        0.0172        0.0170        0.0167
*ATX.PHEV_F.ELC.1                                 0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009
*ATX.PHEV_F.PET.1                                 0.0250        0.0246        0.0242        0.0239        0.0235        0.0232        0.0228        0.0225        0.0221        0.0218        0.0214        0.0211        0.0208        0.0205        0.0202        0.0199        0.0196        0.0193        0.0190        0.0187        0.0184        0.0181        0.0178        0.0176        0.0173        0.0170        0.0168        0.0165        0.0163        0.0160        0.0158        0.0155        0.0153        0.0151        0.0148        0.0146
*ATX.HYBRID_F.PET.1                               0.0250        0.0246        0.0242        0.0239        0.0235        0.0232        0.0228        0.0225        0.0221        0.0218        0.0214        0.0211        0.0208        0.0205        0.0202        0.0199        0.0196        0.0193        0.0190        0.0187        0.0184        0.0181        0.0178        0.0176        0.0173        0.0170        0.0168        0.0165        0.0163        0.0160        0.0158        0.0155        0.0153        0.0151        0.0148        0.0146
*ATX.H2V_F.H2.1                                   0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149        0.0149;
*ATX.EV_F.ELC.1                                   0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009
*ATX.ICE_PET_PUB.PET.1                            0.0022        0.0022        0.0021        0.0021        0.0021        0.0020        0.0020        0.0020        0.0019        0.0019        0.0019        0.0019        0.0018        0.0018        0.0018        0.0017        0.0017        0.0017        0.0017        0.0016        0.0016        0.0016        0.0016        0.0015        0.0015        0.0015        0.0015        0.0015        0.0014        0.0014        0.0014        0.0014        0.0013        0.0013        0.0013        0.0013
*ATX.ICE_DSL_PUB.DSL.1                            0.0019        0.0019        0.0018        0.0018        0.0018        0.0018        0.0017        0.0017        0.0017        0.0017        0.0016        0.0016        0.0016        0.0016        0.0015        0.0015        0.0015        0.0015        0.0014        0.0014        0.0014        0.0014        0.0014        0.0013        0.0013        0.0013        0.0013        0.0013        0.0012        0.0012        0.0012        0.0012        0.0012        0.0011        0.0011        0.0011
*ATX.CNG_PUB.GAS.1                                0.0019        0.0019        0.0018        0.0018        0.0018        0.0018        0.0017        0.0017        0.0017        0.0017        0.0016        0.0016        0.0016        0.0016        0.0015        0.0015        0.0015        0.0015        0.0014        0.0014        0.0014        0.0014        0.0014        0.0013        0.0013        0.0013        0.0013        0.0013        0.0012        0.0012        0.0012        0.0012        0.0012        0.0011        0.0011        0.0011
*ATX.EV_PUB.ELC.1                                 0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0010        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009        0.0009
*ATX.PHEV_PUB.ELC.1                               0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001        0.0001
*ATX.PHEV_PUB.PET.1                               0.0017        0.0017        0.0016        0.0016        0.0016        0.0016        0.0016        0.0015        0.0015        0.0015        0.0015        0.0014        0.0014        0.0014        0.0014        0.0014        0.0013        0.0013        0.0013        0.0013        0.0013        0.0012        0.0012        0.0012        0.0012        0.0012        0.0011        0.0011        0.0011        0.0011        0.0011        0.0011        0.0010        0.0010        0.0010        0.0010
*ATX.HYBRID_PUB.PET.1                             0.0017        0.0017        0.0016        0.0016        0.0016        0.0016        0.0016        0.0015        0.0015        0.0015        0.0015        0.0014        0.0014        0.0014        0.0014        0.0014        0.0013        0.0013        0.0013        0.0013        0.0013        0.0012        0.0012        0.0012        0.0012        0.0012        0.0011        0.0011        0.0011        0.0011        0.0011        0.0011        0.0010        0.0010        0.0010        0.0010;
*ATX.BIO_DSL_PUB.BIO_DSL.1                        0.0020        0.0020        0.0020        0.0020        0.0019        0.0019        0.0019        0.0019        0.0019        0.0019        0.0019        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018        0.0018;


InputActivityRatio(REGION,"ELCTROL","ELC","1",YEAR) =   0.385353787;
InputActivityRatio(REGION,"GASREF","GAS","1",YEAR) =   0.155135976;
InputActivityRatio(REGION,"BIOGAS","BIO","1",YEAR) =   0.282895015;
InputActivityRatio(REGION,"COALGAS","COAL","1",YEAR) =    0.215466634;

*This allows the efficiency of PET and DSL powered vehicles to hit the predicted MPG values given by the EIA

scalar CarEI /0.9852/;
*This allows EVs to take into account efficiency upgrades over time to the electricity distrubtion system
scalar EVEI /0.995/;
*Autonomous Efficiency Upgrades over regular driving
scalar AE /.9/;



InputActivityRatio(REGION,"ICE_PET","PET","1","2015") =    0.0455;
InputActivityRatio(REGION,"ICE_PET","PET","1",YEAR) = InputActivityRatio(REGION,"ICE_PET","PET","1","2015") * CarEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"ICE_DSL","DSL","1","2015") =    0.0286;
InputActivityRatio(REGION,"ICE_DSL","DSL","1",YEAR) = InputActivityRatio(REGION,"ICE_DSL","DSL","1","2015") * CarEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"EV","ELC","1","2015") =    0.001;
InputActivityRatio(REGION,"EV","ELC","1",YEAR) = InputActivityRatio(REGION,"EV","ELC","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"H2V","H2","1","2015") =    0.0149;
InputActivityRatio(REGION,"H2V","H2","1",YEAR) = InputActivityRatio(REGION,"H2V","H2","1","2015") * CarEI **(ord(YEAR)-1);


InputActivityRatio(REGION,"PHEV","ELC","1","2015") =    0.001;
InputActivityRatio(REGION,"PHEV","ELC","1",YEAR) = InputActivityRatio(REGION,"PHEV","ELC","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"PHEV","PET","1","2015") =    0.025;
InputActivityRatio(REGION,"PHEV","PET","1",YEAR) = InputActivityRatio(REGION,"PHEV","PET","1","2015") * CarEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"HYBRID","PET","1","2015") =    0.028;
InputActivityRatio(REGION,"HYBRID","PET","1",YEAR) = InputActivityRatio(REGION,"HYBRID","PET","1","2015") * CarEI **(ord(YEAR)-1);

*Fleet Efficiencies

InputActivityRatio(REGION,"ICE_PET_F","PET","1","2015") =    0.0455;
InputActivityRatio(REGION,"ICE_PET_F","PET","1",YEAR) = InputActivityRatio(REGION,"ICE_PET_F","PET","1","2015") * AE * CarEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"ICE_DSL_F","DSL","1","2015") =    0.0286;
InputActivityRatio(REGION,"ICE_DSL_F","DSL","1",YEAR) = InputActivityRatio(REGION,"ICE_DSL_F","DSL","1","2015") * AE * CarEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"EV_F","ELC","1","2015") =    0.001;
InputActivityRatio(REGION,"EV_F","ELC","1",YEAR) = InputActivityRatio(REGION,"EV_F","ELC","1","2015") * AE * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"H2V_F","H2","1","2015") =    0.0149;
InputActivityRatio(REGION,"H2V_F","H2","1",YEAR) = InputActivityRatio(REGION,"H2V_F","H2","1","2015") * AE * EVEI **(ord(YEAR)-1);


InputActivityRatio(REGION,"PHEV_F","ELC","1","2015") =    0.001;
InputActivityRatio(REGION,"PHEV_F","ELC","1",YEAR) = InputActivityRatio(REGION,"PHEV_F","ELC","1","2015") * AE * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"PHEV_F","PET","1","2015") =    0.025;
InputActivityRatio(REGION,"PHEV_F","PET","1",YEAR) = InputActivityRatio(REGION,"PHEV_F","PET","1","2015") *AE * CarEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"HYBRID_F","PET","1","2015") =    0.028;
InputActivityRatio(REGION,"HYBRID_F","PET","1",YEAR) = InputActivityRatio(REGION,"HYBRID_F","PET","1","2015") * AE * CarEI **(ord(YEAR)-1);

*Public Efficiencies

InputActivityRatio(REGION,"ICE_PET_PUB","PET","1","2015") =    0.40;
InputActivityRatio(REGION,"ICE_PET_PUB","PET","1",YEAR) = InputActivityRatio(REGION,"ICE_PET_PUB","PET","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"ICE_DSL_PUB","DSL","1","2015") =    0.333;
InputActivityRatio(REGION,"ICE_DSL_PUB","DSL","1",YEAR) = InputActivityRatio(REGION,"ICE_DSL_PUB","DSL","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"EV_PUB","ELC","1","2015") =    0.0572;
InputActivityRatio(REGION,"EV_PUB","ELC","1",YEAR) = InputActivityRatio(REGION,"EV_PUB","ELC","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"CNG_PUB","GAS","1","2015") =    0.2475;
InputActivityRatio(REGION,"CNG_PUB","GAS","1",YEAR) = InputActivityRatio(REGION,"CNG_PUB","GAS","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"PHEV_PUB","ELC","1","2015") =    0.0572;
InputActivityRatio(REGION,"PHEV_PUB","ELC","1",YEAR) = InputActivityRatio(REGION,"PHEV_PUB","ELC","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"PHEV_PUB","PET","1","2015") =    0.3;
InputActivityRatio(REGION,"PHEV_PUB","PET","1",YEAR) = InputActivityRatio(REGION,"PHEV_PUB","PET","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"HYBRID_PUB","PET","1","2015") =    0.31;
InputActivityRatio(REGION,"HYBRID_PUB","PET","1",YEAR) = InputActivityRatio(REGION,"HYBRID_PUB","PET","1","2015") * EVEI **(ord(YEAR)-1);

InputActivityRatio(REGION,"BIO_DSL_PUB","BIO_DSL","1","2015") =    0.34;
InputActivityRatio(REGION,"BIO_DSL_PUB","BIO_DSL","1",YEAR) = InputActivityRatio(REGION,"BIO_DSL_PUB","BIO_DSL","1","2015") * EVEI **(ord(YEAR)-1);


*ATX.GASREF.GAS.1                                 0.155135976
*ATX.BIOGAS.BIO.1                                 0.282895015
*ATX.COALGAS.COAL.1                               0.215466634;




* Project forward
*InputActivityRatio(r,t,f,m,y) = InputActivityRatio(r,t,f,m,"2015");


table OutputActivityRatio(REGION,TECHNOLOGY,FUEL,MODE_OF_OPERATION,YEAR)
* Indicates which fuel each technology produces
* Units: 1=yes, 0=no
* Vehicle-to-Grid: Discharging in mode 1, Driving in mode 3.
                               2015
ATX.COALPP.ELC.1               1
ATX.CCPP.ELC.1                 1
ATX.CTPP.ELC.1                 1
ATX.NUCPP.ELC.1                1
ATX.HYDROPP.ELC.1              1
ATX.WINDPP.ELC.1               1
ATX.SOLPP.ELC.1                1
ATX.BIOPP.ELC.1                1
ATX.CCCCSPP.ELC.1              1
ATX.IGCCCCSPP.ELC.1            1
ATX.H2FUELCELL.ELC.1           1
ATX.BATTERY.ELC.1              1
ATX.EV_CHARGE.ELC.1            1
ATX.V2G.ELC.1                  1
ATX.EV_DISCHARGE.ELC.1         1
ATX.EV_CHARGE_F.ELC.1          1
ATX.V2G_F.ELC.1                1
ATX.EV_DISCHARGE_F.ELC.1       1
ATX.BUYCOAL.COAL.1             1
ATX.BUYURN.URN.1               1
ATX.BUYBIO.BIO.1               1
ATX.BUYGAS.GAS.1               1
ATX.BUYPET.PET.1               1
ATX.BUYDSL.DSL.1               1
ATX.BUYBIO_DSL.BIO_DSL.1       1
ATX.SOLPOT.SOL.1               1
ATX.WINDPOT.WIND.1             1
ATX.HYDROPOT.HYDRO.1           1
ATX.ICE_PET.VMT.1              1
ATX.ICE_DSL.VMT.1              1
ATX.PHEV.VMT.1                 1
ATX.HYBRID.VMT.1               1
ATX.H2V.VMT.1                  1
ATX.EV.VMT.1                   1
ATX.ICE_PET_F.FMT.1            1
ATX.ICE_DSL_F.FMT.1            1
ATX.PHEV_F.FMT.1               1
ATX.HYBRID_F.FMT.1             1
ATX.H2V_F.FMT.1                1
ATX.EV_F.FMT.1                 1
ATX.ICE_PET_PUB.PM.1           1
ATX.ICE_DSL_PUB.PM.1           1
ATX.EV_PUB.PM.1                1
ATX.PHEV_PUB.PM.1              1
ATX.HYBRID_PUB.PM.1            1
ATX.CNG_PUB.PM.1               1
ATX.BIO_DSL_PUB.PM.1           1
ATX.ELCTROL.H2.1               1
ATX.GASREF.H2.1                1
ATX.BIOGAS.H2.1                1
ATX.COALGAS.H2.1               1;

* Project forward
OutputActivityRatio(r,t,f,m,y) = OutputActivityRatio(r,t,f,m,"2015");

* ##### Technology Costs #####

table CapitalCost(REGION,TECHNOLOGY,YEAR)
* Capital costs
* Units: $/kW, Million$/Thousand Units (Vehicles)
* Data Source: NREL 2016 Annual Technology Baseline
                         2015            2016            2017            2018            2019            2020            2021            2022            2023            2024            2025            2026            2027            2028            2029            2030            2031            2032            2033            2034            2035            2036            2037            2038            2039            2040            2041            2042            2043            2044            2045            2046            2047            2048            2049            2050
ATX.COALPP               3559.411        3559.411        3527.195        3521.692        3513.332        3509.361        3504.500        3508.889        3500.413        3496.165        3499.986        3485.754        3469.517        3456.042        3448.081        3438.518        3428.361        3415.323        3404.445        3399.069        3389.959        3379.142        3366.720        3360.839        3353.715        3342.171        3332.432        3325.028        3317.846        3309.964        3301.119        3293.411        3284.579        3273.450        3265.691        3237.378
ATX.CCPP                 1010.284        1010.284        1003.702        1004.709        1004.907        1003.228        1001.323        1002.166        999.333         997.706         997.262         990.350         983.683         974.781         969.129         962.767         958.089         952.834         947.871         944.468         941.160         936.779         931.832         929.346         926.012         922.093         918.512         915.971         913.321         910.560         908.318         906.503         904.379         901.622         899.794         892.300
ATX.CTPP                 863.859         863.859         859.766         862.167         858.893         857.389         855.674         856.324         853.834         852.374         851.735         845.346         839.306         830.843         825.442         819.391         815.092         810.342         805.787         802.563         799.617         795.655         791.191         788.930         785.861         782.407         779.211         776.968         774.602         772.157         770.289         768.804         767.056         764.772         763.275         756.973
ATX.NUCPP                5514.824        5477.081        5406.262        5376.487        5342.306        5314.746        5293.103        5291.280        5263.831        5242.718        5233.631        5197.518        5158.468        5123.577        5096.874        5067.803        5037.864        5003.716        4972.760        4949.832        4921.453        4890.606        4857.459        4833.753        4808.236        4776.387        4747.133        4721.203        4695.575        4668.942        4640.945        4614.541        4586.555        4555.374        4528.887        4473.984
ATX.HYDROPP              4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377        4045.377
ATX.WINDPP               1607.789        1566.569        1562.972        1557.682        1550.730        1542.148        1540.115        1536.708        1531.952        1525.873        1518.497        1509.849        1499.955        1488.840        1476.531        1463.053        1470.501        1477.201        1483.166        1488.405        1492.930        1496.751        1499.879        1502.326        1504.101        1505.215        1505.680        1505.506        1504.705        1503.286        1501.260        1498.639        1495.434        1491.654        1487.311        1482.416
ATX.SOLPP                1988.360        1493.910        1203.622        1133.419        1093.303        1032.981        1020.614        1008.247        995.880         983.513         971.146         958.779         946.412         934.045         921.678         909.311         899.207         889.104         879.000         868.897         858.793         848.690         838.587         828.483         818.380         808.276         799.071         789.865         780.659         771.454         762.248         753.042         743.837         734.631         725.425         716.220
ATX.BIOPP                3736.935        3730.294        3701.010        3699.734        3695.467        3674.666        3659.271        3659.094        3645.484        3636.269        3635.424        3615.815        3594.145        3575.353        3562.269        3547.530        3532.182        3513.873        3497.795        3487.368        3473.104        3457.096        3439.452        3428.493        3416.257        3399.521        3384.626        3372.102        3359.798        3346.782        3332.788        3319.942        3305.960        3289.671        3276.769        3243.273
ATX.CCCCSPP              2108.717        2108.717        2090.581        2088.274        2084.275        2074.142        2063.467        2058.481        2045.918        2035.816        2027.433        2005.094        1983.769        1956.104        1936.029        1914.369        1897.249        1879.144        1861.425        1846.784        1833.091        1816.899        1799.539        1787.386        1773.235        1758.423        1744.144        1732.130        1719.778        1707.273        1696.329        1686.270        1675.632        1663.827        1653.414        1630.146
ATX.IGCCCCSPP            5447.600        5447.600        5402.093        5397.479        5388.495        5386.254        5368.398        5364.660        5341.213        5324.202        5319.427        5287.191        5251.951        5220.930        5198.248        5173.153        5147.168        5116.875        5089.839        5071.022        5046.623        5019.693        4990.393        4970.792        4949.336        4921.361        4896.055        4874.177        4852.615        4830.020        4806.015        4783.662        4759.670        4732.359        4709.341        4652.251
ATX.H2FUELCELL           1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000        1000.000
ATX.BATTERY              494             434.72          382.5536        336.647168      296.2495078     260.6995669     229.4156189     201.8857446     177.6594553     156.3403206     137.5794821     121.0699443     106.541551      93.75656486     82.50577708     72.60508383     63.89247377     56.22537692     49.47833169     43.54093188     38.31602006     33.71809765     29.67192593     26.11129482     22.97793944     20.22058671     17.7941163      15.65882235     13.77976367     12.12619203     10.67104898     9.390523105     8.263660332     7.272021092     6.399378561     5.631453134
ATX.EV                   38.8860         37.8563         36.8539         35.8781         34.9281         34.0032         33.1028         32.2263         31.3730         30.5423         29.7335         28.9462         28.1798         27.4336         26.7072         26.0000         25.9818         25.9636         25.9454         25.9273         25.9091         25.8910         25.8729         25.8548         25.8367         25.8186         25.8005         25.7824         25.7644         25.7464         25.7283         25.7103         25.6923         25.6743         25.6564         25.6384
ATX.EV_F                 38.8860         37.8563         36.8539         35.8781         34.9281         34.0032         33.1028         32.2263         31.3730         30.5423         29.7335         28.9462         28.1798         27.4336         26.7072         26.0000         25.9818         25.9636         25.9454         25.9273         25.9091         25.8910         25.8729         25.8548         25.8367         25.8186         25.8005         25.7824         25.7644         25.7464         25.7283         25.7103         25.6923         25.6743         25.6564         25.6384;


CapitalCost(r,"ELCTROL",y) = 4.101;
CapitalCost(r,"GASREF",y) = 1.820;
CapitalCost(r,"BIOGAS",y) = 2.767;
CapitalCost(r,"COALGAS",y) = 5.401;

CapitalCost(r,"ICE_PET",y) = 27;
CapitalCost(r,"ICE_DSL",y) = 32;

CapitalCost(r,"PHEV",y) = 37.5;
CapitalCost(r,"HYBRID",y) = 32;
CapitalCost(r,"H2V",y) = 57.5;

parameter AutoExtraCost(YEAR);
AutoExtraCost(y) = max(7.5 * .866**ord(y), 0.1);

CapitalCost(r,"ICE_PET_F",y) = 27 + AutoExtraCost(y);
CapitalCost(r,"ICE_DSL_F",y) = 32 + AutoExtraCost(y);

*CapitalCost(r,"EV_F",y) = 38.8860;
*CapitalCost(r,"EV_F",2015) = CapitalCost(r,"EV_F",y) * .987 ** (ord(y)-1);

CapitalCost(r,"PHEV_F",y) = 37.5 + AutoExtraCost(y);
CapitalCost(r,"HYBRID_F",y) = 32 + AutoExtraCost(y);
CapitalCost(r,"H2V_F",y) = 57.5 + AutoExtraCost(y);

CapitalCost(r,"EV_F",y) = CapitalCost(r,"EV_F",y) + AutoExtraCost(y);

CapitalCost(r,"ICE_PET_PUB",y) = 300;
CapitalCost(r,"ICE_DSL_PUB",y) = 300;
CapitalCost(r,"CNG_PUB",y) = 370;
CapitalCost(r,"EV_PUB","2015") = 600;
CapitalCost(r, "EV_PUB",y) = CapitalCost(r,"EV_PUB","2015")*0.9734**(ord(y)-1);
CapitalCost(r,"PHEV_PUB",y) = 600;
CapitalCost(r,"HYBRID_PUB",y) = 500;
CapitalCost(r,"BIO_DSL_PUB",y) = 370;

CapitalCost(r,"EV_CHARGE",y) = 0;
CapitalCost(r,"V2G",y) = 1.5*CapitalCost(r,"BATTERY",y);
CapitalCost(r,"EV_DISCHARGE",y) = 0;

CapitalCost(r,"EV_CHARGE_F",y) = 0;
CapitalCost(r,"V2G_F",y) = 1.5*CapitalCost(r,"BATTERY",y);
CapitalCost(r,"EV_DISCHARGE_F",y) = 0;


table VariableCost(REGION,TECHNOLOGY,MODE_OF_OPERATION,YEAR)
* Variable costs (variable O&M for power plants; fuel costs for fuel purchasing)
* Data Source: NREL 2016 Annual Technology Baseline
*Units: Million$/PJ, Million$/Millions of Miles
*              SPEER ATX Case Study for Demand Response
* In driving mode (3), VSTORE incurs typical variable cost per mile. Battery is free!
                         2015          2016          2017          2018          2019          2020          2021          2022          2023          2024          2025          2026          2027          2028          2029          2030          2031          2032          2033          2034          2035          2036          2037          2038          2039          2040          2041          2042          2043          2044          2045          2046          2047          2048          2049          2050
ATX.COALPP.1             1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889
ATX.CCPP.1               0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333        0.8333
ATX.CTPP.1               1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444
ATX.NUCPP.1              0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556        0.5556
ATX.HYDROPP.1            0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000        0.0000
ATX.BIOPP.1              1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889        1.3889
ATX.CCCCSPP.1            1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444        1.9444
ATX.IGCCCCSPP.1          2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000        2.5000
ATX.H2FUELCELL.1         0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778        0.2778
ATX.BUYCOAL.1            1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956        1.8956
ATX.BUYURN.1             0.5020        0.5197        0.5541        0.5728        0.5748        0.5728        0.5905        0.6132        0.6378        0.6516        0.6840        0.7027        0.7205        0.7401        0.7490        0.7579        0.7785        0.8012        0.8238        0.8464        0.8701        0.8947        0.9203        0.9468        0.9744        1.0010        1.0305        1.0600        1.0896        1.1211        1.1535        1.1870        1.2205        1.2559        1.2923        1.3297
ATX.BUYBIO.1             2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679        2.7679
ATX.BUYGAS.1             3.0509        2.7999        3.2780        3.5336        3.8781        4.2108        4.2470        4.2089        4.2321        4.3475        4.4661        4.5745        4.6920        4.7904        4.8771        4.9109        4.9307        4.9269        4.8792        4.9029        5.0066        5.0165        5.0503        5.0592        5.0884        5.0488        5.0628        5.1165        5.1946        5.2594        5.3357        5.3972        5.4589        5.5578        5.5895        5.6913
ATX.BUYPET.1             2.4300        2.1500        2.3600        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500        2.3500
ATX.BUYDSL.1             3.0795        2.6250        2.9659        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909        3.0909
ATX.BUYBIO_DSL.1         2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667        2.7667
ATX.ICE_PET.1            0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800
ATX.ICE_DSL.1            0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800
ATX.EV.1                 0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650
ATX.PHEV.1               0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700
ATX.H2V.1                0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650
ATX.HYBRID.1             0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700
ATX.ICE_PET_F.1          0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800
ATX.ICE_DSL_F.1          0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800        0.0800
ATX.EV_F.1               0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650
ATX.PHEV_F.1             0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700
ATX.H2V_F.1              0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650        0.0650
ATX.HYBRID_F.1           0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700        0.0700
ATX.ICE_PET_PUB.1        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875
ATX.ICE_DSL_PUB.1        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875
ATX.BIO_DSL_PUB.1        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875
ATX.CNG_PUB.1            0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875        0.2875
ATX.EV_PUB.1             0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013        0.2013
ATX.PHEV_PUB.1           0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336        0.2336;
*ATX.HYBRID_PUB.1         0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516        0.2516;

VariableCost(r,"HYBRID_PUB","1",y) = 0.3;

VariableCost(r,"ELCTROL","1",y) = 2.0;
VariableCost(r,"GASREF","1",y) = 2.0;
VariableCost(r,"BIOGAS","1",y) = 2.0;
VariableCost(r,"COALGAS","1",y) = 2.0;

VariableCost(r,"BUYPET","1",y) = 2.43;

VariableCost(r,"BATTERY","2",y) = 0.62255;
VariableCost(r,"EV_CHARGE", "1", y) = 0;
VariableCost(r,"V2G","1",y) = 0;
VariableCost(r,"EV_DISCHARGE","1",y) = 0;

VariableCost(r,"EV_CHARGE_F", "1", y) = 0;
VariableCost(r,"V2G_F","1",y) = 0;
VariableCost(r,"EV_DISCHARGE_F","1",y) = 0;




* Avoid errors from zeros
VariableCost(REGION,TECHNOLOGY,MODE_OF_OPERATION,YEAR)$(VariableCost(REGION,TECHNOLOGY,MODE_OF_OPERATION,YEAR) eq 0) = 0.000001;

table FixedCost(REGION,TECHNOLOGY,YEAR)
* Fixed costs (fixed O&M for power plants)
* Units: $/kW,?? Million$/Thousand Units (Vehicles)
* Data Source: NREL 2016 Annual Technology Baseline
                         2015            2016          2017              2018            2019            2020            2021            2022            2023            2024            2025            2026            2027            2028            2029            2030            2031            2032            2033            2034            2035            2036            2037            2038            2039            2040            2041            2042            2043            2044            2045            2046            2047            2048            2049            2050
ATX.COALPP               32.000          32.000        32.000            32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000          32.000
ATX.CCPP                 10.000          10.000        10.000            10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000
ATX.CTPP                 12.000          12.000        12.000            12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000          12.000
ATX.NUCPP                102.000         102.000       102.000           102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000         102.000
ATX.HYDROPP              118.048         118.048       118.048           118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048         118.048
ATX.WINDPP               51.000          50.636        50.271            49.907          49.543          49.179          48.814          48.450          48.086          47.721          47.357          46.993          46.629          46.264          45.900          45.536          45.171          44.807          44.443          44.079          43.714          43.350          42.986          42.621          42.257          41.893          41.529          41.164          40.800          40.436          40.071          39.707          39.343          38.979          38.614          38.250
ATX.SOLPP                13.000          12.700        12.400            12.100          11.800          11.500          11.200          10.900          10.600          10.300          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000          10.000
ATX.BIOPP                108.000         108.000       108.000           108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000         108.000
ATX.CCCCSPP              33.000          33.000        33.000            33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000          33.000
ATX.IGCCCCSPP            79.000          79.000        79.000            79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000          79.000;

FixedCost(r,PrivTrans,y) = 0.10;
FixedCost(r,Fleet,y)   = 0.10;
FixedCost(r,PubTrans,y) = 0.10;

FixedCost(r,"H2FUELCELL",y) = 10;

FixedCost(r,"BATTERY",y) = 7.36392;
FixedCost(r,"EV_CHARGE",y) = 0;
FixedCost(r,"V2G",y) = 0;
FixedCost(r,"EV_DISCHARGE",y) = 0;

FixedCost(r,"EV_CHARGE_F",y) = 0;
FixedCost(r,"V2G_F",y) = 0;
FixedCost(r,"EV_DISCHARGE_F",y) = 0;

FixedCost(r,"ELCTROL",y) = 0.176;
FixedCost(r,"GASREF",y) = 0.068;
FixedCost(r,"BIOGAS",y)  = 0.176;
FixedCost(r,"COALGAS",y) = 0.273;





* ##### Storage Parameters #####

parameter TechnologyToStorage(REGION,TECHNOLOGY,STORAGE,MODE_OF_OPERATION);
TechnologyToStorage(r,t,s,m) = 0;

TechnologyToStorage(REGION,"BATTERY","BAT","2") = 1;
TechnologyToStorage(REGION,"EV_CHARGE","EV_BAT","1") = 1;

TechnologyToStorage(REGION,"EV_CHARGE_F","EV_BAT_F","1") = 1;


parameter TechnologyFromStorage(REGION,TECHNOLOGY,STORAGE,MODE_OF_OPERATION);
TechnologyFromStorage(r,t,s,m) = 0;

TechnologyFromStorage(REGION,"BATTERY","BAT","1") = 1;
TechnologyFromStorage(r,"V2G","EV_BAT","1") = 1;
TechnologyFromStorage(r,"EV_DISCHARGE","EV_BAT","1") = 1;

TechnologyFromStorage(r,"V2G_F","EV_BAT_F","1") = 1;
TechnologyFromStorage(r,"EV_DISCHARGE_F","EV_BAT_F","1") = 1;


parameter OperationalStorageLife(REGION,STORAGE);
OperationalStorageLife(r,"BAT") = 10;
OperationalStorageLife(r,"EV_BAT") = 10;


OperationalStorageLife(r,"EV_BAT_F") = 10;

parameter ResidualStorageCapacity(YEAR,STORAGE,REGION);
ResidualStorageCapacity(y,s,r) = 0;

ResidualStorageCapacity("2015","EV_BAT",r) = 0.000036;
ResidualStorageCapacity("2015","EV_BAT_F",r) = 0;


ResidualStorageCapacity(y,s,r) = max(0,ResidualStorageCapacity("2015",s,r) - ResidualStorageCapacity("2015",s,r)/OperationalStorageLife(r,s)*(ord(y)-1));

parameter MinStorageCharge(STORAGE,YEAR,REGION);
MinStorageCharge(s,y,r) = 0;



parameter CapitalCostStorage(YEAR,STORAGE,REGION);
CapitalCostStorage("2015","BAT",r) = 235681.25222;
CapitalCostStorage("2016","BAT",r) = 207399.5019536;
CapitalCostStorage("2017","BAT",r) = 182511.561719168;
CapitalCostStorage("2018","BAT",r) = 160610.174312868;
CapitalCostStorage("2019","BAT",r) = 141336.953395324;
CapitalCostStorage("2020","BAT",r) = 124376.518987885;
CapitalCostStorage("2021","BAT",r) = 109451.336709339;
CapitalCostStorage("2022","BAT",r) = 96317.176304218;
CapitalCostStorage("2023","BAT",r) = 84759.1151477119;
CapitalCostStorage("2024","BAT",r) = 74588.0213299864;
CapitalCostStorage("2025","BAT",r) = 65637.4587703881;
CapitalCostStorage("2026","BAT",r) = 57760.9637179415;
CapitalCostStorage("2027","BAT",r) = 50829.6480717885;
CapitalCostStorage("2028","BAT",r) = 44730.0903031739;
CapitalCostStorage("2029","BAT",r) = 39362.479466793;
CapitalCostStorage("2030","BAT",r) = 34638.9819307779;
CapitalCostStorage("2031","BAT",r) = 30482.3040990845;
CapitalCostStorage("2032","BAT",r) = 26824.4276071944;
CapitalCostStorage("2033","BAT",r) = 23605.4962943311;
CapitalCostStorage("2034","BAT",r) = 20772.8367390113;
CapitalCostStorage("2035","BAT",r) = 18280.09633033;
CapitalCostStorage("2036","BAT",r) = 16086.4847706904;
CapitalCostStorage("2037","BAT",r) = 14156.1065982075;
CapitalCostStorage("2038","BAT",r) = 12457.3738064226;
CapitalCostStorage("2039","BAT",r) = 10962.4889496519;
CapitalCostStorage("2040","BAT",r) = 9646.99027569368;
CapitalCostStorage("2041","BAT",r) = 8489.35144261044;
CapitalCostStorage("2042","BAT",r) = 7470.62926949719;
CapitalCostStorage("2043","BAT",r) = 6574.15375715752;
CapitalCostStorage("2044","BAT",r) = 5785.25530629862;
CapitalCostStorage("2045","BAT",r) = 5091.02466954279;
CapitalCostStorage("2046","BAT",r) = 4480.10170919765;
CapitalCostStorage("2047","BAT",r) = 3942.48950409393;
CapitalCostStorage("2048","BAT",r) = 3469.39076360266;
CapitalCostStorage("2049","BAT",r) = 3053.06387197034;
CapitalCostStorage("2050","BAT",r) = 2686.6962073339;

CapitalCostStorage(y,"EV_BAT",r) = 0;



parameter MaxCapacityGrowthRateStorage(REGION,STORAGE);
MaxCapacityGrowthRateStorage(r,s) = 0.25;

*Start Up Value for storage capacity (PJ) (800 mWh)
parameter StartUpValueStorage(STORAGE);
StartUpValueStorage(s) = 0.5;


parameter DiscountRateStorage(REGION,STORAGE);
DiscountRateStorage(r,s) = 0.05;
* ##### Capacity Constraints #####

table TotalAnnualMaxCapacity(REGION,TECHNOLOGY,YEAR)
* Maximum total (residual and new) capacity in each year
* Units:

                   2015
ATX.COALPP         9999999999
ATX.CCPP           9999999999
ATX.CTPP           9999999999
ATX.NUCPP          9999999999
ATX.HYDROPP        9999999999
ATX.WINDPP         9999999999
ATX.SOLPP          9999999999
ATX.BIOPP          9999999999
ATX.CCCCSPP        9999999999
ATX.IGCCCCSPP      9999999999
ATX.H2FUELCELL     9999999999
ATX.BATTERY        9999999999
ATX.EV_CHARGE      9999999999
ATX.V2G            9999999999
ATX.EV_DISCHARGE   9999999999
ATX.EV_CHARGE_F    9999999999
ATX.V2G_F          9999999999
ATX.EV_DISCHARGE_F 9999999999
ATX.BUYCOAL        9999999999
ATX.BUYURN         9999999999
ATX.BUYBIO         9999999999
ATX.BUYGAS         9999999999
ATX.BUYPET         9999999999
ATX.BUYDSL         9999999999
ATX.BUYBIO_DSL     9999999999
ATX.SOLPOT         9999999999
ATX.WINDPOT        9999999999
ATX.HYDROPOT       0.6
ATX.ICE_PET        9999999999
ATX.ICE_DSL        9999999999
ATX.PHEV           9999999999
ATX.HYBRID         9999999999
ATX.H2V            9999999999
ATX.EV             9999999999
ATX.ICE_PET_F      9999999999
ATX.ICE_DSL_F      9999999999
ATX.PHEV_F         9999999999
ATX.HYBRID_F       9999999999
ATX.H2V_F          9999999999
ATX.EV_F           9999999999
ATX.ICE_PET_PUB    9999999999
ATX.ICE_DSL_PUB    9999999999
ATX.CNG_PUB        9999999999
ATX.EV_PUB         9999999999
ATX.PHEV_PUB       9999999999
ATX.HYBRID_PUB     9999999999
ATX.BIO_DSL_PUB    9999999999
ATX.ELCTROL        9999999999
ATX.GASREF         9999999999
ATX.BIOGAS         9999999999
ATX.COALGAS        9999999999;


* Project forward
TotalAnnualMaxCapacity(r,t,y) = TotalAnnualMaxCapacity(r,t,"2015");



parameter TotalAnnualMinCapacity(REGION,TECHNOLOGY,YEAR);
* Minimum total (residual and new) capacity in each year
* Units: GW
TotalAnnualMinCapacity(REGION,TECHNOLOGY,YEAR) = 0;

* ##### Investment Constraints #####

parameter MaxCapacityGrowthRate(REGION,TECHNOLOGY);
* Maximum annual growth rate of capacity
* Units: Fraction
MaxCapacityGrowthRate(r,t) = 9999;

MaxCapacityGrowthRate(r,"COALPP") = 0.1;
MaxCapacityGrowthRate(r,"CCPP") = 0.1;
MaxCapacityGrowthRate(r,"CTPP") = 0.1;
MaxCapacityGrowthRate(r,"NUCPP") = 0.1;
MaxCapacityGrowthRate(r,"HYDROPP") = 0.1;
MaxCapacityGrowthRate(r,"WINDPP") = 0.25;
MaxCapacityGrowthRate(r,"SOLPP") = 0.25;
MaxCapacityGrowthRate(r,"BIOPP") = 0.1;
MaxCapacityGrowthRate(r,"CCCCSPP") = 0.1;
MaxCapacityGrowthRate(r,"IGCCCCSPP") = 0.1;
MaxCapacityGrowthRate(r,"H2FUELCELL") = 0.1;
MaxCapacityGrowthRate(r,"BATTERY") = 0.25;
MaxCapacityGrowthRate(r,"EV_CHARGE") = 0.25;
MaxCapacityGrowthRate(r,"V2G") = 0.25;
MaxCapacityGrowthRate(r,"EV_DISCHARGE") = 1;
MaxCapacityGrowthRate(r,"EV_CHARGE_F") = 0.25;
MaxCapacityGrowthRate(r,"V2G_F") = 0.25;
MaxCapacityGrowthRate(r,"EV_DISCHARGE_F") = 1;
MaxCapacityGrowthRate(r,"ELCTROL") = 0.1;
MaxCapacityGrowthRate(r,"GASREF") = 0.1;
MaxCapacityGrowthRate(r,"BIOGAS") = 0.1;
MaxCapacityGrowthRate(r,"COALGAS") = 0.1;

MaxCapacityGrowthRate(r,PrivTrans) = .25;
MaxCapacityGrowthRate(r,PubTrans) = .5;
MaxCapacityGrowthRate(r,Fleet) = .5;


parameter StartUpValue(TECHNOLOGY);
* Allows initial deployment of new technologies
* Units: GW

StartUpValue("COALPP") = .1;
StartUpValue("CCPP") = .1;
StartUpValue("CTPP") = .1;
StartUpValue("NUCPP") = .1;
StartUpValue("HYDROPP") = .1;
StartUpValue("WINDPP") = .1;
StartUpValue("SOLPP") = .1;
StartUpValue("BIOPP") = .1;
StartUpValue("CCCCSPP") = .1;
StartUpValue("IGCCCCSPP") = .1;
StartUpValue("H2FUELCELL") = 0.1;
StartUpValue("BATTERY") = 0.1;
StartUpValue("EV_CHARGE") = 0.1;
StartUpValue("V2G") = 0.1;
StartUpValue("EV_DISCHARGE") = 99999999999;
StartUpValue("EV_CHARGE_F") = 0.1;
StartUpValue("V2G_F") = 0.1;
StartUpValue("EV_DISCHARGE_F") = 99999999999;
StartUpValue("BUYCOAL") = 99999999999;
StartUpValue("BUYURN") = 99999999999;
StartUpValue("BUYBIO") = 99999999999;
StartUpValue("BUYGAS") = 99999999999;
StartUpValue("BUYPET") = 99999999999;
StartUpValue("BUYDSL") = 99999999999;
StartUpValue("BUYBIO_DSL") = 99999999999;
StartUpValue("SOLPOT") = 99999999999;
StartUpValue("WINDPOT") = 99999999999;
StartUpValue("HYDROPOT") = 99999999999;

StartUpValue("ELCTROL") = 18.59675;
StartUpValue("GASREF") = 18.59675;
StartUpValue("BIOGAS") = 18.59675;
StartUpValue("COALGAS") = 18.59675;

StartUpValue(PP) = 0.1;
StartUpValue(PrivTrans) = 1;
StartUpValue(PubTrans) = 0.05;
StartUpValue(Fleet) = 1;

parameter TotalAnnualMaxCapacityInvestment(REGION,TECHNOLOGY,YEAR);
* Maximum new capacity in each year
* Units: GW
TotalAnnualMaxCapacityInvestment(REGION,TECHNOLOGY,YEAR) = 9999999999999999;
TotalAnnualMaxCapacityInvestment(r,t,"2015") = MaxCapacityGrowthRate(r,t)*ResidualCapacity(r,t,"2015") + StartUpValue(t);
TotalAnnualMaxCapacityInvestment(r,Fleet,"2015") = 9999999999999999;

parameter TotalAnnualMinCapacityInvestment(REGION,TECHNOLOGY,YEAR);
* Minimum new capacity in each year
* Units: GW
TotalAnnualMinCapacityInvestment(REGION,TECHNOLOGY,YEAR) = 0;

* ######## Activity Constraints #############

parameter TotalTechnologyAnnualActivityUpperLimit(REGION,TECHNOLOGY,YEAR);
* Maximum amount of activity that a technology can perform each year
* Units: PJ
TotalTechnologyAnnualActivityUpperLimit(REGION,TECHNOLOGY,YEAR) = 9999999999;

parameter TotalTechnologyAnnualActivityLowerLimit(REGION,TECHNOLOGY,YEAR);
* Minimum amount of activity that a technology can perform each year
* Units: PJ
TotalTechnologyAnnualActivityLowerLimit(REGION,TECHNOLOGY,YEAR) = 0;

parameter TotalTechnologyModelPeriodActivityUpperLimit(REGION,TECHNOLOGY);
* Maximum level of activity by a technology over the whole model period
* Units: PJ
TotalTechnologyModelPeriodActivityUpperLimit(REGION,TECHNOLOGY) = 999999999;

parameter TotalTechnologyModelPeriodActivityLowerLimit(REGION,TECHNOLOGY);
* Minimum level of activity by a technology over the whole model period
* Units: PJ
TotalTechnologyModelPeriodActivityLowerLimit(REGION,TECHNOLOGY) = 0;

* ##### Reserve Margin #####

table ReserveMarginTagTechnology(REGION,TECHNOLOGY,YEAR)
* Technologies that contribute to meeting the reserve margin requirement
* Units: 1=yes, 0=no
                       2015
ATX.COALPP             1
ATX.CCPP               1
ATX.CTPP               1
ATX.NUCPP              1
ATX.HYDROPP            1
ATX.WINDPP             1
ATX.SOLPP              1
ATX.BIOPP              1
ATX.CCCCSPP            1
ATX.IGCCCCSPP          1
ATX.BATTERY            1
ATX.V2G                1
ATX.V2G_F              1;

* Project forward
ReserveMarginTagTechnology(r,t,y) = ReserveMarginTagTechnology(r,t,"2015");

table ReserveMarginTagFuel(REGION,FUEL,YEAR)
* Fuel subject to a reserve margin requirement
* Units: 1=yes,0=no
               2015
ATX.ELC        1;

* Project forward
ReserveMarginTagFuel(r,f,y) = ReserveMarginTagFuel(r,f,"2015");

table ReserveMargin(REGION,YEAR)
* The reserve (installed) capacity required relative to the peak demand for the specified fuel
* Units: Installed/Peak
       2015
ATX    1.18;

* Project forward
ReserveMargin(r,y) = ReserveMargin(r,"2015");

* ##### Renewable Energy Generation Target #####

parameter RETagTechnology(REGION,TECHNOLOGY,YEAR);
* Technologies that are allowed to contribute to the renewable capacity of the system
* Units: 1=yes,0=no
* Data Source: Texas RPS eligibility
RETagTechnology(REGION,TECHNOLOGY,YEAR) = 0;
RETagTechnology(REGION,"WINDPP",YEAR) = 1;
RETagTechnology(REGION,"SOLPP",YEAR) = 1;
RETagTechnology(REGION,"HYDROPP",YEAR) = 1;
RETagTechnology(REGION,"BIOPP",YEAR) = 1;

parameter RETagFuel(REGION,FUEL,YEAR);
* The fuels for which there is a renewable target
* Units: 1=yes,0=no
RETagFuel(REGION,FUEL,YEAR) = 0;
RETagFuel(REGION,"ELC",YEAR) = 1;

parameter REMinProductionTarget(REGION,YEAR);
* What fraction of the fuels must come from renewable technologies
* Units: Fraction
REMinProductionTarget(REGION,YEAR) = 0;

* ##### Emissions and Penalties #####

table EmissionActivityRatio(REGION,TECHNOLOGY,EMISSION,MODE_OF_OPERATION,YEAR)
* Emission rates by technology
* Units: Million Tonnes / PJ Output, Million Tonnes / Millions of Miles
* Data Source: IPCC AR5 WG3 Annex III
                         2015
ATX.COALPP.CO2.1         0.21111300000
ATX.CCPP.CO2.1           0.10277900000
ATX.CTPP.CO2.1           0.13416800000
ATX.BIOPP.CO2.1          0.06388900000
ATX.CCCCSPP.CO2.1        0.04722300000
ATX.IGCCCCSPP.CO2.1      0.05555600000
ATX.ICE_PET.CO2.1        0.00029300000
ATX.ICE_DSL.CO2.1        0.00027600000
ATX.EV.CO2.1             0.00000000000
ATX.PHEV.CO2.1           0.00010400000
ATX.HYBRID.CO2.1         0.00019400000
ATX.H2V.CO2.1            0.00000000000
ATX.ICE_PET_F.CO2.1      0.00029300000
ATX.ICE_DSL_F.CO2.1      0.00027600000
ATX.EV_F.CO2.1           0.00000000000
ATX.PHEV_F.CO2.1         0.00010400000
ATX.HYBRID_F.CO2.1       0.00019400000
ATX.H2V_F.CO2.1          0.00000000000
ATX.ICE_PET_PUB.CO2.1    0.00001953333
ATX.ICE_DSL_PUB.CO2.1    0.00001840000
ATX.CNG_PUB.CO2.1        0.00001840000
ATX.EV_PUB.CO2.1         0.00000000000
ATX.PHEV_PUB.CO2.1       0.00000693333
ATX.HYBRID_PUB.CO2.1     0.00001293333
ATX.BIO_DSL_PUB.CO2.1    0.00001840000
ATX.ELCTROL.CO2.1        0.00480956152
ATX.GASREF.CO2.1         0.00961912305
ATX.BIOGAS.CO2.1         0.00240478076
ATX.COALGAS.CO2.1        0.00913816689;





* Project forward
EmissionActivityRatio(r,t,e,m,y) = EmissionActivityRatio(r,t,e,m,"2015");

table EmissionsPenalty(REGION,EMISSION,YEAR)
* Emissions tax
* Units: $/Tonne
                 2015
ATX.CO2          20 ;


* Project forward
EmissionsPenalty(r,e,y) = EmissionsPenalty(r,e,"2015")*(1.05)**(ord(y)-1);
EmissionsPenalty(r,e,y) = 0;

parameter AnnualExogenousEmission(REGION,EMISSION,YEAR);
AnnualExogenousEmission(REGION,EMISSION,YEAR) = 0;

parameter AnnualEmissionLimit(REGION,EMISSION,YEAR);
AnnualEmissionLimit(REGION,EMISSION,y) = 999999999;
parameter ModelPeriodExogenousEmission(REGION,EMISSION);
ModelPeriodExogenousEmission(REGION,EMISSION) = 0;

parameter ModelPeriodEmissionLimit(REGION,EMISSION);
ModelPeriodEmissionLimit(REGION,EMISSION) = 999999999;

parameter YearVal(YEAR);
YearVal(YEAR) = StartYear-1+ord(YEAR);

parameter NICPPlower(YEAR);
NICPPlower(y) = 0.6;
NICPPlower(y)$(ORD(y) LE 5) = 0;

* ##### Model Variables #####

* ##### Capacity Variables #####

positive variable NewCapacity(YEAR,TECHNOLOGY,REGION);
positive variable AccumulatedNewCapacity(YEAR,TECHNOLOGY,REGION);
positive variable TotalCapacityAnnual(YEAR,TECHNOLOGY,REGION);

* ##### Activity Variables #####

positive variable Activity(YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,REGION);
positive variable RateOfTotalActivity(YEAR,TIMESLICE,TECHNOLOGY,REGION);
positive variable RateOfActivity(YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,REGION);

positive variable TotalTechnologyAnnualActivity(YEAR,TECHNOLOGY,REGION);
positive variable TotalAnnualTechnologyActivityByMode(YEAR,TECHNOLOGY,MODE_OF_OPERATION,REGION);
positive variable RateOfProductionByTechnologyByMode(YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,FUEL,REGION);
positive variable RateOfProductionByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);
positive variable ProductionByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);

ProductionByTechnology.fx(y,LowV2G,"EV_CHARGE",f,r) = 0;
*ProductionByTechnology.fx(y,LowV2G,"EV_CHARGE_F",f,r) = 0;



positive variable ProductionByTechnologyAnnual(YEAR,TECHNOLOGY,FUEL,REGION);
positive variable RateOfProduction(YEAR,TIMESLICE,FUEL,REGION);
positive variable Production(YEAR,TIMESLICE,FUEL,REGION);
positive variable RateOfUseByTechnologyByMode(YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,FUEL,REGION);


positive variable RateOfUseByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);
positive variable UseByTechnologyAnnual(YEAR,TECHNOLOGY,FUEL,REGION);
positive variable RateOfUse(YEAR,TIMESLICE,FUEL,REGION);
positive variable UseByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);




positive variable Use(YEAR,TIMESLICE,FUEL,REGION);
positive variable RateOfDemand(YEAR,TIMESLICE,FUEL,REGION);
positive variable Demand(YEAR,TIMESLICE,FUEL,REGION);
positive variable ProductionAnnual(YEAR,FUEL,REGION);
positive variable UseAnnual(YEAR,FUEL,REGION);

* ##### Costing Variables #####

positive variable CapitalInvestment(YEAR,TECHNOLOGY,REGION);
positive variable DiscountedCapitalInvestment(YEAR,TECHNOLOGY,REGION);
positive variable SalvageValue(YEAR,TECHNOLOGY,REGION);
positive variable DiscountedSalvageValue(YEAR,TECHNOLOGY,REGION);
positive variable OperatingCost(YEAR,TECHNOLOGY,REGION);
positive variable DiscountedOperatingCost(YEAR,TECHNOLOGY,REGION);
positive variable AnnualVariableOperatingCost(YEAR,TECHNOLOGY,REGION);
positive variable AnnualFixedOperatingCost(YEAR,TECHNOLOGY,REGION);
positive variable VariableOperatingCost(YEAR,TIMESLICE,TECHNOLOGY,REGION);
positive variable TotalDiscountedCost(YEAR,TECHNOLOGY,REGION);
positive variable ModelPeriodCostByRegion (REGION);

* ##### Storage Variables #####

free variable NetStorageCharge(STORAGE,YEAR,TIMESLICE,REGION);
positive variable StorageLevel(STORAGE,YEAR,TIMESLICE,REGION);
positive variable StorageCharge(STORAGE,YEAR,TIMESLICE,REGION);
positive variable StorageDischarge(STORAGE,YEAR,TIMESLICE,REGION);

positive variable StorageLowerLimit(YEAR,STORAGE,REGION);
positive variable StorageUpperLimit(YEAR,STORAGE,REGION);
positive variable AccumulatedStorageCapacity(YEAR,STORAGE,REGION);
positive variable NewStorageCapacity(YEAR,STORAGE,REGION);
positive variable CapitalInvestmentStorage(YEAR,STORAGE,REGION);
positive variable DiscountedCapitalInvestmentStorage(YEAR,STORAGE,REGION);
positive variable SalvageValueStorage(YEAR,STORAGE,REGION);
positive variable DiscountedSalvageValueStorage(YEAR,STORAGE,REGION);
positive variable TotalDiscountedStorageCost(YEAR,STORAGE,REGION);

* ##### Reserve Margin #####

positive variable TotalCapacityInReserveMargin(REGION,YEAR);
positive variable DemandNeedingReserveMargin(YEAR,TIMESLICE,REGION);

* ##### RE Gen Target #####

free variable TotalGenerationByRETechnologies(YEAR,REGION);
free variable TotalREProductionAnnual(YEAR,REGION);
free variable RETotalDemandOfTargetFuelAnnual(YEAR,REGION);
free variable TotalTechnologyModelPeriodActivity(TECHNOLOGY,REGION);

* ##### Emissions #####

positive variable AnnualTechnologyEmissionByMode(YEAR,TECHNOLOGY,EMISSION,MODE_OF_OPERATION,REGION);
positive variable AnnualTechnologyEmission(YEAR,TECHNOLOGY,EMISSION,REGION);
positive variable AnnualTechnologyEmissionPenaltyByEmission(YEAR,TECHNOLOGY,EMISSION,REGION);
positive variable AnnualTechnologyEmissionsPenalty(YEAR,TECHNOLOGY,REGION);
positive variable DiscountedTechnologyEmissionsPenalty(YEAR,TECHNOLOGY,REGION);
positive variable AnnualEmissions(YEAR,EMISSION,REGION);
free variable EmissionsProduction(YEAR,TECHNOLOGY,EMISSION,MODE_OF_OPERATION,REGION);
positive variable ModelPeriodEmissions(EMISSION,REGION);
*added emissions variables

positive variable EmissionRatioByTimeslice(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);
positive variable TimesliceEmissionProduction(YEAR,TECHNOLOGY,EMISSION,TIMESLICE,FUEL,REGION);


*EmissionRatioByTimeslice.fx("2020","W1","EV_CHARGE","ELC","ATX") = UseByTechnology("2020","W1","EV_CHARGE","ELC","ATX") /  sum(t,ProductionByTechnology("2020","W1",t,"ELC","ATX"));




* ##### Calibration #####
* free variable CalibratedCap;
* free variable CalibratedRPS;


* #### Demand Response ####
set DR_TYPE /LO,MED,HI/;
alias(d,DR_TYPE);

parameter DemandResponseVarCost(YEAR,DR_TYPE,FUEL,REGION);
DemandResponseVarCost(y,d,f,r) = 0;
*DR LO is 300 $Million/PJ
DemandResponseVarCost(y,"LO","ELC",r) = 300*277778/1000000;
DemandResponseVarCost(y,"MED","ELC",r) = 500*277778/1000000;
DemandResponseVarCost(y,"HI","ELC",r) = 1000*277778/1000000;

parameter DemandResponseMaxLevel(YEAR,DR_TYPE,FUEL,TIMESLICE,REGION);
DemandResponseMaxLevel(y,d,f,l,r) = 0;
DemandResponseMaxLevel(y,d,"ELC",l,r) = 0.2*(1+ORD(y)/CARD(y))*8760*YearSplit(l,y)*(1/277.7777777778);

parameter DemandResponseMinLevel(YEAR,DR_TYPE,FUEL,TIMESLICE,REGION);
DemandResponseMinLevel(y,d,f,l,r) = 0;

parameter TagFuelWithDemandResponseCapability(FUEL,DR_TYPE);
TagFuelWithDemandResponseCapability(f,d) = 0;
TagFuelWithDemandResponseCapability("ELC",d) = 1;

parameter DemandResponseDiscountRate(r);
DemandResponseDiscountRate(r) = 0.05;

positive variable DemandResponseLevel(YEAR,DR_TYPE,FUEL,TIMESLICE,REGION);
positive variable DemandResponseCost(YEAR,TIMESLICE,REGION);
positive variable DemandResponseAnnualCost(YEAR,REGION);
positive variable DiscountedDemandResponseAnnualCost(YEAR,REGION);

* #### CapitalVintaging ####
positive variable RateOfActivityByVintage(YEAR,YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,REGION);
positive variable RateOfUseByTechnologyByModeByVintage(YEAR,YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,FUEL,REGION);
positive variable RateOfTotalActivityByVintage(YEAR,YEAR,TIMESLICE,TECHNOLOGY,REGION);

parameter FleetSize(YEAR,REGION);
parameter FleetSizeFleet(YEAR,REGION);
scalar AvgSpeed /30/;
FleetSize(y,r) = smax(l,1000*(((SpecifiedDemandProfile(r,"VMT",l,y)*SpecifiedAnnualDemand(r,"VMT",y))/(YearSplit(l,y)*8760))/AvgSpeed)*(1/CapacityFactor(r,"ICE_PET","W1",y)));
FleetSizeFleet(y,r) = smax(l,1000*(((SpecifiedDemandProfile(r,"FMT",l,y)*SpecifiedAnnualDemand(r,"FMT",y))/(YearSplit(l,y)*8760))/AvgSpeed)*(1/CapacityFactor(r,"ICE_PET_F","W1",y)));



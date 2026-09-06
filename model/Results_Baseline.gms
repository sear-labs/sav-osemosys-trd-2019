FILE Results_Baseline /OSeMOSYS_ATX_Baseline_Results.csv/;
PUT Results_Baseline;
Results_Baseline.pc = 5;
Results_Baseline.pw = 500;

put 'Output Data:' / /;


loop((r,t),
 put / "TotalAnnualCapacity",r.TL,t.TL;
 loop(y, put TotalCapacityAnnual.L(y,t,r));
);
put / /;

loop((r,t),
 put / "NewCapacity",r.TL,t.TL;
 loop(y, put NewCapacity.L(y,t,r));
);
put / /;

loop((r,t,f)$(sum((y,m), OutputActivityRatio(r,t,f,m,y)) > 0),
 put / "AnnualGenerationByTechnology",r.TL,t.TL,f.TL;
 loop(y, put ProductionByTechnologyAnnual.L(y,t,f,r));
);
put /;

* Annual Emissions (by region, technology, emission, year)
loop((r,t,e)$(sum((y,m), EmissionActivityRatio(r,t,e,m,y)) > 0),
 put / "AnnualEmissions",r.TL,e.TL,t.TL;
 loop(y, put AnnualTechnologyEmission.L(y,t,e,r));
);
put /;

loop((t,r),
 put / "Year 2020 Electricity Production - WINTER",r.TL,t.TL;
 loop(WNT, put ProductionByTechnology.L("2020",WNT,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2020 Electricity Production - INTERMEDIATE",r.TL,t.TL;
 loop(SPRFALL, put ProductionByTechnology.L("2020",SPRFALL,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2020 Electricity Production - SUMMER",r.TL,t.TL;
 loop(SUMM, put ProductionByTechnology.L("2020",SUMM,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2020 Electricity Use - WINTER",r.TL,t.TL;
 loop(WNT, put UseByTechnology.L("2020",WNT,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2020 Electricity Use - INTERMEDIATE",r.TL,t.TL;
 loop(SPRFALL, put UseByTechnology.L("2020",SPRFALL,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2020 Electricity Use - SUMMER",r.TL,t.TL;
 loop(SUMM, put UseByTechnology.L("2020",SUMM,t,"ELC",r));
 );
put / /;



loop((t,r),
 put / "Year 2050 Electricity Production - WINTER",r.TL,t.TL;
 loop(WNT, put ProductionByTechnology.L("2050",WNT,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2050 Electricity Production - INTERMEDIATE",r.TL,t.TL;
 loop(SPRFALL, put ProductionByTechnology.L("2050",SPRFALL,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2050 Electricity Production - SUMMER",r.TL,t.TL;
 loop(SUMM, put ProductionByTechnology.L("2050",SUMM,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2050 Electricity Use - WINTER",r.TL,t.TL;
 loop(WNT, put UseByTechnology.L("2050",WNT,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2050 Electricity Use - INTERMEDIATE",r.TL,t.TL;
 loop(SPRFALL, put UseByTechnology.L("2050",SPRFALL,t,"ELC",r));
 );
put / /;

loop((t,r),
 put / "Year 2050 Electricity Use - SUMMER",r.TL,t.TL;
 loop(SUMM, put UseByTechnology.L("2050",SUMM,t,"ELC",r));
 );
put / /;

loop((r,s),
 put / "Total Storage Capacity",r.TL,s.TL;
 loop(y, put AccumulatedStorageCapacity.L(y,s,r));
);
put / /;

loop((r,s),
 put / "New Storage Capacity",r.TL,s.TL;
 loop(y, put NewStorageCapacity.L(y,s,r));
);
put / /;


loop((s,r),
 put / "Year 2020 Storage Levels - WINTER",r.TL,s.TL;
 loop(WNT, put StorageLevel.L(s,"2020",WNT,r));
 );
put / /;

loop((s,r),
 put / "Year 2020 Storage Levels - INTERMEDIATE",r.TL,s.TL;
 loop(SPRFALL, put StorageLevel.L(s,"2020",SPRFALL,r));
 );
put / /;

loop((s,r),
 put / "Year 2020 Storage Levels - SUMMER",r.TL,s.TL;
 loop(SUMM, put StorageLevel.L(s,"2020",SUMM,r));
 );
put / /;


loop((s,r),
 put / "Year 2050 Storage Levels - WINTER",r.TL,s.TL;
 loop(WNT, put StorageLevel.L(s,"2050",WNT,r));
 );
put / /;

loop((s,r),
 put / "Year 2050 Storage Levels - INTERMEDIATE",r.TL,s.TL;
 loop(SPRFALL, put StorageLevel.L(s,"2050",SPRFALL,r));
 );
put / /;

loop((s,r),
 put / "Year 2050 Storage Levels - SUMMER",r.TL,s.TL;
 loop(SUMM, put StorageLevel.L(s,"2050",SUMM,r));
 );
put / /;





put / "Objective Value", z.L;
put / /;

putclose;






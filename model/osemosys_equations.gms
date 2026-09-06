* Benjamin D. Leibowicz
* Graduate Program in Operations Research and Industrial Engineering
* The University of Texas at Austin

* OSeMOSYS model equations

* ##### Objective Function #####

*minimize cost: sum(YEAR,TECHNOLOGY, STORAGE, REGION) TotalDiscountedCost[y,t,r];
free variable z;
equation cost;
cost.. z =e= sum((y,t,r), TotalDiscountedCost(y,t,r)) + sum((y,r),DiscountedDemandResponseAnnualCost(y,r)) + sum((y,s,r), TotalDiscountedStorageCost(y,s,r));

* ##### Constraints #####

*:SpecifiedAnnualDemand[y,f,r]<>0
*s.t. EQ_SpecifiedDemand1(YEAR,TIMESLICE,FUEL,REGION): SpecifiedAnnualDemand[y,f,r]*SpecifiedDemandProfile[y,l,f,r] / YearSplit[y,l]=RateOfDemand[y,l,f,r];
equation EQ_SpecifiedDemand1(YEAR,TIMESLICE,FUEL,REGION);
 EQ_SpecifiedDemand1(y,l,f,r).. (SpecifiedAnnualDemand(r,f,y)*SpecifiedDemandProfile(r,f,l,y)-sum(d,TagFuelWithDemandResponseCapability(f,d)*DemandResponseLevel(y,d,f,l,r)) ) / YearSplit(l,y) =e=
RateOfDemand(y,l,f,r);

* ##### Storage #####

*s.t. S1_StorageCharge(STORAGE,YEAR,TIMESLICE,REGION): sum(TECHNOLOGY,MODE_OF_OPERATION) RateOfActivity[y,l,t,m,r] * TechnologyToStorage[t,m,s,r] * YearSplit[y,l] = StorageCharge[s,y,l,r];
equation S1_StorageCharge(STORAGE,YEAR,TIMESLICE,REGION);
 S1_StorageCharge(s,y,l,r).. sum((t,m), (RateOfActivity(y,l,t,m,r) * TechnologyToStorage(r,t,s,m))) * YearSplit(l,y) =e=
StorageCharge(s,y,l,r);
*s.t. S2_StorageDischarge(STORAGE,YEAR,TIMESLICE,REGION): sum(TECHNOLOGY,MODE_OF_OPERATION) RateOfActivity[y,l,t,m,r] * TechnologyFromStorage[t,m,s,r] * YearSplit[y,l] = StorageDischarge[s,y,l,r];
equation S2_StorageDischarge(STORAGE,YEAR,TIMESLICE,REGION);
 S2_StorageDischarge(s,y,l,r).. sum((t,m), (RateOfActivity(y,l,t,m,r) * TechnologyFromStorage(r,t,s,m))) * YearSplit(l,y) =e=
StorageDischarge(s,y,l,r);
*s.t. S3_NetStorageCharge(STORAGE,YEAR,TIMESLICE,REGION): NetStorageCharge[s,y,l,r] = StorageCharge[s,y,l,r] - StorageDischarge[s,y,l,r];
equation S3_NetStorageCharge(STORAGE,YEAR,TIMESLICE,REGION);
 S3_NetStorageCharge(s,y,l,r).. NetStorageCharge(s,y,l,r) =e= StorageCharge(s,y,l,r) - StorageDischarge(s,y,l,r);
*s.t S4_StorageLevel(STORAGE,YEAR,TIMESLICE,REGION);
equation StorageLevelCalculationWNT(STORAGE,YEAR,WNT,REGION);
 StorageLevelCalculationWNT(s,y,WNT,r).. StorageLevel(s,y,WNT,r) =e= NetStorageCharge(s,y,WNT,r) + StorageLevel(s,y,WNT--1,r);
equation StorageLevelCalculationSPRFALL(STORAGE,YEAR,SPRFALL,REGION);
 StorageLevelCalculationSPRFALL(s,y,SPRFALL,r).. StorageLevel(s,y,SPRFALL,r) =e= NetStorageCharge(s,y,SPRFALL,r) + StorageLevel(s,y,SPRFALL--1,r);
equation StorageLevelCalculationSUMM(STORAGE,YEAR,SUMM,REGION);
 StorageLevelCalculationSUMM(s,y,SUMM,r).. StorageLevel(s,y,SUMM,r) =e= NetStorageCharge(s,y,SUMM,r) + StorageLevel(s,y,SUMM--1,r);

*s.t. S5_StorageLowerLimit(STORAGE,YEAR,TIMESLICE,REGION): StorageLevel[s,y,l,r] >= StorageLowerLimit[y,s,r];
equation S5_StorageLowerLimit(STORAGE,YEAR,TIMESLICE,REGION);
 S5_StorageLowerLimit(s,y,l,r).. StorageLevel(s,y,l,r) / DaysInSeason(l) =g= StorageLowerLimit(y,s,r);
*s.t. S6_StorageUpperLimit(STORAGE,YEAR,TIMESLICE,REGION): StorageLevel(s,y,l,r) <= StorageUpperLimit[s,y,r];
equation S6_StorageUpperLimit(STORAGE,YEAR,TIMESLICE,REGION);
 S6_StorageUpperLimit(s,y,l,r).. StorageLevel(s,y,l,r) / DaysInSeason(l) =l= StorageUpperLimit(y,s,r);

*s.t. SI1_StorageUpperLimit{r in REGION, s in STORAGE, y in YEAR}: AccumulatedNewStorageCapacity[r,s,y]+ResidualStorageCapacity[r,s,y] = StorageUpperLimit[r,s,y];
equation SI1_StorageUpperLimit(YEAR,STORAGE,REGION);
 SI1_StorageUpperLimit(y,s,r).. AccumulatedStorageCapacity(y,s,r) + ResidualStorageCapacity(y,s,r) =e= StorageUpperLimit(y,s,r);

*s.t. SI2_StorageLowerLimit{r in REGION, s in STORAGE, y in YEAR}: MinStorageCharge[r,s,y]*StorageUpperLimit[r,s,y] = StorageLowerLimit[r,s,y];
equation SI2_StorageLowerLimit(YEAR,STORAGE,REGION);
 SI2_StorageLowerLimit(y,s,r).. MinStorageCharge(s,y,r) * StorageUpperLimit(y,s,r) =e= StorageLowerLimit(y,s,r);

*s.t. SI3_TotalNewStorage{r in REGION, s in STORAGE, y in YEAR}: sum{yy in YEAR: y-yy < OperationalLifeStorage[r,s] && y-yy>=0} NewStorageCapacity[r,s,yy]=AccumulatedNewStorageCapacity[r,s,y];
equation SI3_TotalNewStorage(YEAR,STORAGE,REGION);
 SI3_TotalNewStorage(y,s,r).. AccumulatedStorageCapacity(y,s,r) =e= sum(yy$((YearVal(y)-YearVal(yy) < OperationalStorageLife(r,s))
AND (YearVal(y)-YearVal(yy) >= 0)), NewStorageCapacity(yy,s,r));

*s.t. SI4_UndiscountedCapitalInvestmentStorage{r in REGION, s in STORAGE, y in YEAR}: CapitalCostStorage[r,s,y] * NewStorageCapacity[r,s,y] = CapitalInvestmentStorage[r,s,y];
equation SI4_UndiscountedCapitalInvestmentStorage(YEAR,STORAGE,REGION);
 SI4_UndiscountedCapitalInvestmentStorage(y,s,r).. CapitalCostStorage(y,s,r) * NewStorageCapacity(y,s,r) =e= CapitalInvestmentStorage(y,s,r);

*s.t. SI5_DiscountingCapitalInvestmentStorage{r in REGION, s in STORAGE, y in YEAR}: CapitalInvestmentStorage[r,s,y]/((1+DiscountRate[r])^(y-min{yy in YEAR} min(yy))) = DiscountedCapitalInvestmentStorage[r,s,y];
equation SI5_DiscountingCapitalInvestmentStorage(YEAR,STORAGE,REGION);
 SI5_DiscountingCapitalInvestmentStorage(y,s,r).. CapitalInvestmentStorage(y,s,r)/((1+DiscountRateStorage(r,s))**(YearVal(y)-StartYear)) =e=
DiscountedCapitalInvestmentStorage(y,s,r);

*s.t. SI6_SalvageValueStorageAtEndOfPeriod1{r in REGION, s in STORAGE, y in YEAR: (y+OperationalLifeStorage[r,s]-1) <= (max{yy in YEAR} max(yy))}: 0 = SalvageValueStorage[r,s,y];
equation SI6_SalvageValueStorageAtEndOfPeriod1(YEAR,STORAGE,REGION);
SI6_SalvageValueStorageAtEndOfPeriod1(y,s,r)$((YearVal(y) + OperationalStorageLife(r,s)-1 > smax(yy, YearVal(yy))) and (DiscountRateStorage(r,s)
> 0))..
 SalvageValueStorage(y,s,r) =e= CapitalCostStorage(y,s,r)*NewStorageCapacity(y,s,r)*(1-(((1+DiscountRateStorage(r,s))**(smax(yy, YearVal(yy)) -
YearVal(y)+1) -1)
/((1+DiscountRateStorage(r,s))**OperationalStorageLife(r,s)-1)));

*s.t. SI7_SalvageValueStorageAtEndOfPeriod2{r in REGION, s in STORAGE, y in YEAR: (DepreciationMethod[r]=1 && (y+OperationalLifeStorage[r,s]-1) > (max{yy in YEAR} max(yy)) && DiscountRate[r]=0) || (DepreciationMethod[r]=2 && (y+OperationalLifeStorage[r,s]-1) > (max{yy in YEAR} max(yy)))}: CapitalInvestmentStorage[r,s,y]*(1-(max{yy in YEAR} max(yy) - y+1)/OperationalLifeStorage[r,s]) = SalvageValueStorage[r,s,y];
equation SI7_SalvageValueStorageAtEndOfPeriod2(YEAR,STORAGE,REGION);
 SI7_SalvageValueStorageAtEndOfPeriod2(y,s,r)$((YearVal(y) + OperationalStorageLife(r,s)-1 > smax(yy, YearVal(yy))) and
(DiscountRateStorage(r,s) = 0))..
 SalvageValueStorage(y,s,r) =e= CapitalCostStorage(y,s,r)*NewStorageCapacity(y,s,r)*(1-smax(yy, YearVal(yy))- YearVal(y)+1)/OperationalStorageLife(r,s);

*s.t. SI8_SalvageValueStorageAtEndOfPeriod3{r in REGION, s in STORAGE, y in YEAR: DepreciationMethod[r]=1 && (y+OperationalLifeStorage[r,s]-1) > (max{yy in YEAR} max(yy)) && DiscountRate[r]>0}: CapitalInvestmentStorage[r,s,y]*(1-(((1+DiscountRate[r])^(max{yy in YEAR} max(yy) - y+1)-1)/((1+DiscountRate[r])^OperationalLifeStorage[r,s]-1))) = SalvageValueStorage[r,s,y];
equation SI8_SalvageValueStorageAtEndOfPeriod3(YEAR,STORAGE,REGION);
 SI8_SalvageValueStorageAtEndOfPeriod3(y,s,r)$(YearVal(y) + OperationalStorageLife(r,s)-1 <= smax(yy, YearVal(yy)))..
 SalvageValueStorage(y,s,r) =e= 0;

*s.t. SI9_SalvageValueStorageDiscountedToStartYear{r in REGION, s in STORAGE, y in YEAR}: SalvageValueStorage[r,s,y]/((1+DiscountRate[r])^(max{yy in YEAR} max(yy)-min{yy in YEAR} min(yy)+1)) = DiscountedSalvageValueStorage[r,s,y];
equation SI9_SalvageValueStorageDiscountedToStartYear(YEAR,STORAGE,REGION);
 SI9_SalvageValueStorageDiscountedToStartYear(y,s,r)..
 DiscountedSalvageValueStorage(y,s,r) =e= SalvageValueStorage(y,s,r)/((1+DiscountRateStorage(r,s))**(1+smax(yy, YearVal(yy)) - smin(yy,
YearVal(yy))));

*s.t. SI10_TotalDiscountedCostByStorage{r in REGION, s in STORAGE, y in YEAR}: DiscountedCapitalInvestmentStorage[r,s,y]-DiscountedSalvageValueStorage[r,s,y] = TotalDiscountedStorageCost[r,s,y];
equation SI10_TotalDiscountedCostByStorage(YEAR,STORAGE,REGION);
 SI10_TotalDiscountedCostByStorage(y,s,r).. TotalDiscountedStorageCost(y,s,r) =e= DiscountedCapitalInvestmentStorage(y,s,r) - DiscountedSalvageValueStorage(y,s,r);

* Limit battery storage to address diurnal variation only
equation S7_DiurnalStorage(STORAGE,YEAR,SEASON,REGION);
 S7_DiurnalStorage(s,y,ls,r).. sum(l, NetStorageCharge(s,y,l,r)*TimeSliceInSeason(l,ls)) =e= 0;

equation SI11_CapacityGrowthRateConstraintStorage(YEAR,STORAGE,REGION);
 SI11_CapacityGrowthRateConstraintStorage(y,s,r)$(ord(y) gt 1 and MaxCapacityGrowthRateStorage(r,s) < 1).. NewStorageCapacity(y,s,r) =l=
SUM(yy$(ord(yy) eq ord(y)-1), StorageUpperLimit(yy,s,r))*MaxCapacityGrowthRateStorage(r,s) + StartUpValueStorage(s);

* ##### Capacity Adequacy A #####

*s.t. CBa1_TotalNewCapacity{y in YEAR, t in TECHNOLOGY, r in REGION}:AccumulatedNewCapacity[y,t,r] = sum{yy in YEAR: y-yy < OperationalLife[t,r] && y-yy>=0} NewCapacity[yy,t,r];
equation CBa1_TotalNewCapacity(YEAR,TECHNOLOGY,REGION);
 CBa1_TotalNewCapacity(y,t,r).. AccumulatedNewCapacity(y,t,r) =e= sum(yy$((YearVal(y)-YearVal(yy) < OperationalLife(r,t))
AND (YearVal(y)-YearVal(yy) >= 0)), NewCapacity(yy,t,r));
*s.t. CBa2_TotalAnnualCapacity(YEAR,TECHNOLOGY,REGION): AccumulatedNewCapacity[y,t,r]+ ResidualCapacity[y,t,r] = TotalCapacityAnnual[y,t,r];
equation CBa2_TotalAnnualCapacity(YEAR,TECHNOLOGY,REGION);
 CBa2_TotalAnnualCapacity(y,t,r).. AccumulatedNewCapacity(y,t,r)+ ResidualCapacity(r,t,y) =e= TotalCapacityAnnual(y,t,r);
*s.t. CBa3_TotalActivityOfEachTechnology(YEAR,TECHNOLOGY,TIMESLICE,REGION): sum(MODE_OF_OPERATION) RateOfActivity[y,l,t,m,r] = RateOfTotalActivity[y,l,t,r];
equation CBa3_TotalActivityOfEachTechnology(YEAR,TECHNOLOGY,TIMESLICE,REGION);
 CBa3_TotalActivityOfEachTechnology(y,t,l,r).. sum(m, RateOfActivity(y,l,t,m,r)) =e= RateOfTotalActivity(y,l,t,r);
*s.t. CBa4_Constraint_Capacity(YEAR,TIMESLICE,TECHNOLOGY,REGION: TechWithCapacityNeededToMeetPeakTS[t,r]<>0): RateOfTotalActivity[y,l,t,r] <= TotalCapacityAnnual[y,t,r] * CapacityFactor[y,t,r]*CapacityToActivityUnit[t,r];
equation CBa4_Constraint_Capacity(YEAR,TIMESLICE,TECHNOLOGY,REGION);
 CBa4_Constraint_Capacity(y,l,t,r)$(TechWithCapacityNeededToMeetPeakTS(r,t) <> 0).. RateOfTotalActivity(y,l,t,r) =l=
TotalCapacityAnnual(y,t,r) * CapacityFactor(r,t,l,y)*CapacityToActivityUnit(r,t);
* Note that the PlannedMaintenance equation below ensures that all other technologies have a capacity great enough to at least meet the annual average.

* ##### Capacity Adequacy B #####

*s.t. CBb1_PlannedMaintenance(YEAR,TECHNOLOGY,REGION): sum(TIMESLICE) RateOfTotalActivity[y,l,t,r]*YearSplit[y,l] <= TotalCapacityAnnual[y,t,r]*CapacityFactor[y,t,r]* AvailabilityFactor[y,t,r]*CapacityToActivityUnit[t,r];
equation CBb1_PlannedMaintenance(YEAR,TECHNOLOGY,REGION);
 CBb1_PlannedMaintenance(y,t,r).. sum(l, RateOfTotalActivity(y,l,t,r)*YearSplit(l,y)) =l=
sum(l, TotalCapacityAnnual(y,t,r)*CapacityFactor(r,t,l,y)* AvailabilityFactor(r,t,y)*CapacityToActivityUnit(r,t));

* ##### Energy Balance A #####

*s.t. EBa1_RateOfFuelProduction1(YEAR,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,REGION): RateOfActivity[y,l,t,m,r]*OutputActivityRatio[y,t,f,m,r] = RateOfProductionByTechnologyByMode[y,l,t,m,f,r];
equation EBa1_RateOfFuelProduction1(YEAR,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,REGION);
 EBa1_RateOfFuelProduction1(y,l,f,t,m,r).. RateOfActivity(y,l,t,m,r)*OutputActivityRatio(r,t,f,m,y) =e=
RateOfProductionByTechnologyByMode(y,l,t,m,f,r);
*s.t. EBa2_RateOfFuelProduction2(YEAR,TIMESLICE,FUEL,TECHNOLOGY,REGION): sum(MODE_OF_OPERATION) RateOfProductionByTechnologyByMode[y,l,t,m,f,r] = RateOfProductionByTechnology[y,l,t,f,r];
equation EBa2_RateOfFuelProduction2(YEAR,TIMESLICE,FUEL,TECHNOLOGY,REGION);
 EBa2_RateOfFuelProduction2(y,l,f,t,r).. sum(m, RateOfProductionByTechnologyByMode(y,l,t,m,f,r)) =e=
RateOfProductionByTechnology(y,l,t,f,r);
*s.t. EBa3_RateOfFuelProduction3(YEAR,TIMESLICE,FUEL,REGION): sum(TECHNOLOGY) RateOfProductionByTechnology[y,l,t,f,r] = RateOfProduction[y,l,f,r];
equation EBa3_RateOfFuelProduction3(YEAR,TIMESLICE,FUEL,REGION);
 EBa3_RateOfFuelProduction3(y,l,f,r).. sum(t, RateOfProductionByTechnology(y,l,t,f,r)) =e= RateOfProduction(y,l,f,r);
*s.t. EBa4_RateOfFuelUse1(YEAR,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,REGION): RateOfActivity[y,l,t,m,r]*InputActivityRatio[y,t,f,m,r] = RateOfUseByTechnologyByMode[y,l,t,m,f,r];
equation EBa4_RateOfFuelUse1(YEAR,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,REGION);
 EBa4_RateOfFuelUse1(y,l,f,t,m,r).. RateOfActivity(y,l,t,m,r)*InputActivityRatio(r,t,f,m,y) =e= RateOfUseByTechnologyByMode(y,l,t,m,f,r);
*s.t. EBa5_RateOfFuelUse2(YEAR,TIMESLICE,FUEL,TECHNOLOGY,REGION): sum(MODE_OF_OPERATION) RateOfUseByTechnologyByMode[y,l,t,m,f,r] = RateOfUseByTechnology[y,l,t,f,r];
equation EBa5_RateOfFuelUse2(YEAR,TIMESLICE,FUEL,TECHNOLOGY,REGION);
 EBa5_RateOfFuelUse2(y,l,f,t,r).. sum(m, RateOfUseByTechnologyByMode(y,l,t,m,f,r)) =e= RateOfUseByTechnology(y,l,t,f,r);

*s.t. EBa6_RateOfFuelUse3(YEAR,TIMESLICE,FUEL,REGION): sum(TECHNOLOGY) RateOfUseByTechnology[y,l,t,f,r] = RateOfUse[y,l,f,r];
equation EBa6_RateOfFuelUse3(YEAR,TIMESLICE,FUEL,REGION);
 EBa6_RateOfFuelUse3(y,l,f,r).. sum(t, RateOfUseByTechnology(y,l,t,f,r)) =e= RateOfUse(y,l,f,r);

*s.t. EBa7_EnergyBalanceEachTS1(YEAR,TIMESLICE,FUEL,REGION): RateOfProduction[y,l,f,r]*YearSplit[y,l] = Production[y,l,f,r];
equation EBa7_EnergyBalanceEachTS1(YEAR,TIMESLICE,FUEL,REGION);
 EBa7_EnergyBalanceEachTS1(y,l,f,r).. RateOfProduction(y,l,f,r)*YearSplit(l,y) =e= Production(y,l,f,r);
*s.t. EBa8_EnergyBalanceEachTS2(YEAR,TIMESLICE,FUEL,REGION): RateOfUse[y,l,f,r]*YearSplit[y,l] = Use[y,l,f,r];
equation EBa8_EnergyBalanceEachTS2(YEAR,TIMESLICE,FUEL,REGION);
 EBa8_EnergyBalanceEachTS2(y,l,f,r).. RateOfUse(y,l,f,r)*YearSplit(l,y) =e= Use(y,l,f,r);
*s.t. EBa9_EnergyBalanceEachTS3(YEAR,TIMESLICE,FUEL,REGION): RateOfDemand[y,l,f,r]*YearSplit[y,l] = Demand[y,l,f,r];
equation EBa9_EnergyBalanceEachTS3(YEAR,TIMESLICE,FUEL,REGION);
 EBa9_EnergyBalanceEachTS3(y,l,f,r).. RateOfDemand(y,l,f,r)*YearSplit(l,y) =e= Demand(y,l,f,r);
*s.t. EBa10_EnergyBalanceEachTS4(YEAR,TIMESLICE,FUEL,REGION): Production[y,l,f,r] >= Demand[y,l,f,r] + Use[y,l,f,r];
equation EBa10_EnergyBalanceEachTS4(YEAR,TIMESLICE,FUEL,REGION);
 EBa10_EnergyBalanceEachTS4(y,l,f,r).. Production(y,l,f,r) =g= Demand(y,l,f,r) + Use(y,l,f,r);

*For each day,
*equation EBa11_EnergyBalanceDailyWNT(y,f,r);
*EBa11_EnergyBalanceDailyWNT(y,f,r).. sum(WNT, Production(y,WNT,f,r)) =g= sum(WNT,Demand(y,WNT,f,r)) + sum((WNT,t),RateOfUseByTechnology(y,WNT,t,f,r)*YearSplit(WNT,y));

*equation EBa12_EnergyBalanceDailySPRFALL(y,f,r);
*EBa12_EnergyBalanceDailySPRFALL(y,f,r).. sum(SPRFALL, Production(y,SPRFALL,f,r)) =g= sum(SPRFALL,Demand(y,SPRFALL,f,r)) + sum((SPRFALL,t),RateOfUseByTechnology(y,SPRFALL,t,f,r)*YearSplit(SPRFALL,y));

*equation EBa13_EnergyBalanceDailySUMM(y,f,r);
*EBa13_EnergyBalanceDailySUMM(y,f,r).. sum(SUMM, Production(y,SUMM,f,r)) =g= sum(SUMM,Demand(y,SUMM,f,r)) + sum((SUMM,t),RateOfUseByTechnology(y,SUMM,t,f,r)*YearSplit(SUMM,y));



* ##### Energy Balance B #####

*s.t. EBb1_EnergyBalanceEachYear1(YEAR,FUEL,REGION): sum(TIMESLICE) Production[y,l,f,r] = ProductionAnnual[y,f,r];
equation EBb1_EnergyBalanceEachYear1(YEAR,FUEL,REGION);
 EBb1_EnergyBalanceEachYear1(y,f,r).. sum(l, Production(y,l,f,r)) =e= ProductionAnnual(y,f,r);
*s.t. EBb2_EnergyBalanceEachYear2(YEAR,FUEL,REGION): sum(TIMESLICE) Use[y,l,f,r] = UseAnnual[y,f,r];
equation EBb2_EnergyBalanceEachYear2(YEAR,FUEL,REGION);
 EBb2_EnergyBalanceEachYear2(y,f,r).. sum(l, Use(y,l,f,r)) =e= UseAnnual(y,f,r);
*s.t. EBb3_EnergyBalanceEachYear3(YEAR,FUEL,REGION): ProductionAnnual[y,f,r] >= UseAnnual[y,f,r] + AccumulatedAnnualDemand[y,f,r];
equation EBb3_EnergyBalanceEachYear3(YEAR,FUEL,REGION);
 EBb3_EnergyBalanceEachYear3(y,f,r).. ProductionAnnual(y,f,r) =g= UseAnnual(y,f,r) + AccumulatedAnnualDemand(r,f,y);

* ##### Accounting Technology Production/Use #####

*s.t. Acc1_FuelProductionByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION): RateOfProductionByTechnology[y,l,t,f,r] * YearSplit[y,l] = ProductionByTechnology[y,l,t,f,r];
equation Acc1_FuelProductionByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);
 Acc1_FuelProductionByTechnology(y,l,t,f,r).. RateOfProductionByTechnology(y,l,t,f,r) * YearSplit(l,y) =e=
ProductionByTechnology(y,l,t,f,r);
*s.t. Acc2_FuelUseByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION): RateOfUseByTechnology[y,l,t,f,r] * YearSplit[y,l] = UseByTechnology[y,l,t,f,r];
equation Acc2_FuelUseByTechnology(YEAR,TIMESLICE,TECHNOLOGY,FUEL,REGION);
 Acc2_FuelUseByTechnology(y,l,t,f,r).. RateOfUseByTechnology(y,l,t,f,r) * YearSplit(l,y) =e= UseByTechnology(y,l,t,f,r);
*s.t. Acc3_AverageAnnualRateOfActivity(YEAR,TECHNOLOGY,MODE_OF_OPERATION,REGION): sum(TIMESLICE) RateOfActivity[y,l,t,m,r]*YearSplit[y,l] = TotalAnnualTechnologyActivityByMode[y,t,m,r];
equation Acc3_AverageAnnualRateOfActivity(YEAR,TECHNOLOGY,MODE_OF_OPERATION,REGION);
 Acc3_AverageAnnualRateOfActivity(y,t,m,r).. sum(l, RateOfActivity(y,l,t,m,r)*YearSplit(l,y)) =e=
TotalAnnualTechnologyActivityByMode(y,t,m,r);
*s.t. Acc3_ModelPeriodCostByRegion(REGION):sum(YEAR,TECHNOLOGY)TotalDiscountedCost[y,t,r]=ModelPeriodCostByRegion[r];
equation Acc3_ModelPeriodCostByRegion(REGION);
 Acc3_ModelPeriodCostByRegion(r)..sum((y,t), TotalDiscountedCost(y,t,r)) =e= ModelPeriodCostByRegion(r);

* ##### Captial Costs #####

*s.t. CC1_UndiscountedCapitalInvestment(YEAR,TECHNOLOGY,REGION): CapitalCost[y,t,r] * NewCapacity[y,t,r] = CapitalInvestment[y,t,r];
equation CC1_UndiscountedCapitalInvestment(YEAR,TECHNOLOGY,REGION);
 CC1_UndiscountedCapitalInvestment(y,t,r).. CapitalCost(r,t,y) * NewCapacity(y,t,r) =e= CapitalInvestment(y,t,r);
*s.t. CC2_DiscountingCapitalInvestmenta(YEAR,TECHNOLOGY,REGION): CapitalInvestment[y,t,r]/((1+DiscountRate[t,r])^(yStartYear)) = DiscountedCapitalInvestment[y,t,r];
equation CC2_DiscountingCapitalInvestmenta(YEAR,TECHNOLOGY,REGION);
 CC2_DiscountingCapitalInvestmenta(y,t,r).. CapitalInvestment(y,t,r)/((1+DiscountRate(r,t))**(YearVal(y)-StartYear)) =e=
DiscountedCapitalInvestment(y,t,r);

* ##### Salvage Value #####

*s.t. SV1_SalvageValueAtEndOfPeriod1(YEAR,TECHNOLOGY,REGION: (y + OperationalLife[t,r]-1) > (max(yy in YEAR) max(yy)) && DiscountRate[t,r]>0): SalvageValue[y,t,r] = CapitalCost[y,t,r]*NewCapacity[y,t,r]*(1-(((1+DiscountRate[t,r])^(max(yy in YEAR) max(yy) - y+1)-1)/((1+DiscountRate[t,r])^OperationalLife[t,r]-1)));
equation SV1_SalvageValueAtEndOfPeriod1(YEAR,TECHNOLOGY,REGION);
 SV1_SalvageValueAtEndOfPeriod1(y,t,r)$((YearVal(y) + OperationalLife(r,t)-1 > smax(yy, YearVal(yy))) and (DiscountRate(r,t)
> 0))..
 SalvageValue(y,t,r) =e= CapitalCost(r,t,y)*NewCapacity(y,t,r)*(1-(((1+DiscountRate(r,t))**(smax(yy, YearVal(yy)) -
YearVal(y)+1) -1)
/((1+DiscountRate(r,t))**OperationalLife(r,t)-1)));
*s.t. SV2_SalvageValueAtEndOfPeriod2(YEAR,TECHNOLOGY,REGION: (y + OperationalLife[t,r]-1) > (max(yy in YEAR) max(yy)) && DiscountRate[t,r]=0): SalvageValue[y,t,r] = CapitalCost[y,t,r]*NewCapacity[y,t,r]*(1-(max(yy in YEAR) max(yy) - y+1)/OperationalLife[t,r]);
equation SV2_SalvageValueAtEndOfPeriod2(YEAR,TECHNOLOGY,REGION);
 SV2_SalvageValueAtEndOfPeriod2(y,t,r)$((YearVal(y) + OperationalLife(r,t)-1 > smax(yy, YearVal(yy))) and
(DiscountRate(r,t) = 0))..
 SalvageValue(y,t,r) =e= CapitalCost(r,t,y)*NewCapacity(y,t,r)*(1-smax(yy, YearVal(yy))- YearVal(y)+1)/OperationalLife(r,t);
*s.t. SV3_SalvageValueAtEndOfPeriod3(YEAR,TECHNOLOGY,REGION: (y + OperationalLife[t,r]-1) <= (max(yy in YEAR) max(yy))): SalvageValue[y,t,r] = 0;
equation SV3_SalvageValueAtEndOfPeriod3(YEAR,TECHNOLOGY,REGION);
 SV3_SalvageValueAtEndOfPeriod3(y,t,r)$(YearVal(y) + OperationalLife(r,t)-1 <= smax(yy, YearVal(yy)))..
 SalvageValue(y,t,r) =e= 0;
*s.t. SV4_SalvageValueDiscountedToStartYear(YEAR,TECHNOLOGY,REGION): DiscountedSalvageValue[y,t,r] = SalvageValue[y,t,r]/((1+DiscountRate[t,r])^(1+max(yy in YEAR) max(yy)-min(yy in YEAR) min(yy)));
equation SV4_SalvageValueDiscToStartYr(YEAR,TECHNOLOGY,REGION);
 SV4_SalvageValueDiscToStartYr(y,t,r)..
 DiscountedSalvageValue(y,t,r) =e= SalvageValue(y,t,r)/((1+DiscountRate(r,t))**(1+smax(yy, YearVal(yy)) - smin(yy,
YearVal(yy))));

* ##### Operating Costs #####

*s.t. OC1_OperatingCostsVariable(YEAR,TIMESLICE,TECHNOLOGY,REGION): sum(MODE_OF_OPERATION) TotalAnnualTechnologyActivityByMode[y,t,m,r]*VariableCost[y,t,m,r] = AnnualVariableOperatingCost[y,t,r];
equation OC1_OperatingCostsVariable(YEAR,TECHNOLOGY,REGION);
 OC1_OperatingCostsVariable(y,t,r).. sum(m, (TotalAnnualTechnologyActivityByMode(y,t,m,r)*VariableCost(r,t,m,y))) =e=
AnnualVariableOperatingCost(y,t,r);
*s.t. OC2_OperatingCostsFixedAnnual(YEAR,TECHNOLOGY,REGION): TotalCapacityAnnual[y,t,r]*FixedCost[y,t,r] = AnnualFixedOperatingCost[y,t,r];
equation OC2_OperatingCostsFixedAnnual(YEAR,TECHNOLOGY,REGION);
 OC2_OperatingCostsFixedAnnual(y,t,r).. TotalCapacityAnnual(y,t,r)*FixedCost(r,t,y) =e= AnnualFixedOperatingCost(y,t,r);
*s.t. OC3_OperatingCostsTotalAnnual(YEAR,TECHNOLOGY,REGION): AnnualFixedOperatingCost[y,t,r]+AnnualVariableOperatingCost[y,t,r] = OperatingCost[y,t,r];
equation OC3_OperatingCostsTotalAnnual(YEAR,TECHNOLOGY,REGION);
 OC3_OperatingCostsTotalAnnual(y,t,r).. AnnualFixedOperatingCost(y,t,r)+AnnualVariableOperatingCost(y,t,r) =e=
OperatingCost(y,t,r);
*s.t. OC4_DiscountedOperatingCostsTotalAnnual{y in YEAR, t in TECHNOLOGY, r in REGION}: OperatingCost[y,t,r]/((1+DiscountRate[t,r])^(y-min{yy in YEAR} min(yy)+0.5)) = DiscountedOperatingCost[y,t,r];
equation OC4_DiscountedOperatingCostsTotalAnnual(YEAR,TECHNOLOGY,REGION);
 OC4_DiscountedOperatingCostsTotalAnnual(y,t,r).. OperatingCost(y,t,r)/((1+DiscountRate(r,t))**(YearVal(y)-smin(yy,
YearVal(yy))+0.5)) =e= DiscountedOperatingCost(y,t,r);

* ##### Total Discounted Costs #####

*s.t. TDC1_TotalDiscountedCostByTechnology(YEAR,TECHNOLOGY,REGION): DiscountedOperatingCost[y,t,r]+DiscountedCapitalInvestment[y,t,r]+DiscountedTechnologyEmissionsPenalty[y,t,r]- DiscountedSalvageValue[y,t,r] = TotalDiscountedCost[y,t,r];
equation TDC1_TotalDiscountedCostByTechnology(YEAR,TECHNOLOGY,REGION);
 TDC1_TotalDiscountedCostByTechnology(y,t,r)..
DiscountedOperatingCost(y,t,r)+DiscountedCapitalInvestment(y,t,r)+DiscountedTechnologyEmissionsPenalty(y,t,r)-
DiscountedSalvageValue(y,t,r) =e= TotalDiscountedCost(y,t,r);

* ##### Total Capacity Constraints #####

*s.t. TCC1_TotalAnnualMaxCapacityConstraint(YEAR,TECHNOLOGY,REGION: TotalAnnualMaxCapacity[y,t,r]<99999 ): TotalCapacityAnnual[y,t,r] <= TotalAnnualMaxCapacity[y,t,r];
equation TCC1_TotalAnnualMaxCapacityConstraint(YEAR,TECHNOLOGY,REGION);
 TCC1_TotalAnnualMaxCapacityConstraint(y,t,r)$(TotalAnnualMaxCapacity(r,t,y) < 99999).. TotalCapacityAnnual(y,t,r) =l=
TotalAnnualMaxCapacity(r,t,y);
*s.t. TCC2_TotalAnnualMinCapacityConstraint(YEAR,TECHNOLOGY,REGION: TotalAnnualMinCapacity[y,t,r]>0): TotalCapacityAnnual[y,t,r] >= TotalAnnualMinCapacity[y,t,r];
equation TCC2_TotalAnnualMinCapacityConstraint(YEAR,TECHNOLOGY,REGION);
 TCC2_TotalAnnualMinCapacityConstraint(y,t,r)$(TotalAnnualMinCapacity(r,t,y)>0).. TotalCapacityAnnual(y,t,r) =g=
TotalAnnualMinCapacity(r,t,y);

* ##### New Capacity Constraints #####

*s.t. NCC1_TotalAnnualMaxNewCapacityConstraint(YEAR,TECHNOLOGY,REGION: TotalAnnualMaxCapacityInvestment[y,t,r]<9999): NewCapacity[y,t,r] <= TotalAnnualMaxCapacityInvestment[y,t,r];
equation NCC1_TotalAnnualMaxNewCapacityConstraint(YEAR,TECHNOLOGY,REGION);
 NCC1_TotalAnnualMaxNewCapacityConstraint(y,t,r)$(TotalAnnualMaxCapacityInvestment(r,t,y) < 9999).. NewCapacity(y,t,r)
=l= TotalAnnualMaxCapacityInvestment(r,t,y);
*s.t. NCC2_TotalAnnualMinNewCapacityConstraint(YEAR,TECHNOLOGY,REGION: TotalAnnualMinCapacityInvestment[y,t,r]>0): NewCapacity[y,t,r] >= TotalAnnualMinCapacityInvestment[y,t,r];
equation NCC2_TotalAnnualMinNewCapacityConstraint(YEAR,TECHNOLOGY,REGION);
 NCC2_TotalAnnualMinNewCapacityConstraint(y,t,r)$(TotalAnnualMinCapacityInvestment(r,t,y) > 0).. NewCapacity(y,t,r) =g=
TotalAnnualMinCapacityInvestment(r,t,y);

* ##### Annual Activity Constraints #####

*s.t. AAC1_TotalAnnualTechnologyActivity(YEAR,TECHNOLOGY,REGION): sum(TIMESLICE) RateOfTotalActivity[y,l,t,r]*YearSplit[y,l] = TotalTechnologyAnnualActivity[y,t,r];
equation AAC1_TotalAnnualTechnologyActivity(YEAR,TECHNOLOGY,REGION);
 AAC1_TotalAnnualTechnologyActivity(y,t,r).. sum(l, (RateOfTotalActivity(y,l,t,r)*YearSplit(l,y))) =e=
TotalTechnologyAnnualActivity(y,t,r);
*s.t. AAC2_TotalAnnualTechnologyActivityUpperLimit(YEAR,TECHNOLOGY,REGION:TotalTechnologyAnnualActivityUpperLimit[y,t,r]<9999): TotalTechnologyAnnualActivity[y,t,r] <= TotalTechnologyAnnualActivityUpperLimit[y,t,r] ;
equation AAC2_TotalAnnualTechnologyActivityUpperLimit(YEAR,TECHNOLOGY,REGION);
 AAC2_TotalAnnualTechnologyActivityUpperLimit(y,t,r)$(TotalTechnologyAnnualActivityUpperLimit(r,t,y) <9999)..
TotalTechnologyAnnualActivity(y,t,r) =l= TotalTechnologyAnnualActivityUpperLimit(r,t,y);
*s.t. AAC3_TotalAnnualTechnologyActivityLowerLimit(YEAR,TECHNOLOGY,REGION: TotalTechnologyAnnualActivityLowerLimit[y,t,r]>0): TotalTechnologyAnnualActivity[y,t,r] >= TotalTechnologyAnnualActivityLowerLimit[y,t,r] ;
equation AAC3_TotalAnnualTechnologyActivityLowerLimit(YEAR,TECHNOLOGY,REGION);
 AAC3_TotalAnnualTechnologyActivityLowerLimit(y,t,r)$(TotalTechnologyAnnualActivityLowerLimit(r,t,y) > 0)..
TotalTechnologyAnnualActivity(y,t,r) =g= TotalTechnologyAnnualActivityLowerLimit(r,t,y);

* ##### Total Activity Constraints #####

*s.t. TAC1_TotalModelHorizenTechnologyActivity(TECHNOLOGY,REGION): sum(YEAR) TotalTechnologyAnnualActivity[y,t,r] = TotalTechnologyModelPeriodActivity[t,r];
equation TAC1_TotalModelHorizenTechnologyActivity(TECHNOLOGY,REGION);
 TAC1_TotalModelHorizenTechnologyActivity(t,r).. sum(y, TotalTechnologyAnnualActivity(y,t,r)) =e=
TotalTechnologyModelPeriodActivity(t,r);
*s.t. TAC2_TotalModelHorizenTechnologyActivityUpperLimit(YEAR,TECHNOLOGY,REGION:TotalTechnologyModelPeriodActivityUpperLimit[t,r]<9999): TotalTechnologyModelPeriodActivity[t,r] <= TotalTechnologyModelPeriodActivityUpperLimit[t,r] ;
equation TAC2_TotalModelHorizenTechnologyActivityUpperLimit(YEAR,TECHNOLOGY,REGION);
 TAC2_TotalModelHorizenTechnologyActivityUpperLimit(y,t,r)$(TotalTechnologyModelPeriodActivityUpperLimit(r,t) < 9999)..
TotalTechnologyModelPeriodActivity(t,r) =l= TotalTechnologyModelPeriodActivityUpperLimit(r,t);
*s.t. TAC3_TotalModelHorizenTechnologyActivityLowerLimit(YEAR,TECHNOLOGY,REGION: TotalTechnologyModelPeriodActivityLowerLimit[t,r]>0): TotalTechnologyModelPeriodActivity[t,r] >= TotalTechnologyModelPeriodActivityLowerLimit[t,r] ;
equation TAC3_TotalModelHorizenTechnologyActivityLowerLimit(YEAR,TECHNOLOGY,REGION);
 TAC3_TotalModelHorizenTechnologyActivityLowerLimit(y,t,r)$(TotalTechnologyModelPeriodActivityLowerLimit(r,t) > 0)..
TotalTechnologyModelPeriodActivity(t,r) =g= TotalTechnologyModelPeriodActivityLowerLimit(r,t);

* ##### Reserve Margin Constraint #####

*s.t. RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units(YEAR,TIMESLICE,REGION): sum (TECHNOLOGY) TotalCapacityAnnual[y,t,r] *ReserveMarginTagTechnology[y,t,r] * CapacityToActivityUnit[t,r] = TotalCapacityInReserveMargin[y,r];
equation RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units(YEAR,TIMESLICE,REGION);
 RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units(y,l,r).. sum (t, (TotalCapacityAnnual(y,t,r) * ReserveMarginTagTechnology(r,t,y) * CapacityToActivityUnit(r,t))) =e= TotalCapacityInReserveMargin(r,y);
*s.t. RM2_ReserveMargin_FuelsIncluded(YEAR,TIMESLICE,REGION): sum (FUEL) RateOfProduction[y,l,f,r] * ReserveMarginTagFuel[y,f,r] = DemandNeedingReserveMargin[y,l,r];
equation RM2_ReserveMargin_FuelsIncluded(YEAR,TIMESLICE,REGION);
 RM2_ReserveMargin_FuelsIncluded(y,l,r).. sum (f, (RateOfProduction(y,l,f,r) * ReserveMarginTagFuel(r,f,y))) =e=
DemandNeedingReserveMargin(y,l,r);
*s.t. RM3_ReserveMargin_Constraint(YEAR,TIMESLICE,REGION): DemandNeedingReserveMargin[y,l,r] * ReserveMargin[y,r] <= TotalCapacityInReserveMargin[y,r];
equation RM3_ReserveMargin_Constraint(YEAR,TIMESLICE,REGION);
 RM3_ReserveMargin_Constraint(y,l,r).. DemandNeedingReserveMargin(y,l,r) * ReserveMargin(r,y) =l=
TotalCapacityInReserveMargin(r,y);

* ##### RE Production Target #####

*s.t. RE1_FuelProductionByTechnologyAnnual(YEAR,TECHNOLOGY,FUEL,REGION): sum(TIMESLICE) ProductionByTechnology[y,l,t,f,r] = ProductionByTechnologyAnnual[y,t,f,r];
equation RE1_FuelProductionByTechnologyAnnual(YEAR,TECHNOLOGY,FUEL,REGION);
 RE1_FuelProductionByTechnologyAnnual(y,t,f,r).. sum(l, ProductionByTechnology(y,l,t,f,r)) =e=
ProductionByTechnologyAnnual(y,t,f,r);
*s.t. RE2_TechIncluded(YEAR,REGION): sum(TECHNOLOGY,FUEL) ProductionByTechnologyAnnual[y,t,f,r]*RETagTechnology[y,t,r] = TotalREProductionAnnual[y,r];
equation RE2_TechIncluded(YEAR,REGION);
 RE2_TechIncluded(y,r).. sum((t,f), (ProductionByTechnologyAnnual(y,t,f,r)*RETagTechnology(r,t,y))) =e=
TotalREProductionAnnual(y,r);
*s.t. RE3_FuelIncluded(YEAR,REGION): sum(TIMESLICE,FUEL) RateOfDemand[y,l,f,r]*YearSplit[y,l]*RETagFuel[y,f,r] = RETotalDemandOfTargetFuelAnnual[y,r];
equation RE3_FuelIncluded(YEAR,REGION);
 RE3_FuelIncluded(y,r).. sum((l,f), (RateOfDemand(y,l,f,r)*YearSplit(l,y)*RETagFuel(r,f,y))) =e=
RETotalDemandOfTargetFuelAnnual(y,r);
*s.t. RE4_EnergyConstraint(YEAR,REGION):REMinProductionTarget[y,r]*RETotalDemandOfTargetFuelAnnual[y,r] <= TotalREProductionAnnual[y,r];
equation RE4_EnergyConstraint(YEAR,REGION);
 RE4_EnergyConstraint(y,r).. REMinProductionTarget(r,y)*RETotalDemandOfTargetFuelAnnual(y,r) =l=
TotalREProductionAnnual(y,r);
*s.t. RE5_FuelUseByTechnologyAnnual(YEAR,TECHNOLOGY,FUEL,REGION): sum(TIMESLICE) RateOfUseByTechnology[y,l,t,f,r]*YearSplit[y,l] = UseByTechnologyAnnual[y,t,f,r];
equation RE5_FuelUseByTechnologyAnnual(YEAR,TECHNOLOGY,FUEL,REGION);
 RE5_FuelUseByTechnologyAnnual(y,t,f,r).. sum(l, (RateOfUseByTechnology(y,l,t,f,r)*YearSplit(l,y))) =e=
UseByTechnologyAnnual(y,t,f,r);

* ##### Emissions Accounting #####

*s.t. E1_AnnualEmissionProductionByMode(YEAR,TECHNOLOGY,EMISSION,MODE_OF_OPERATION,REGION:EmissionActivityRatio[y,t,e,m,r]<>0):EmissionActivityRatio[y,t,e,m,r]*TotalAnnualTechnologyActivityByMode[y,t,m,r]=AnnualTechnologyEmissionByMode[y,t,e,m,r];
equation E1_AnnualEmissionProductionByMode(YEAR,TECHNOLOGY,EMISSION,MODE_OF_OPERATION,REGION);
* E1_AnnualEmissionProductionByMode(y,t,e,m,r)$(EmissionActivityRatio(r,t,e,m,y) <> 0)..EmissionActivityRatio(r,t,e,m,y)*TotalAnnualTechnologyActivityByMode(y,t,m,r) =e=AnnualTechnologyEmissionByMode(y,t,e,m,r);
 E1_AnnualEmissionProductionByMode(y,t,e,m,r)..
EmissionActivityRatio(r,t,e,m,y)*TotalAnnualTechnologyActivityByMode(y,t,m,r) =e=
AnnualTechnologyEmissionByMode(y,t,e,m,r);
*s.t. E2_AnnualEmissionProduction(YEAR,TECHNOLOGY,EMISSION,REGION): sum(MODE_OF_OPERATION) AnnualTechnologyEmissionByMode[y,t,e,m,r] = AnnualTechnologyEmission[y,t,e,r];
equation E2_AnnualEmissionProduction(YEAR,TECHNOLOGY,EMISSION,REGION);
 E2_AnnualEmissionProduction(y,t,e,r).. sum(m, AnnualTechnologyEmissionByMode(y,t,e,m,r)) =e=
AnnualTechnologyEmission(y,t,e,r);
*s.t. E3_EmissionsPenaltyByTechAndEmission(YEAR,TECHNOLOGY,EMISSION,REGION): AnnualTechnologyEmission[y,t,e,r]*EmissionsPenalty[y,e,r] = AnnualTechnologyEmissionPenaltyByEmission[y,t,e,r];
equation E3_EmissionsPenaltyByTechAndEmission(YEAR,TECHNOLOGY,EMISSION,REGION);
 E3_EmissionsPenaltyByTechAndEmission(y,t,e,r).. AnnualTechnologyEmission(y,t,e,r)*EmissionsPenalty(r,e,y) =e=
AnnualTechnologyEmissionPenaltyByEmission(y,t,e,r);
*s.t. E4_EmissionsPenaltyByTechnology(YEAR,TECHNOLOGY,REGION): sum(EMISSION) AnnualTechnologyEmissionPenaltyByEmission[y,t,e,r] = AnnualTechnologyEmissionsPenalty[y,t,r];
equation E4_EmissionsPenaltyByTechnology(YEAR,TECHNOLOGY,REGION);
 E4_EmissionsPenaltyByTechnology(y,t,r).. sum(e, AnnualTechnologyEmissionPenaltyByEmission(y,t,e,r)) =e=
AnnualTechnologyEmissionsPenalty(y,t,r);
*s.t. E5_DiscountedEmissionsPenaltyByTechnology(YEAR,TECHNOLOGY,REGION): AnnualTechnologyEmissionsPenalty[y,t,r]/((1+DiscountRate[t,r])^(y-min(yy in YEAR) min(yy)+0.5)) = DiscountedTechnologyEmissionsPenalty[y,t,r];
equation E5_DiscountedEmissionsPenaltyByTechnology(YEAR,TECHNOLOGY,REGION);
 E5_DiscountedEmissionsPenaltyByTechnology(y,t,r)..
AnnualTechnologyEmissionsPenalty(y,t,r)/((1+DiscountRate(r,t))**(YearVal(y)-smin(yy, YearVal(yy))+0.5)) =e=
DiscountedTechnologyEmissionsPenalty(y,t,r);
*s.t. E6_EmissionsAccounting1(YEAR,EMISSION,REGION): sum(TECHNOLOGY) AnnualTechnologyEmission[y,t,e,r] = AnnualEmissions[y,e,r];
equation E6_EmissionsAccounting1(YEAR,EMISSION,REGION);
 E6_EmissionsAccounting1(y,e,r).. sum(t, AnnualTechnologyEmission(y,t,e,r)) =e= AnnualEmissions(y,e,r);
*s.t. E7_EmissionsAccounting2(EMISSION,REGION): sum(YEAR) AnnualEmissions[y,e,r] = ModelPeriodEmissions[e,r]-ModelPeriodExogenousEmission[e,r];
equation E7_EmissionsAccounting2(EMISSION,REGION);
 E7_EmissionsAccounting2(e,r).. sum(y, AnnualEmissions(y,e,r)) =e= ModelPeriodEmissions(e,r)-
ModelPeriodExogenousEmission(r,e);
*s.t. E8_AnnualEmissionsLimit(YEAR,EMISSION,REGION): AnnualEmissions[y,e,r]+AnnualExogenousEmission[y,e,r] <= AnnualEmissionLimit[y,e,r];
equation E8_AnnualEmissionsLimit(YEAR,EMISSION,REGION);
 E8_AnnualEmissionsLimit(y,e,r).. AnnualEmissions(y,e,r)+AnnualExogenousEmission(r,e,y) =l= AnnualEmissionLimit(r,e,y);
*s.t. E9_ModelPeriodEmissionsLimit(EMISSION,REGION): ModelPeriodEmissions[e,r] <= ModelPeriodEmissionLimit[e,r] ;
*equation E9_ModelPeriodEmissionsLimit(EMISSION,REGION);
* E9_ModelPeriodEmissionsLimit(e,r).. ModelPeriodEmissions(e,r) =l= ModelPeriodEmissionLimit(r,e);

* ##### Additional Equations Added for This Study #####

* Constrain the annual percentage growth of capacity
equation NCC3_CapacityGrowthRateConstraint(YEAR,TECHNOLOGY,REGION);
 NCC3_CapacityGrowthRateConstraint(y,t,r)$(ord(y) gt 1 and MaxCapacityGrowthRate(r,t) < 1).. NewCapacity(y,t,r) =l=
SUM(yy$(ord(yy) eq ord(y)-1), TotalCapacityAnnual(yy,t,r))*MaxCapacityGrowthRate(r,t) + StartUpValue(t);

equation NoCapacity2015(NoNewCap2015,REGION);
 NoCapacity2015(NoNewCap2015,r).. NewCapacity("2015",NoNewCap2015,r) =e= 0;



* Limit the number of miles vehicles can travel in a year
equation CarMiles(YEAR,PrivTrans,REGION);
 CarMiles(y,PrivTrans,r).. ProductionByTechnologyAnnual(y,PrivTrans,"VMT",r) =l= TotalCapacityAnnual(y,PrivTrans,r) * 15;
equation FleetMiles(YEAR,Fleet,REGION);
 FleetMiles(y,Fleet,r).. ProductionByTechnologyAnnual(y,Fleet,"FMT",r) =l= TotalCapacityAnnual(y,Fleet,r) * 92;
equation PubMiles(YEAR,PubTrans,REGION);
 PubMiles(y,PubTrans,r).. ProductionByTechnologyAnnual(y,PubTrans,"PM",r) =l= TotalCapacityAnnual(y,PubTrans,r) * 15 * 20;


* #### Demand Response ####


*DR1_LevelUpperLimit
equation DR1_LevelUpperLimit(YEAR,DR_TYPE,FUEL,TIMESLICE,REGION);
 DR1_LevelUpperLimit(y,d,f,l,r).. DemandResponseLevel(y,d,f,l,r) =l= DemandResponseMaxLevel(y,d,f,l,r);

*DR2_LevelLowerLimit
equation DR2_LevelLowerLimit(YEAR,DR_TYPE,FUEL,TIMESLICE,REGION);
 DR2_LevelLowerLimit(y,d,f,l,r).. DemandResponseLevel(y,d,f,l,r) =g= DemandResponseMinLevel(y,d,f,l,r);

*DR3_Cost
equation DR3_Cost(YEAR,TIMESLICE,REGION);
 DR3_Cost(y,l,r).. sum((f,d),DemandResponseLevel(y,d,f,l,r)*DemandResponseVarCost(y,d,f,r)) =e= DemandResponseCost(y,l,r)

*DR4_AnnualCost
equation DR4_AnnualCost(YEAR,REGION);
 DR4_AnnualCost(y,r).. DemandResponseAnnualCost(y,r) =e= sum(l,DemandResponseCost(y,l,r));

*DR5_DiscountedAnnualCost
equation DR5_DiscountedAnnualCost(YEAR,REGION);
 DR5_DiscountedAnnualCost(y,r).. DiscountedDemandResponseAnnualCost(y,r) =e= DemandResponseAnnualCost(y,r) / ((1+DemandResponseDiscountRate(r))**(YearVal(y)-StartYear));

* ## Subtract DR Level from Demand - implemented above ##
*equation EQ_SpecifiedDemand1(YEAR,TIMESLICE,FUEL,REGION);
* EQ_SpecifiedDemand1(y,l,f,r).. (SpecifiedAnnualDemand(r,f,y)*SpecifiedDemandProfile(r,f,l,y)-sum(d,TagFuelWithDemandResponseCapability(f,d)*DemandResponseLevel(y,d,f,l,r)) ) / YearSplit(l,y) =e=
*RateOfDemand(y,l,f,r);

* ## Add Total Discounted Costs to Objective - implemented above ##
*equation cost;
*cost.. z =e= sum((y,t,r), TotalDiscountedCost(y,t,r)) + sum((y,r),DiscountedAnnualDemandResponseCost(y,r));


* #### Capital Vintaging ####
*
*equation EBa4_RateOfFuelUse1(YEAR,YEAR,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,REGION);
* EBa4_RateOfFuelUse1(v,y,l,f,t,m,r).. RateOfActivityByVintage(v,y,l,t,m,r)*InputActivityRatio(r,t,f,m,v) =e=
*RateOfUseByTechnologyByModeByVintage(v,y,l,t,m,f,r);

*equation CapVintage1(YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,FUEL,REGION);
*CapVintage1(y,l,t,m,f,r).. sum(v,RateOfUseByTechnologyByModeByVintage(v,y,l,t,m,f,r)) =e= RateOfUseByTechnologyByMode(y,l,t,m,f,r);

*equation CapVintage2(YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,REGION);
*CapVintage2(y,l,t,m,r).. sum(v, RateOfActivityByVintage(v,y,l,t,m,r)) =e= RateOfActivity(y,l,t,m,r);

*equation CapVintage3(YEAR,YEAR,TIMESLICE,TECHNOLOGY,REGION);
*CapVintage3(v,y,l,t,r).. sum(m,RateOfActivityByVintage(v,y,l,t,m,r)) =e= RateOfTotalActivityByVintage(v,y,l,t,r);

*equation CapVintage4a(YEAR,YEAR,TIMESLICE,TECHNOLOGY,REGION);
*CapVintage4a(v,y,l,t,r)$( (TechWithCapacityNeededToMeetPeakTS(r,t) <> 0) AND (ord(y)>1) ).. RateOfTotalActivityByVintage(v,y,l,t,r) =l= NewCapacity(v,t,r)*CapacityFactor(r,t,l,v)*CapacityToActivityUnit(r,t);

*equation CapVintage4b(YEAR,YEAR,TIMESLICE,TECHNOLOGY,REGION);
*CapVintage4b(v,y,l,t,r)$( (TechWithCapacityNeededToMeetPeakTS(r,t) <> 0) AND  (ord(y)=1) ).. RateOfTotalActivityByVintage(v,y,l,t,r) =l= (NewCapacity(v,t,r)+ResidualCapacity(r,t,y))*CapacityFactor(r,t,l,v)*CapacityToActivityUnit(r,t);

*equation CapVintage5(YEAR,YEAR,TIMESLICE,TECHNOLOGY,MODE_OF_OPERATION,REGION);
*CapVintage5(v,y,l,t,m,r)$(ord(v) >= ord(y)+1).. RateOfActivityByVintage(v,y,l,t,m,r) =e= 0;





equation VehicleVMTProduction(YEAR,TIMESLICE,PrivTrans,REGION);
VehicleVMTProduction(y,l,p,r).. ProductionByTechnology(y,l,p,"VMT",r) =e= TotalCapacityAnnual(y,p,r)*SpecifiedAnnualDemand(r,"VMT",y)*SpecifiedDemandProfile(r,"VMT",l,y)/FleetSize(y,r);

equation V2GCapacityConstraint1(YEAR,REGION);
V2GCapacityConstraint1(y,r).. NewCapacity(y,"V2G",r) =l= 0.006*NewCapacity(y,"EV",r);
equation V2GCapacityConstraint2(YEAR,REGION);
V2GCapacityConstraint2(y,r).. NewCapacity(y,"EV_CHARGE",r) =e= 0.006*NewCapacity(y,"EV",r);

equation V2GCapacityConstraint3(YEAR,REGION);
V2GCapacityConstraint3(y,r).. NewStorageCapacity(y,"EV_BAT",r) =e= 0.000072 * NewCapacity(y,"EV",r);


*Constrain non-intermittent (fossil fuel) PP capacities to meet 80% of peak demand
equation FFPowerPlantCapAtPeakDemand(y,r,l);
FFPowerPlantCapAtPeakDemand(y,r,l).. sum(NICPP,TotalCapacityAnnual(y,NICPP,r)) =g= NICPPlower(y)*(RateOfDemand(y,l,"ELC",r)+sum(t, RateOfUseByTechnology(y,l,t,"ELC",r)))/CapacityToActivityUnit(r,"COALPP");

equation EV_Driving(y,l,r);
EV_Driving(y,l,r).. UseByTechnology(y,l,"EV","ELC",r) =e= ProductionByTechnology(y,l,"EV_DISCHARGE","ELC",r);




*Fleet Constraints

equation EVF_Driving(y,l,r);
EVF_Driving(y,l,r).. UseByTechnology(y,l,"EV_F","ELC",r) =e= ProductionByTechnology(y,l,"EV_DISCHARGE_F","ELC",r);

*equation VehicleFMTProduction(YEAR,TIMESLICE,Fleet,REGION);
*VehicleFMTProduction(y,l,ft,r).. ProductionByTechnology(y,l,ft,"FMT",r) =e= TotalCapacityAnnual(y,ft,r)*SpecifiedAnnualDemand(r,"FMT",y)*SpecifiedDemandProfile(r,"FMT",l,y)/FleetSizeFleet(y,r);

equation V2GFCapacityConstraint1(YEAR,REGION);
V2GFCapacityConstraint1(y,r).. NewCapacity(y,"V2G_F",r) =l= 0.006*NewCapacity(y,"EV_F",r);
equation V2GFCapacityConstraint2(YEAR,REGION);
V2GFCapacityConstraint2(y,r).. NewCapacity(y,"EV_CHARGE_F",r) =e= 0.006*NewCapacity(y,"EV_F",r);

equation V2GFCapacityConstraint3(YEAR,REGION);
V2GFCapacityConstraint3(y,r).. NewStorageCapacity(y,"EV_BAT_F",r) =e= 0.000072 * NewCapacity(y,"EV_F",r);


*Carbon Intensity Equation


equation CI1_TimesliceEmissionProduction(YEAR,TECHNOLOGY,EMISSION,TIMESLICE,FUEL,REGION);
* E1_AnnualEmissionProductionByMode(y,t,e,m,r)$(EmissionActivityRatio(r,t,e,m,y) <> 0)..EmissionActivityRatio(r,t,e,m,y)*TotalAnnualTechnologyActivityByMode(y,t,m,r) =e=AnnualTechnologyEmissionByMode(y,t,e,m,r);
CI1_TimesliceEmissionProduction(y,t,e,l,f,r)..
sum(m,EmissionActivityRatio(r,t,e,m,y))*ProductionByTechnology(y,l,t,f,r) =e=
TimesliceEmissionProduction(y,t,e,l,f,r);


*CI Variables

positive variable TotalELC_Use(YEAR,TIMESLICE,REGION);
positive variable TotalEmissionBySlice(YEAR,TIMESLICE,REGION);
positive variable UseIndVMT(YEAR,TECHNOLOGY,FUEL,REGION);
positive variable UseTotVMT(YEAR,FUEL,REGION);
positive variable Tot_EV_USE(YEAR,TIMESLICE,REGION)



equation CI1_TotalELC_USE(YEAR,TIMESLICE,REGION);

CI1_TotalELC_Use(y,l,r)..
sum(t,ProductionByTechnology(y,l,t,"ELC",r)) - ProductionByTechnology(y,l,"EV_CHARGE","ELC",r) -
ProductionByTechnology(y,l,"EV_DISCHARGE","ELC",r) - ProductionByTechnology(y,l,"EV_CHARGE_F","ELC",r) -
ProductionByTechnology(y,l,"EV_DISCHARGE_F","ELC",r)
 =e= TotalELC_Use(y,l,r);


equation CI2_TotalEmissionBySlice(YEAR,TIMESLICE,REGION);

CI2_TotalEmissionBySlice(y,l,r)..
sum(t,TimesliceEmissionProduction(y,t,"CO2",l,"ELC",r)) =e=
TotalEmissionBySlice(y,l,r);

equation CI3_UseIndVMT(YEAR,TECHNOLOGY,FUEL,REGION);

CI3_UseIndVMT(y,t,f,r)..
sum(l,UseByTechnologyAnnual(y,t,f,r))  =e=
UseIndVMT(y,t,f,r);

equation CI4_UseTotVMT(YEAR,FUEL,REGION);

CI4_UseTotVMT(y,f,r)..
sum(t,sum(l,UseByTechnology(y,l,t,f,r)))  =e=
UseTotVMT(y,f,r);

equation CI5_TotEV_Use(y,l,r);

CI5_TotEV_Use(y,l,r)..
UseByTechnology(y,l,"EV_CHARGE","ELC",r) + UseByTechnology(y,l,"EV_CHARGE_F","ELC",r) =e=
Tot_EV_USE(y,l,r);





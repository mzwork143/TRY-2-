/************************************************************************************/
/* This program takes shap output from Python and summarizes for model adjustments	*/
/* to WPC workload targets								 							*/
/* based on property code from:														*/
/* "A:\Modeling\Claims\Resource Capacity\Property Adjuster\Report\Score Code\		*/
/*	6 Import and Prep Python Output v2 Superfile Fixes.sas"							*/
/************************************************************************************/


	
/* IMPORT THE SHAP VALUES SCORED BY THE CATBOOST MODEL */
/* get rid of invalid values when importing- ex: changes (InjuryLevelIncident,) to __InjuryLevelIncident___ */
options validvarname=v7;

%macro ImportCustom();

%if &flag. = 1 %then %do;
	PROC IMPORT DATAFILE="/ere/local/shared/actuarial/Share/Claims/WPC/Liability/executable/Output/model_shap.csv"
	DBMS=csv
	REPLACE
	OUT=PYTHONRAW;
RUN;
%end;
%else %do;
	PROC IMPORT DATAFILE="&output_path_csv/model_shap.csv"
	DBMS=csv
	REPLACE
	OUT=PYTHONRAW;
RUN;
%end;

%mend ImportCustom;

%ImportCustom();




/* now get rid of the underscores */
data PYTHONRAW;
	set PYTHONRAW;

	rename __InjuryLevelIncident___=InjuryLevelIncident;
	rename __legal_ind___=legal_ind;
	rename __EXPSR_TIER_DC_grp___=EXPSR_TIER_DC_grp;
	rename __CT_SCAN_IN___=CT_SCAN_IN;
	rename __TIER_TYP_DC_grp___=TIER_TYP_DC_grp;
	rename __AGGR_LMT_Ind___=AGGR_LMT_Ind;
	rename __ContactCount___=ContactCount;
	rename __FLG_TYP_DC_Ind___=FLG_TYP_DC_Ind;
	rename __PRIM_BODY_PART_TYP_Ind___=PRIM_BODY_PART_TYP_Ind;
	rename __AdjusterRole___=AdjusterRole;
	rename __USR_RPT_BRNCH_DC___=USR_RPT_BRNCH_DC;
	rename __INSD_FLT_TYP_DC_grp___=INSD_FLT_TYP_DC_grp;
	rename __frst_iso_send_dt_Ind___=frst_iso_send_dt_Ind;
	rename __SPCL_INVSTN_UNT_STT_DC___=SPCL_INVSTN_UNT_STT_DC;
	rename __FNOL_SRVY_IN___=FNOL_SRVY_IN;
	rename __TORT_OPT_Full_Ind___=TORT_OPT_Full_Ind;
	rename __EXPSR_TYP_DC_grp___=EXPSR_TYP_DC_grp;
	rename __LIEN_IN___=LIEN_IN;
	rename __AutoMidHighComplexity_Ind___=AutoMidHighComplexity_Ind;
	rename __LC_CollisionMultiVeh___=LC_CollisionMultiVeh;
	rename __HIT_AND_RUN_IN___=HIT_AND_RUN_IN;
	rename __Out_Of_State_Ind___=Out_Of_State_Ind;
	rename __HO_PNTV_DMG_CNT_IN___=HO_PNTV_DMG_CNT_IN;
	rename __Report_Lag___=Report_Lag;
	rename __Contact_Government___=Contact_Government;
	rename __LC_Weather___=LC_Weather;
	rename __Claimant_Under17_ind___=Claimant_Under17_ind;
	rename __Contact_Doctor___=Contact_Doctor;
	rename __LC_TheftOfEntireVehicle___=LC_TheftOfEntireVehicle;
	rename __baseline_mean___=baseline_mean;

run;


/* check all modeled times make sense with shap, and create variable groupings */
data python2;
	set pythonraw (drop=var1);

	Claim =			sum(TIER_TYP_DC_grp,
					ContactCount,
					INSD_FLT_TYP_DC_grp,
					AutoMidHighComplexity_Ind,
					LC_CollisionMultiVeh,
					Out_Of_State_Ind,
					Report_Lag,
					Contact_Government,
					LC_Weather,
					Claimant_Under17_ind,
					LC_TheftOfEntireVehicle);

	Exposure =	 	sum(EXPSR_TIER_DC_grp,
					AGGR_LMT_Ind,
					AdjusterRole,
					USR_RPT_BRNCH_DC,
					FNOL_SRVY_IN,
					TORT_OPT_Full_Ind,
					EXPSR_TYP_DC_grp,
					LIEN_IN);

	Medical = 		sum(InjuryLevelIncident,
					CT_SCAN_IN,
					PRIM_BODY_PART_TYP_Ind,
					Contact_Doctor);

	Investigation = sum(legal_ind,
					FLG_TYP_DC_Ind,
					frst_iso_send_dt_Ind,
					SPCL_INVSTN_UNT_STT_DC,
					HIT_AND_RUN_IN,
					HO_PNTV_DMG_CNT_IN);

	shap_pred = 	sum(baseline_mean,
					Claim,
					Exposure,
					Medical,
					Investigation);

	check = round(shap_pred - pred,.001);

run;
/* all zeros- no errors! */
proc means data = python2 nway noprint missing;
	class check;
	var Contact_Government;
	output out = test (drop = _type_) sum=;
run;

/* get the files that underlie the count data from MaryBeth */
PROC IMPORT DATAFILE='/ere/local/shared/actuarial/Share/Claims/WPC/Liability/Workload SAS programs/History Liability Completed Exposure.xlsx' 
	DBMS=XLSX
	REPLACE
	OUT=Exposures_Completed;
	GETNAMES=YES;
RUN;
%changeColFormat2Char(Exposures_Completed, CLM_NR|Claimkey|JURIS_STATE_DC|LOB|wkldhist|
											YearMon|ADJ_NM|ADJNUM|USR_RPT_BRNCH_DC|ReportingRegion|
											ADJ_GRP_DC|ADJ_POS_DC|ST_POS_DC|SPVS_NM|SUPVNUM|WorkType|EXPSR_TYP_DC|
											ClmntFirst|ClmntLast|PolicyST|Source|Status|
											PayPeriodEnd|EmpIDPPE, $50.)

%changeColFormat2Num(Exposures_Completed,LOSS_DT|EXPSR_STRT_DT|WORK_CLS_DT|start_dt|CreateDate|claimcnt|EXPSR_NTRL_ID|INCID_NTRL_ID|CLMT_ID, Best8.2);
 



PROC IMPORT DATAFILE='/ere/local/shared/actuarial/Share/Claims/WPC/Liability/Workload SAS programs/History Liability New Exposure.xlsx'
	DBMS=XLSX
	REPLACE
	OUT=Exposures_New;
	GETNAMES=YES;
RUN;

%changeColFormat2Char(Exposures_New, CLM_NR|Claimkey|JURIS_STATE_DC|LOB|wkldhist|
											YearMon|ADJ_NM|ADJNUM|USR_RPT_BRNCH_DC|ReportingRegion|
											ADJ_GRP_DC|ADJ_POS_DC|ST_POS_DC|SPVS_NM|SUPVNUM|WorkType|
											EXPSR_TYP_DC|ClmntFirst|ClmntLast|PolicyST|Source|Status|
											PayPeriodEnd|EmpIDPPE|LossSt, $50.)

%changeColFormat2Num(Exposures_New,LOSS_DT|CreateDate|EXPSR_STRT_DT|EXPSR_END_DT|startdt|claimcnt|ClmCnt|EXPSR_NTRL_ID|INCID_NTRL_ID|CLMT_ID, Best8.2);





/* in case we would ever get a historical open file- probably not needed for scoring because we place so little weight on open exposures  */
/*PROC IMPORT DATAFILE='/ere/ho/actuarial/Share/Claims/WPC/Liability/Workload SAS programs/history Liability Open Exposures.xlsx'*/
/*	DBMS=XLSX*/
/*	REPLACE*/
/*	OUT=Exposures_Open;*/
/*	GETNAMES=YES;*/
/*RUN;*/

/* stack - 528,258*/
data monthend_Liab_Exposure;
	set Exposures_Completed Exposures_New;

	/* create a key field to mmerge on */
	format drpno $100.;
	drpno=strip(CLM_NR)||"-"||strip(EXPSR_NTRL_ID)||"-"||strip(ADJNUM);

	/* create a standard pay period to merge on */
	format PayPeriodString $8.;
	PayPeriodString = put(PayPeriodEnd,8.);

	format payperioddate MMDDYY10.;
	payperioddate = mdy(substr(PayPeriodString,5,2),substr(PayPeriodString,7,2),substr(PayPeriodString,1,4));
run;

/* merge on shap values- 528,258 */
PROC SQL;
	CREATE TABLE for_report As
		Select a.drpno,
				A.Status,
				A.ADJ_NM as ADJUSTERNAME,	
				A.ADJNUM as ADJUSTERNR,
				A.ADJ_POS_DC as ADJPOSITIONTITLE,
				A.USR_RPT_BRNCH_DC as ADJUSTERREPORTINGBRANCH,
				a.WorkType,
				a.payperioddate,
				max(B.pred,0) as model_elaps, /* some of the model predictions are negative- cap at a min of zero */
				b.Claim,
				b.Exposure,
				b.Medical,
				b.Investigation

		From monthend_Liab_Exposure as A left join python2 as B
		on compress(a.drpno) = compress(b.drpno)
		;
QUIT;
/* see how many predictions are blank- about 1%- nice */
proc means data = for_report nway noprint missing;
	class Claim;
	var payperioddate;
	output out = test (drop = _type_) sum=;
run;

/*************************/
/* probably need to merge on branch and adjuster position from other file */
/*************************/
/* merge adjuster info on from the main template file- adjuster names and positions are not consistent on these files */
PROC IMPORT DATAFILE='/ere/local/shared/actuarial/Share/Claims/WPC/Adj Prod by Liability_Template.xlsx' 
	DBMS=XLSX
	REPLACE
	OUT=Liability_Template;
	GETNAMES=YES;
RUN;
/**/
/*%changeColFormat2Char(BOTH1, AdjusterRegion|AdjusterTeamBranch|SupvNum|SupvNam|AdjPosition|AdjNm|AdjNumber|*/
/*								MaskEmpl|PayPeriodEnd|PayPeriodEnd|EmpPayPeriod|*/
/*								StartDateinPosition|HireDate, $50.)*/
/*%changeColFormat2Num(Both1,OldClaims|OldBIExposures|NewInjuryExposures|OpenInjuryExposures|*/
/*							CompletedInjuryExposures|NewNonInjuryExposures|OpenNonInjuryExposures|*/
/*							CompletedNonInjuryExposures, Best8.);*/
/*%changeColFormat2Num(Both1,TotalHoursWorked|TotalRegHrsPaid|TotalOTHrsPaid|TotalPTOHrsPaid, Best8.2);*/
/*  */


/* 528,258 */
proc sql;
	create table for_report as
	select a.*, b.AdjusterRegion, b.AdjusterTeamBranch, b.AdjPosition
	from for_report as a left join Liability_Template as b
	on a.ADJUSTERNR = b.AdjNumber and a.payperioddate = b.PayPeriodEnd_1;
quit;

/* DROP MISSING INFO */
/* the template file has the main count of exposures */
/* the new and completed file has the detail of the exposures that we need to score the model on */
/* drop records where we are missing the main data needed for model adjustments (adjuster position, pay period, or model scores) */
/* 162,596- need payperiod on new exposures- this should drastically increase the records we keep */
data for_report;
	set for_report;
    if AdjPosition='' then delete;
	if payperioddate=. then delete;
	if Claim=. then delete;
	if AdjusterTeamBranch= 'Fort Wayne' then AdjusterTeamBranch='Indiana';
		else if AdjusterTeamBranch= 'Hagerstown' then AdjusterTeamBranch='Silver Spring';
		else if AdjusterTeamBranch= 'Johnstown' then AdjusterTeamBranch='Murrysville';
		else if AdjusterTeamBranch= 'Waynesboro' then AdjusterTeamBranch='Roanoke';
run;

/* ADJUSTER AVERAGES- 18,479*/
proc means data= for_report noprint nway missing;
	class ADJUSTERNR AdjPosition AdjusterTeamBranch WorkType payperioddate;
	var model_elaps Claim Exposure Medical Investigation;
	output out= avg_adj (drop = _type_ ) mean= ;
	where not missing(ADJUSTERNR);
run;

/* OVERALL AVERAGE BY POSITION ACROSS ALL PAY PERIODS */
proc means data= for_report noprint nway missing;
	class AdjPosition WorkType;
	var model_elaps Claim Exposure Medical Investigation;
	output out= avg_adjposition (drop = _type_ ) mean= ;
	where not missing(ADJUSTERNR);
run;

/* 18,372 */
PROC SQL;
	CREATE TABLE ind_report As
		Select a.ADJUSTERNR,
			a.AdjPosition, 
			a.AdjusterTeamBranch,
			a.WorkType, 
			a.payperioddate,
			year(a.payperioddate) as year,
			a.model_elaps as adj_avg,
			a._freq_ as records,
			a.Claim,
			a.Exposure,
			a.Medical,
			a.Investigation,
			b.model_elaps as model_elaps_roll, 
			a.model_elaps/b.model_elaps as adj_to_cw
		From avg_adj as A left join avg_adjposition as B
		on A.AdjPosition = B.AdjPosition
		and a.WorkType = b.WorkType
/*		and a.payperiod = b.payperiod*/  /* not using rolling payperiods- just using all time average from all periods- we don't have full rolling history available */
		;
QUIT;

/* force adjustments to be normal- removed "year" from by field since we are not using rolling 12 months */
proc sort data=ind_report;
	by AdjPosition WorkType /*year*/;
run;
/* each adjustment is given a rank from 0 to 99 */
proc rank data=ind_report out=ind_report groups=100;
   var adj_to_cw;
   by AdjPosition WorkType /*year*/;
   ranks adj_to_cw_n;
run;

/* this limits the max/mins based on the standard deviation selection- same calc as what we use for other WPC reports  */
data ind_report;
	set ind_report;
	z_score = max(min((adj_to_cw_n)/100,99),.01); /* 0 and 1 cannot be quantiles */
	norm = quantile('NORMAL',z_score);
	norm_adj = round(1+norm*.05,.01);
run;

/* rank the four flags in groups from 0 to 3 */
proc rank data=ind_report out=ind_report groups=4;
   var Claim;
   by AdjPosition WorkType;
   ranks Claim_r;
run;
proc rank data=ind_report out=ind_report groups=4;
   var Exposure;
   by AdjPosition WorkType;
   ranks Exposure_r;
run;
proc rank data=ind_report out=ind_report groups=4;
   var Medical;
   by AdjPosition WorkType;
   ranks Medical_r;
run;
proc rank data=ind_report out=ind_report groups=4;
   var Investigation;
   by AdjPosition WorkType;
   ranks Investigation_r;
run;

/* merge to main template file */

/* split file into injuries and non-injuries */
data Liability_Template_Injuries;
	set Liability_Template;
	format WorkType $12.;
	WorkType='Injuries';
run;
data Liability_Template_NonInjuries;
	set Liability_Template;
	format WorkType $12.;
	WorkType='Non-Injuries';
run;
/* stack- 18,404 */
data ind_all;
	set Liability_Template_Injuries Liability_Template_NonInjuries;
run;

/* MERGE ON THE ADJUSTER MODEL ADJUSTMENTS- 18,404 */
proc sql;
	create table ind_all as
	select a.*, b.*
	from ind_all as a left join ind_report as b
	on a.AdjNumber = b.ADJUSTERNR and a.PayPeriodEnd_1 = b.payperioddate and a.WorkType = b.WorkType;
quit;

/* OUTPUT FOR EXCEL- 18,404 */
data ind_out(keep=WorkType
				AdjNumber	
				AdjPosition
				AdjusterTeamBranch
				PayPeriodEnd_1	
				norm_adj
				Claim_r
				Exposure_r
				Medical_r
				Investigation_r);

			retain WorkType
					AdjNumber	
					AdjPosition
					AdjusterTeamBranch
					PayPeriodEnd_1	
					norm_adj
					Claim_r
					Exposure_r
					Medical_r
					Investigation_r;
	set ind_all;
	if norm_adj = . then norm_adj = 1;

	/* 1 defaults to medium complexity claim or no adjustment to targets */
	/* claims analytics (MaryBeth) requested that we did not leave blanks */
	if Claim_r = . then Claim_r = 1;
	if Exposure_r = . then Exposure_r = 1;
	if Medical_r = . then Medical_r = 1;
	if Investigation_r = . then Investigation_r = 1;
run;

/* BRANCH */
/* roll up to branch using hours as weight */
proc means data= ind_all noprint nway missing;
	class WorkType AdjPosition AdjusterTeamBranch PayPeriodEnd_1;
	var norm_adj;
	wgt TotalHoursWorked;
	output out= br_adjs (drop = _freq_ _type_) mean=;
run;
/* OUTPUT */
data br_adjs;
	set br_adjs;
	norm_adj=round(norm_adj,0.01);
	if norm_adj = . then norm_adj = 1;
run;

/* REGION */
/* roll up to branch using hours as weight */
proc means data= ind_all noprint nway missing;
	class WorkType AdjPosition AdjusterRegion PayPeriodEnd_1;
	var norm_adj;
	wgt TotalHoursWorked;
	output out= regn_adjs (drop = _freq_ _type_) mean=;
run;
/* OUTPUT */
data regn_adjs;
	set regn_adjs;
	norm_adj=round(norm_adj,0.01);
	if norm_adj = . then norm_adj = 1;
run;

/*****************************************
	QLIK FILES
*****************************************/
/* 1. QlikSuperfile_liab.xlsx */

/* basically just have to merge on model scores */
/* separate scores into injuries and non-injuries (Error datasets should be blank) */
data AVG_ADJ_Injuries AVG_ADJ_NonInjuries Error;
	set ind_out;
	if WorkType='Injuries' then output AVG_ADJ_Injuries;
		else if WorkType='Non-Injuries' then output AVG_ADJ_NonInjuries;
		else output Error;
run;
data AVG_BRANCH_Injuries AVG_BRANCH_NonInjuries Error2;
	set br_adjs;
	if WorkType='Injuries' then output AVG_BRANCH_Injuries;
		else if WorkType='Non-Injuries' then output AVG_BRANCH_NonInjuries;
		else output Error2;
run;
data AVG_REGION_Injuries AVG_REGION_NonInjuries Error3;
	set regn_adjs;
	if WorkType='Injuries' then output AVG_REGION_Injuries;
		else if WorkType='Non-Injuries' then output AVG_REGION_NonInjuries;
		else output Error3;
run;

/* 9,861 */
PROC SQL;
CREATE TABLE qlik_final As
	Select 

		A.AdjusterRegion
		,a.AdjusterTeamBranch
		,a.AdjPosition
		,a.AdjNm
		,a.AdjNumber
		,a.SupvNam
		,a.SupvNum
		,a.payperioddate
		,Year(a.payperioddate) as year
		,Month(a.payperioddate) as month
		,strip(a.AdjNumber)||strip(put(a.payperioddate, yymmddn8.)) as EmpID_PP
		/*	counts*/
		,a.NewInjuryExposures 
		,a.NewNonInjuryExposures  	
		,a.OpenInjuryExposures	
		,a.OpenNonInjuryExposures
		,a.CompletedInjuryExposures	
		,a.CompletedNonInjuryExposures
		/*hours*/
		,a.TotalHoursWorked
		,a.TotalPTOHrsPaid
		,a.TotalOTHrsPaid
		,a.TotalRegHrsPaid

		/* model- injuries */
		,b.norm_adj as Norm_adj_injuries
		,b.Claim_r as Claim_r_injuries
		,b.Exposure_r as Exposure_r_injuries
		,b.Medical_r as Medical_r_injuries
		,b.Investigation_r as Investigation_r_injuries
		,c.norm_adj as Adj_br_injuries
		,d.norm_adj as Adj_rgn_injuries

		/* model- noninjuries */
		,e.norm_adj as Norm_adj_noninjuries
		,e.Claim_r as Claim_r_noninjuries
		,e.Exposure_r as Exposure_r_noninjuries
		,e.Medical_r as Medical_r_noninjuries
		,e.Investigation_r as Investigation_r_noninjuries
		,f.norm_adj as Adj_br_noninjuries
		,g.norm_adj as Adj_rgn_noninjuries
			
	From LiabAdj.hcoutput as A 

	left join AVG_ADJ_Injuries as B
		on a.AdjNumber = b.AdjNumber
		and a.AdjPosition = b.AdjPosition 
		and a.AdjusterTeamBranch = b.AdjusterTeamBranch
		and a.payperioddate = b.PayPeriodEnd_1

	left join AVG_BRANCH_Injuries as C
		on a.AdjPosition = c.AdjPosition 
		and a.AdjusterTeamBranch = c.AdjusterTeamBranch
		and a.payperioddate = c.PayPeriodEnd_1

	left join AVG_REGION_Injuries as D
		on a.AdjPosition = d.AdjPosition 
		and a.AdjusterRegion = d.AdjusterRegion
		and a.payperioddate = d.PayPeriodEnd_1

	left join AVG_ADJ_NonInjuries as E
		on a.AdjNumber = e.AdjNumber
		and a.AdjPosition = e.AdjPosition 
		and a.AdjusterTeamBranch = e.AdjusterTeamBranch
		and a.payperioddate = e.PayPeriodEnd_1

	left join AVG_BRANCH_NonInjuries as F
		on a.AdjPosition = f.AdjPosition 
		and a.AdjusterTeamBranch = f.AdjusterTeamBranch
		and a.payperioddate = f.PayPeriodEnd_1

	left join AVG_REGION_NonInjuries as G
		on a.AdjPosition = g.AdjPosition 
		and a.AdjusterRegion = g.AdjusterRegion
		and a.payperioddate = g.PayPeriodEnd_1
;
QUIT;

/* fill in 1.0s - ok to leave categories as blanks */
data qlik_final (drop=i);
	set qlik_final;

	/* file in 1.00 for missing factors */
	array N[*] Norm_adj_injuries Adj_br_injuries Adj_rgn_injuries Norm_adj_noninjuries Adj_br_noninjuries Adj_rgn_noninjuries;
		
	do i=1 to hbound(N);
		if N[i]=. then N[i]=1;
	end;
run;



/* 2. QlikAdjustments_liab.xlsx */

/* again start with the template file and transpose */
/* 9,861 */
PROC SQL;
	CREATE TABLE qa_completed As
		Select a.AdjNumber
				,a.AdjPosition
				,a.AdjusterTeamBranch
				,a.AdjusterRegion
				,a.payperioddate
				,a.NewInjuryExposures 
				,a.NewNonInjuryExposures  	
				,a.OpenInjuryExposures	
				,a.OpenNonInjuryExposures
				,a.CompletedInjuryExposures	
				,a.CompletedNonInjuryExposures
		From LiabAdj.hcoutput as a
	;
QUIT;
proc sort data= qa_completed; 
	by AdjNumber AdjusterTeamBranch AdjusterRegion payperioddate AdjPosition;
run;

/* transpose wide to long- basically creating a record for the 6 exposure types (file increases x6) */
/* 59,166 */
proc transpose data=qa_completed out=qa_completed_w /*prefix=adj*/;
	by AdjNumber AdjusterTeamBranch AdjusterRegion payperioddate AdjPosition;
    var NewInjuryExposures -- CompletedNonInjuryExposures;
run;
/* create an Exposure field to merge on */
data qa_completed_w;
	set qa_completed_w;

	/* look for the string "NonInjury" */
	format Exposure $12.;
	if find(_NAME_, "NonInjury")>0 then Exposure ='Non-Injuries';
		else Exposure ='Injuries';
run;
/* Create columns to count new, open, and close exposures */
data qa_completed_w;
	set qa_completed_w;
	format 	New 8.
			Open 8.
			Completed 8.;
	if substr(_NAME_,1,3)="New" then New = COL1;
		else if substr(_NAME_,1,3)="Ope" then Open = COL1;
		else if substr(_NAME_,1,3)="Com" then Completed = COL1;		
run;
/* summarize */
proc means data = qa_completed_w nway noprint missing;
	class Exposure AdjPosition AdjNumber AdjusterTeamBranch payperioddate;
	var New Open Completed;
	output out = qa_completed_sum (drop = _type_) sum=;
run;

/* merge */
/* 59,166 */
PROC SQL;
	CREATE TABLE qlik_adj1 As
		Select a.Exposure,
				a.AdjPosition,
				a.AdjNumber,
				a.AdjusterTeamBranch,
				a.payperioddate,
				strip(a.AdjNumber)||strip(put(a.payperioddate,yymmddn8. )) as EmpID_PP, /*"MB" as EmpID_PP MB will fill */
				a.New,
				a.Open,
				a.Completed,

				/* model */
				b.Norm_adj,
				b.Claim_r,
				b.Exposure_r,
				b.Medical_r,
				b.Investigation_r				

		From qa_completed_sum as a

		left join ind_out as b

		on 	a.AdjNumber = b.AdjNumber
		and	a.AdjusterTeamBranch = b.AdjusterTeamBranch
		and a.AdjPosition = b.AdjPosition
		and a.payperioddate = b.PayPeriodEnd_1
		and a.Exposure = b.WorkType
	;
QUIT;
data qlik_adj1;
	set qlik_adj1;
	if norm_adj = . then norm_adj = 1;
run;	




%macro ExportCustom();

%if &flag. = 1 %then %do;
	/* excel output */
	proc export data=qlik_final 
		outfile="/ere/local/shared/actuarial/Share/Claims/WPC/Liability/executable/Output/QlikSuperfile_liab.xlsx"
		dbms=xlsx
		replace;
run;


	proc export data=qlik_adj1 
		outfile="/ere/local/shared/actuarial/Share/Claims/WPC/Liability/executable/Output/QlikAdjustments_liab.xlsx"
		dbms=xlsx
	replace;
run;
%end;
%else %do;

	/* excel output */
	proc export data=qlik_final 
		outfile="&output_path_csv/QlikSuperfile_liab.xlsx"
		dbms=xlsx
		replace;
run;




	proc export data=qlik_adj1 
		outfile="&output_path_csv/QlikAdjustments_liab.xlsx"
		dbms=xlsx
	replace;
run;
%end;

%mend ExportCustom;

%ExportCustom();
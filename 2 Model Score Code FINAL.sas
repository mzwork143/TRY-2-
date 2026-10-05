
/*libname LiabAdj "/ere/local/shared/actuarial/Share/Claims/WPC/TESTING 2/Liability/2024/05-17-2024";*/

LIBNAME CCDS ORACLE PATH=CDEP1 SCHEMA=BRFADM Authdomain=Oracle_Auth_CCDS;

%let from_date=%unquote(%str(%'&from_date%'));
%put &from_date;

%let to_date=%unquote(%str(%'&to_date%'));
%put &to_date;


PROC SQL; 

    CONNECT USING CCDS;



    CREATE TABLE InternalServicesScored AS
    SELECT * 

	FROM connection to CCDS
    (
    SELECT DISTINCT

	CLM.CLM_NTRL_ID,
	CLM.POL_NTRL_ID,
	CLM.CLMT_ID,
	CLM.CLM_NR as ClaimNumber,
	CLM.RPT_DT,
	CLM.LOSS_DT,
	CLM.CRT_DT,
	CLM.FLG_TYP_DC,
	CLM.FNOL_SRVY_IN,
	CLM.INSD_FLT_TYP_DC,
	CLM.JURIS_STATE_DC,
	CLM.LOSS_CAUS_DC,
	CLM.RPT_BY_DC,
	CLM.SGMNT_DC,
	CLM.SPCL_INVSTN_UNT_STT_DC,
	CLM.TIER_TYP_DC,

	CNTC.BRTH_DT,
	CNTC.SBTYP_DC,

	CORP_REFL.PNTV_DMG_CNT_IN,

	COV.AGGR_LMT_AM,

	BODY_PART_DTL.PRIM_BODY_PART_TYP_DC,

	EVAL.CT_SCAN_IN,

	EVAL.LIEN_IN,

	EXPSR.EXPSR_TIER_DC,
	EXPSR.EXPSR_TYP_DC,
	EXPSR.EXPSR_CLMT_NR,
	EXPSR.EXPSR_NTRL_ID,
	EXPSR.CLS_DT					as Expo_CloseDate,

	EXPSR_HRCHY_MV.ADJ_POS_DC,
	EXPSR_HRCHY_MV.USR_RPT_BRNCH_DC,
	EXPSR_HRCHY_MV.EXPSR_ASGN_USR_ID,
	EXPSR_HRCHY_MV.EXPSR_STRT_DT  	as Adj_Expo_StartDate,
	EXPSR_HRCHY_MV.EXPSR_END_DT		as Adj_Expo_EndDate,

	INCID.FRST_ISO_SEND_DT,
	INCID.HIT_AND_RUN_IN,
	INCID.TORT_OPT_DC,

	
	case 
		when EXPSR_HRCHY_MV.ADJ_POS_DC in('Liability Specialist','Liability Specailist','Liabilty Specialist') then 'Liability Specialist'
		when EXPSR_HRCHY_MV.ADJ_POS_DC in('Commercial Liab Claims Spct','Commercial Liability Claims Specialist','Commercial Liability Specialist','COMMERCIAL LIABILITY SPECIALIST') then 'Commercial Liability Specialist'
		when EXPSR_HRCHY_MV.ADJ_POS_DC in('Liability Adjuster','Sr Liability Adjuster') then 'Liability Adjuster'
		when EXPSR_HRCHY_MV.ADJ_POS_DC in('UM/UIM Claims Adjuster','UM/UIM Claims Specialist','UM/UIM Adjuster','UM/UIM Specialist') then 'UM/UIM Specialist'
		when EXPSR_HRCHY_MV.ADJ_POS_DC in('Sr Commercial Claims and Litigation Specialist','Sr Commercial Liability Specialist') then 'Sr Commercial Claims and Litigation Specialist'
		
		else 'Z_Other'
	end as Adjuster_Type,

	CLM.CLM_NR||EXPSR.EXPSR_CLMT_NR as CLM_CLMT_NR
	
	
	FROM BRFADM.CLM	CLM

	
	LEFT JOIN BRFADM.INCID ON CLM.CLM_NTRL_ID = INCID.CLM_NTRL_ID
		
		AND INCID.REC_RET_IN = 'N' 
		AND INCID.CRNT_REC_IN = 'Y'

	
	LEFT JOIN BRFADM.EXPSR ON CLM.CLM_NTRL_ID = EXPSR.CLM_NTRL_ID
		AND INCID.INCID_NTRL_ID = EXPSR.INCID_NTRL_ID
	    AND EXPSR.REC_RET_IN = 'N' 
	    AND EXPSR.CRNT_REC_IN = 'Y'

	
	LEFT JOIN BRFADM.EXPSR_HRCHY_MV ON EXPSR.EXPSR_NTRL_ID = EXPSR_HRCHY_MV.EXPSR_NTRL_ID


	
	LEFT JOIN BRFADM.CNTC ON EXPSR.CLMT_ID = CNTC.CNTC_NTRL_ID
	    AND CNTC.REC_RET_IN = 'N' 
	    AND CNTC.CRNT_REC_IN = 'Y'

	
	LEFT JOIN BRFADM.COV ON EXPSR.COV_NTRL_ID = COV.COV_NTRL_ID
	    AND COV.REC_RET_IN = 'N' 
	    AND COV.CRNT_REC_IN = 'Y'

	
	LEFT JOIN BRFADM.BODY_PART_DTL ON INCID.INCID_NTRL_ID = BODY_PART_DTL.INCID_NTRL_ID
	    AND BODY_PART_DTL.REC_RET_IN = 'N' 
	    AND BODY_PART_DTL.CRNT_REC_IN = 'Y'	

	
	LEFT JOIN BRFADM.EVAL ON EXPSR.EXPSR_NTRL_ID = EVAL.EXPSR_NTRL_ID
		AND EVAL.REC_RET_IN = 'N'
		AND EVAL.CRNT_REC_IN = 'Y'

	
	LEFT JOIN BRFADM.CORP_REFL ON EXPSR.EXPSR_NTRL_ID = CORP_REFL.EXPSR_NTRL_ID
		AND CORP_REFL.REC_RET_IN = 'N'
		AND CORP_REFL.CRNT_REC_IN = 'Y'

	
	WHERE CLM.CRNT_REC_IN = 'Y' 
		AND CLM.REC_RET_IN = 'N'
		AND CLM.LOSS_CAUS_DC not in ('CMSConversion') 

		AND EXPSR_HRCHY_MV.EXPSR_STRT_DT > '01JAN1900:01:00:00.000000'  
		AND EXPSR.EXPSR_TYP_DC not in ('TimeLoss','WCInjuryDamage','EmployerLiability') 

		
		AND EXPSR_HRCHY_MV.ADJ_POS_DC in ('Liability Specialist','Liability Specailist','Liabilty Specialist',
										'Commercial Liab Claims Spct','Commercial Liability Claims Specialist','Commercial Liability Specialist','COMMERCIAL LIABILITY SPECIALIST',
										'Liability Adjuster','Sr Liability Adjuster',
										'UM/UIM Claims Adjuster','UM/UIM Claims Specialist','UM/UIM Adjuster','UM/UIM Specialist',
										'Sr Commercial Claims and Litigation Specialist','Sr Commercial Liability Specialist')

		/* limit to pay periods defined by the exposure counting file from claims analytics */ 
		/* this took 15 min as compared to over an hour without dates restricting the query */
		and (EXPSR_HRCHY_MV.EXPSR_STRT_DT between TO_DATE(&from_date,'MM/DD/YYYY')and TO_DATE(&to_date,'MM/DD/YYYY')
			or EXPSR.CLS_DT between TO_DATE(&from_date,'MM/DD/YYYY')and TO_DATE(&to_date,'MM/DD/YYYY')
			or EXPSR_HRCHY_MV.EXPSR_END_DT between TO_DATE(&from_date,'MM/DD/YYYY')and TO_DATE(&to_date,'MM/DD/YYYY'))
		
	);

	DISCONNECT FROM CCDS;
QUIT;




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




data monthend_Liab_Exposure;
	set Exposures_Completed Exposures_New;
run;


proc sql;
	create table InternalServicesScored as
	select *
	from InternalServicesScored
	where strip(ClaimNumber)||strip(put(EXPSR_NTRL_ID,8.)) in (select strip(CLM_NR)||strip(put(EXPSR_NTRL_ID,8.)) from monthend_Liab_Exposure);
quit;


LIBNAME CCDS ORACLE PATH=CDEP1 SCHEMA=BRFADM Authdomain=Oracle_Auth_CCDS;
proc sql;
	create table AdjCRTL
	as select distinct
        USR_NTRL_ID,
        CRTL_NTRL_ID
    from CCDS.USR
    where rec_ret_in = 'N' and crnt_rec_in = 'Y' and USR_NTRL_ID in (select EXPSR_ASGN_USR_ID  from InternalServicesScored);
quit;
proc sql;
	create table AdjNum
	as select distinct
        CRTL_NTRL_ID,
        USR_NM
	from CCDS.CRTL
    where rec_ret_in = 'N' and crnt_rec_in = 'Y' and CRTL_NTRL_ID in (select CRTL_NTRL_ID  from AdjCRTL);
quit;
proc sql;
	create table AdjNumber as
	select a.*, b.*
	from AdjCRTL as a left join AdjNum as b
	on a.CRTL_NTRL_ID = b.CRTL_NTRL_ID;
quit;
   
 
proc sql;
	create table InternalServicesScored as
	select a.*, b.USR_NM
	from InternalServicesScored as a left join AdjNumber as b
	on a.EXPSR_ASGN_USR_ID = b.USR_NTRL_ID;
quit;


proc sql;
	create table dups
	as select *
	from InternalServicesScored group by CLAIMNUMBER, EXPSR_CLMT_NR, EXPSR_NTRL_ID, USR_NM having count(*)>1;
quit;

proc sort data= InternalServicesScored;
	by CLAIMNUMBER EXPSR_CLMT_NR EXPSR_NTRL_ID USR_NM ADJ_EXPO_STARTDATE;
run;
data InternalServicesScored;
	set InternalServicesScored;
	by CLAIMNUMBER EXPSR_CLMT_NR EXPSR_NTRL_ID USR_NM ADJ_EXPO_STARTDATE;
	format temp_start DATETIME30.9;
	retain temp_start;
	if first.USR_NM then temp_start=ADJ_EXPO_STARTDATE;
	ADJ_EXPO_STARTDATE=temp_start;
	if last.USR_NM then output;
run;

proc sql;
	create table dups2
	as select *
	from InternalServicesScored group by CLAIMNUMBER, EXPSR_CLMT_NR, EXPSR_NTRL_ID, USR_NM having count(*)>1;
quit;

proc sql;
	create table dups3
	as select *
	from InternalServicesScored group by CLAIMNUMBER, EXPSR_NTRL_ID, USR_NM having count(*)>1;
quit;


LIBNAME CCDS ORACLE PATH=CDEP1 SCHEMA=BRFADM Authdomain=Oracle_Auth_CCDS;

proc sql;
	create table 
		ClaimContact
	as
	select *
		
	from
		CCDS.CLM_CNTC ClaimContact
	where
		ClaimContact.CLM_NTRL_ID in (select CLM_NTRL_ID from InternalServicesScored)
	order by 
		ClaimContact.CLM_NTRL_ID;
quit;
proc sql;
	create table 
		Contact
	as
	select *
		
	from
		CCDS.CNTC Contact
	where
		Contact.CNTC_NTRL_ID in (select CNTC_NTRL_ID from ClaimContact)
	order by 
		Contact.CNTC_NTRL_ID;
quit;


proc sql;
	create table 
		Contact_type
	as
	select distinct CNTC_NTRL_ID, SBTYP_DC, 1 as Ind
		
	from
		Contact
	order by 
		CNTC_NTRL_ID;
quit;

PROC TRANSPOSE DATA=Contact_type OUT=Contact_type_transp prefix=Contact_;
	ID SBTYP_DC;
	VAR Ind;
	BY CNTC_NTRL_ID;
RUN;

proc sql;
	create table merged as
	select a.*, b.*
	from ClaimContact as a left join Contact_type_transp as b
	on a.CNTC_NTRL_ID = b.CNTC_NTRL_ID;
quit;

data merged (drop = i);
	set merged;

	array FillInZeros[*] Contact_Adjudicator Contact_Attorney Contact_Doctor Contact_Government Contact_LawFirm;
		do i=1 to hbound(FillInZeros);
	    	if FillInZeros[i]=. then FillInZeros[i]= 0;
	    end;
run;


proc sql;
	create table ClaimContact_count
	as select distinct CLM_NTRL_ID,
		count (distinct case when (CNTC_NM ne '') then CNTC_NTRL_ID end) as ContactCount,
		Max(Contact_Adjudicator) as Contact_Adjudicator,
		Max(Contact_Attorney) as Contact_Attorney,
		Max(Contact_Doctor) as Contact_Doctor,
		Max(Contact_Government) as Contact_Government,
		Max(Contact_LawFirm) as Contact_LawFirm
	from merged
	group by CLM_NTRL_ID;
quit;


proc sql;
	create table InternalServicesScored as
	select a.*, b.*
	from InternalServicesScored as a left join ClaimContact_count as b
	on a.CLM_NTRL_ID = b.CLM_NTRL_ID;
quit;










LIBNAME CCDS ORACLE PATH=CDEP1 SCHEMA=BRFADM Authdomain=Oracle_Auth_CCDS;



proc sql;
	create table 
		NOTESTABLE
	as
	select 
		note.CLM_NTRL_ID,
		note.NOTE_DC,
		note.SUBJ_DC,
		note.TPC_TYP_DC,
		note.EXPSR_NTRL_ID,
		note.LST_UPD_DT as Notes_LST_UPD_DT
	from
		CCDS.NOTE note
	where
		note.CLM_NTRL_ID in (select CLM_NTRL_ID from InternalServicesScored)
		and note.EXPSR_NTRL_ID in (select EXPSR_NTRL_ID from InternalServicesScored) /* added to only look at exposures that we are dealing with */
		and note.EXPSR_NTRL_ID is not null
		and note.NOTE_DC is not null
		and note.TPC_TYP_DC <> "Contact"  
	order by 
		note.CLM_NTRL_ID;
quit;


%changeColFormat2Char(NOTESTABLE, Notes_LST_UPD_DT, $50.)



data NOTESTABLE;
	set NOTESTABLE;

	length Notes $2000;
	Notes = catx(" ", NOTE_DC, SUBJ_DC);

	drop NOTE_DC;
	drop SUBJ_DC;
run;


proc sort data=NOTESTABLE;
	by CLM_NTRL_ID EXPSR_NTRL_ID Notes_LST_UPD_DT;
run;

data NOTESTABLE(keep= CLM_NTRL_ID EXPSR_NTRL_ID Notes_LST_UPD_DT long_Notes);
  do until (last.EXPSR_NTRL_ID);
    set NOTESTABLE;
    by CLM_NTRL_ID EXPSR_NTRL_ID;
    length long_Notes $32700;
    long_Notes = catx(' ', long_Notes, Notes);
  end;
run;

proc sql;
	create table dups
	as select distinct *
	from NOTESTABLE group by CLM_NTRL_ID, EXPSR_NTRL_ID, Notes_LST_UPD_DT having count(*)>1;
quit;




proc sql;
	create table NOTESTABLE_OLD as
	select *
	from NOTESTABLE
	where put(CLM_NTRL_ID,8.)||put(EXPSR_NTRL_ID,8.)||put(Notes_LST_UPD_DT,10.) in
	(select put(CLM_NTRL_ID,8.)||put(EXPSR_NTRL_ID,8.)||put(Notes_LST_UPD_DT,10.) from LiabPr.InternalServicesScored);
quit;

proc sql;
	create table NOTESTABLE_NEW as
	select *
	from NOTESTABLE
	where put(CLM_NTRL_ID,8.)||put(EXPSR_NTRL_ID,8.)||put(Notes_LST_UPD_DT,10.) not in
	(select put(CLM_NTRL_ID,8.)||put(EXPSR_NTRL_ID,8.)||put(Notes_LST_UPD_DT,10.) from LiabPr.InternalServicesScored);
quit;

%INCLUDE '/ere/local/shared/actuarial/Share/Claims/WPC/Liability/Score Code/Text Mining/Clean Text.sas';
%INCLUDE '/ere/local/shared/actuarial/Share/Claims/WPC/Liability/Score Code/Text Mining/Clean Text BI FNOL.sas';
%INCLUDE '/ere/local/shared/actuarial/Share/Claims/WPC/Liability/Score Code/Text Mining/Text Miner Word Table - Grid.sas';


options compress=yes;


DATA NOTESTABLE_NEW;
	SET NOTESTABLE_NEW;

	FORMAT long_Notes $1500.;  
	%cleantext(in_words=long_Notes,out_words=long_Notes,remove_numbers=0);

	
	%cleantext_BI_FNOL(long_Notes);

RUN;


%miner_table(NOTESTABLE_NEW, long_Notes, stopWordTbl=static.custom_stopwords, stopWordCol=stopword);







PROC SQL;
	CREATE TABLE 
		Stem_Claim AS
	SELECT
		*
	FROM
		SW_Claim.STEMWORDS_CLAIM_DETAILS
	WHERE
		word1_stem IN(SELECT
						Word
					  FROM
					  	Inj_Wd.INJURY_WORDS);
QUIT;


PROC SORT DATA=Stem_Claim;
	BY word1_stem;
RUN;

PROC TRANSPOSE DATA=Stem_Claim 
	OUT=Stem_Claim2 (DROP=_NAME_ _LABEL_); 
	BY word1_stem;
	VAR col:;
RUN;

DATA Stem_Claim2;
	SET Stem_Claim2;
	IF COL1 = '' THEN DELETE;
	RENAME COL1 = word_match;
RUN;

PROC SQL;
	CREATE TABLE 
		Stem_Claim_Final AS
	SELECT 
		l.word1_stem,
		l.word_match,
		r.level_inj AS InjuryLevelIncident, 
		max(r.attorney_inj) AS AttorneyClaim 
	FROM 
		Stem_Claim2 l 
		LEFT JOIN Inj_Wd.INJURY_WORDS r ON l.word1_stem = r.word
	GROUP BY
		l.word1_stem,
		l.word_match 
	ORDER BY
		l.word1_stem;
QUIT;
PROC SQL;

	
	CREATE TABLE 
		Minetbl_Final AS
	SELECT 
		L.recnum,
		min(r.InjuryLevelIncident) AS InjuryLevelIncident, 
		max(r.AttorneyClaim) AS AttorneyClaim
	FROM 
		Work.minetbl L 
		INNER JOIN Stem_Claim_Final R ON L.word1 = R.word_match
	GROUP BY 
		L.RecNum
	ORDER BY
		L.RecNum;


	CREATE TABLE 
		Claim_List2 AS
	SELECT
		a.*,
		CASE
			WHEN b.AttorneyClaim eq 1
			THEN 1
			ELSE 0
		END AS AttorneyClaim,
		CASE
			WHEN b.InjuryLevelIncident gt 0
			THEN b.InjuryLevelIncident
			ELSE 0
		END AS InjuryLevelIncident

	FROM
		NOTESTABLE_NEW a
		LEFT JOIN Minetbl_Final b ON a.RecNum = b.RecNum;
QUIT;

proc sql;
	create table Prior_Textmining
	as select distinct CLM_NTRL_ID, EXPSR_NTRL_ID, AttorneyClaim, InjuryLevelIncident, Notes_LST_UPD_DT
	from LiabPr.InternalServicesScored
	group by CLM_NTRL_ID, EXPSR_NTRL_ID;
quit;
proc sql;
	create table NOTESTABLE_OLD as
	select a.*, b.AttorneyClaim, b.InjuryLevelIncident, b.Notes_LST_UPD_DT
	from NOTESTABLE_OLD as a left join Prior_Textmining as b
	on a.CLM_NTRL_ID = b.CLM_NTRL_ID and a.EXPSR_NTRL_ID = b.EXPSR_NTRL_ID;
quit;

data NOTESTABLE;
	set Claim_List2 NOTESTABLE_OLD;
run;


proc sql;
	create table InternalServicesScored as
	select a.*, b.AttorneyClaim, b.InjuryLevelIncident, b.Notes_LST_UPD_DT
	from InternalServicesScored as a left join NOTESTABLE as b
	on a.CLM_NTRL_ID = b.CLM_NTRL_ID and a.EXPSR_NTRL_ID = b.EXPSR_NTRL_ID;
quit;










data InternalServicesScored;
	set InternalServicesScored;


	
	if InjuryLevelIncident = . then InjuryLevelIncident = -1; 
		else if InjuryLevelIncident = 0 then InjuryLevelIncident = 0; 
		else if InjuryLevelIncident = 9 then InjuryLevelIncident = 1; 
		else if InjuryLevelIncident = 6 then InjuryLevelIncident = 2; 
		else if InjuryLevelIncident = 5 then InjuryLevelIncident = 3; 
		else if InjuryLevelIncident = 4 then InjuryLevelIncident = 4; 
		else if InjuryLevelIncident = 3 then InjuryLevelIncident = 5; 
		else if InjuryLevelIncident = 2 then InjuryLevelIncident = 6; 
		else if InjuryLevelIncident = 1 then InjuryLevelIncident = 7; 

	
	format legal_ind 2.;			
	if (AttorneyClaim=1 or Contact_LawFirm=1 or Contact_Attorney=1 or Contact_Adjudicator=1 or RPT_BY_DC in ('Attorney','ClaimantAttorney')) then legal_ind=1;
		else if (AttorneyClaim=0 or Contact_LawFirm=0 or Contact_Attorney=0 or Contact_Adjudicator=0) then legal_ind=0;
		else if (AttorneyClaim=. or Contact_LawFirm=. or Contact_Attorney=. or Contact_Adjudicator=.) then legal_ind=-1;

	
	format EXPSR_TIER_DC_grp $30.;
	if EXPSR_TIER_DC in ('FrstPrtyMedLwCmplx','FrstPrtyMedHiCmplx') then EXPSR_TIER_DC_grp = 'FrstPrtyMed';
		else if EXPSR_TIER_DC in ('FrstPrtyPhysclDmgLwCmplx') then EXPSR_TIER_DC_grp = 'FrstPrtyPhysclDmgLwCmplx';
		else if EXPSR_TIER_DC in ('FrstPrtyPhysclDmgHiCmplx') then EXPSR_TIER_DC_grp = 'FrstPrtyPhysclDmgHiCmplx';
		else if EXPSR_TIER_DC in ('FrstPrtyCntntLwCmplx','FrstPrtyStrctrlDmgLwCmplx','LwCmplx','LossofUse') then EXPSR_TIER_DC_grp = 'LwCmplx';
		else if EXPSR_TIER_DC in ('MediumCmplx') then EXPSR_TIER_DC_grp = 'MediumCmplx';
		else if EXPSR_TIER_DC in ('HiCmplx','Indemnity','Medical','EmployersLiability') then EXPSR_TIER_DC_grp = 'HiCmplx';
		else if EXPSR_TIER_DC in ('ThrdPrtyMedLwCmplx','ThrdPrtyMedHiCmplx') then EXPSR_TIER_DC_grp = 'ThrdPrtyMed';
		else EXPSR_TIER_DC_grp = EXPSR_TIER_DC;

	
	format CT_SCAN_IN_temp 2.;
	if CT_SCAN_IN = '' then CT_SCAN_IN_temp = -1;
		else if CT_SCAN_IN = 'N' then CT_SCAN_IN_temp = 0;
		else CT_SCAN_IN_temp = 1;
	drop CT_SCAN_IN; 
 	rename CT_SCAN_IN_temp=CT_SCAN_IN;

	
	format TIER_TYP_DC_grp $30.;
	if TIER_TYP_DC not in ('MediumSeverity','LowSeverity') then TIER_TYP_DC_grp = 'HighSeverity';
		else TIER_TYP_DC_grp = TIER_TYP_DC;

	
	format AGGR_LMT_Ind 2.;
	if AGGR_LMT_AM = . then AGGR_LMT_Ind = 0; else AGGR_LMT_Ind = 1;

	
	ContactCount = min(ContactCount,20);

	
	format FLG_TYP_DC_Ind 2.;
	if FLG_TYP_DC = '' then FLG_TYP_DC_Ind = -1;
		else if FLG_TYP_DC = 'NeverFlagged' then FLG_TYP_DC_Ind = 0;
		else FLG_TYP_DC_Ind = 1;

	
	format PRIM_BODY_PART_TYP_Ind 2.;	
	if PRIM_BODY_PART_TYP_DC ='' then PRIM_BODY_PART_TYP_Ind=0;
		else PRIM_BODY_PART_TYP_Ind = 1;

	
	format AdjusterRole $50.;
	if Adjuster_Type in ('Sr Commercial Claims and Litigation Specialist','Commercial Liability Specialist') then AdjusterRole ='Commercial';
		else AdjusterRole= Adjuster_Type; 

	

	
	format INSD_FLT_TYP_DC_grp $40.;
	if INSD_FLT_TYP_DC in ('InsuredNotAtFault','OtherPartyAtFault') then INSD_FLT_TYP_DC_grp = 'OtherPartyAtFault';
		else if INSD_FLT_TYP_DC in ('UnderInvestigation','DisputedLiability','Contributory') then INSD_FLT_TYP_DC_grp = 'UnderInvestigation';
		else if INSD_FLT_TYP_DC = 'Accepted100PCT' then INSD_FLT_TYP_DC_grp = 'Accepted100PCT';
		else if INSD_FLT_TYP_DC = 'InsuredAtFault' then INSD_FLT_TYP_DC_grp = 'InsuredAtFault';
		else if INSD_FLT_TYP_DC = 'NoFault' then INSD_FLT_TYP_DC_grp = 'NoFault';
		
		else INSD_FLT_TYP_DC_grp = 'Missing_Other';

	
	format frst_iso_send_dt_Ind 2.;
	if FRST_ISO_SEND_DT = .  then frst_iso_send_dt_Ind = 0; else frst_iso_send_dt_Ind = 1;

	
	format FNOL_SRVY_IN_temp 2.;
	if FNOL_SRVY_IN = 'N' then FNOL_SRVY_IN_temp = 0; else FNOL_SRVY_IN_temp = 1;
	drop FNOL_SRVY_IN; 
 	rename FNOL_SRVY_IN_temp=FNOL_SRVY_IN;

	
	format TORT_OPT_Full_Ind 2.;	
	if TORT_OPT_DC ='FullTort' then TORT_OPT_Full_Ind=1;
		else if TORT_OPT_DC ='LimitedTort' then TORT_OPT_Full_Ind=0;
		else TORT_OPT_Full_Ind = -1;

	
	format EXPSR_TYP_DC_grp $40.;
	if EXPSR_TYP_DC in ('BodilyInjuryDamage') then EXPSR_TYP_DC_grp = 'BodilyInjuryDamage';
		else if EXPSR_TYP_DC in ('MedPay','PIPDamages') then EXPSR_TYP_DC_grp = 'MP_PIPDamage';
		else if EXPSR_TYP_DC in ('PropertyDamage') then EXPSR_TYP_DC_grp = 'PropertyDamage';
		else if EXPSR_TYP_DC in ('VehicleDamage','VesselDamage') then EXPSR_TYP_DC_grp = 'VehVslDamage';
		else if EXPSR_TYP_DC in ('TimeLoss','WCInjuryDamage','EmployerLiability') then EXPSR_TYP_DC_grp = 'WC_EPLIDamage';
		else if EXPSR_TYP_DC in ('LossOfUseDamage') then EXPSR_TYP_DC_grp = 'LossOfUseDamage';
		
		else if EXPSR_TYP_DC in ('GeneralDamage') and AdjusterRole='Commercial' then EXPSR_TYP_DC_grp = 'GeneralDamage';
		else EXPSR_TYP_DC_grp = 'Other';

	
	format LIEN_IN_temp 2.;	
	if LIEN_IN = '' then LIEN_IN_temp = -1;	
		else if LIEN_IN = 'N' then LIEN_IN_temp = 0;
		else LIEN_IN_temp = 1;
	drop LIEN_IN;	
	rename LIEN_IN_temp=LIEN_IN;

	
	format AutoMidHighComplexity_Ind 2.;
	if SGMNT_DC in ('AutoMidComplexity','AutoHighComplexity','') then AutoMidHighComplexity_Ind=1;
		else AutoMidHighComplexity_Ind = 0;

	
	format LOSS_CAUS_DC_grp $25.;
	if LOSS_CAUS_DC in('Collision2or3Veh') then LOSS_CAUS_DC_grp = 'Collision2or3Veh';
		else if LOSS_CAUS_DC in('CollisionFourPlusVeh','CollisionFourPlusVehGrg') then LOSS_CAUS_DC_grp = 'CollisionFourPlusVeh'; 
		else if LOSS_CAUS_DC in('CollisionClmntRearEndInsd') then LOSS_CAUS_DC_grp = 'CollisionClmntRearEndInsd';
		else if LOSS_CAUS_DC in('CollisionInsdRearEndClmnt') then LOSS_CAUS_DC_grp = 'CollisionInsdRearEndClmnt';
		else if substr(LOSS_CAUS_DC,1,9)='Collision' then LOSS_CAUS_DC_grp = 'CollisionOther';
		else if LOSS_CAUS_DC in('TheftOfEntireVehicle','TheftMissingLost') then LOSS_CAUS_DC_grp = 'TheftOfEntireVehicle';
		else if LOSS_CAUS_DC in('Weather') then LOSS_CAUS_DC_grp = 'Weather';
		else LOSS_CAUS_DC_grp = 'Other';

	format LC_CollisionMultiVeh 2.;
	if LOSS_CAUS_DC_grp in('Collision2or3Veh','CollisionFourPlusVeh') then LC_CollisionMultiVeh=1;
		else LC_CollisionMultiVeh=0;

	
	format HIT_AND_RUN_IN_temp 2.;	
	if HIT_AND_RUN_IN = '' then HIT_AND_RUN_IN_temp = -1;	
		else if HIT_AND_RUN_IN = 'N' then HIT_AND_RUN_IN_temp = 0;
		else HIT_AND_RUN_IN_temp = 1;
	drop HIT_AND_RUN_IN;	
	rename HIT_AND_RUN_IN_temp=HIT_AND_RUN_IN;

	
	if JURIS_STATE_DC not in ('DC','IL','IN','KY','MD','NC','NY','OH','PA','TN','VA','WI','WV') then JURIS_STATE_DC = 'OUT';

	
	if JURIS_STATE_DC='OUT' then Out_Of_State_Ind=2;
		else if USR_RPT_BRNCH_DC in ('Allentown') and JURIS_STATE_DC not in ('PA') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Canton','Columbus') and JURIS_STATE_DC not in ('OH') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Charlotte','Raleigh') and JURIS_STATE_DC not in ('NC') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Erie','Johnstown','Murrysville','Philadelphia','Pittsburgh','Harrisburg') and JURIS_STATE_DC not in ('PA') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Fort Wayne','Indiana') and JURIS_STATE_DC not in ('IN') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Hagerstown') and JURIS_STATE_DC not in ('MD') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Illinois') and JURIS_STATE_DC not in ('IL') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Kentucky') and JURIS_STATE_DC not in ('KY') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('New York') and JURIS_STATE_DC not in ('NY') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Richmond','Roanoke','Waynesboro') and JURIS_STATE_DC not in ('VA') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Silver Spring') and JURIS_STATE_DC not in ('MD','DC') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Tennessee') and JURIS_STATE_DC not in ('TN') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('West Virginia') and JURIS_STATE_DC not in ('WV') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('Wisconsin') and JURIS_STATE_DC not in ('WI') then Out_Of_State_Ind = 1;

		
		else if USR_RPT_BRNCH_DC in ('Greater Pennsylvania Zone') and JURIS_STATE_DC not in ('PA') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('North East Zone') and JURIS_STATE_DC not in ('DC','MD','NY','TN','PA','OH') then Out_Of_State_Ind = 1;
		else if USR_RPT_BRNCH_DC in ('South West Zone') and JURIS_STATE_DC not in ('IL','IN','KY','NC','VA','WV','WI') then Out_Of_State_Ind = 1;

		else Out_Of_State_Ind=0;

	
	format HO_PNTV_DMG_CNT_IN 2.;
	if PNTV_DMG_CNT_IN = '' then HO_PNTV_DMG_CNT_IN = -1;
		else if PNTV_DMG_CNT_IN = 'N' then HO_PNTV_DMG_CNT_IN = 0;
		else HO_PNTV_DMG_CNT_IN = 1;

	
	Report_Lag = max(intck('dtday', LOSS_DT, CRT_DT),-1); 
	Report_Lag = min(Report_Lag,30);
	if Report_Lag=-1 then Report_Lag=30;

	
	format LC_Weather 2.;
	if LOSS_CAUS_DC_grp='Weather' then LC_Weather=1;
		else LC_Weather=0;

	
	format Claimant_Age 3.;
	Claimant_Age = floor(YRDIF(datepart(BRTH_DT),datepart(RPT_DT),"AGE"));

	if Claimant_Age = . then Claimant_Age = -1;
		else if Claimant_Age < 0 then Claimant_Age=0;

	Claimant_Age = min(Claimant_Age,80);

	format Claimant_Under17_ind 2.;
	if 0<=Claimant_Age<=16 then Claimant_Under17_ind = 1;
		else Claimant_Under17_ind = 0;

	
	format LC_TheftOfEntireVehicle 2.;
	if LOSS_CAUS_DC_grp='TheftOfEntireVehicle' then LC_TheftOfEntireVehicle=1;
		else LC_TheftOfEntireVehicle=0; 
run;


data InternalServicesScored;
	set InternalServicesScored;
	FORMAT Cycle_Time 5.;
	Cycle_Time = intck('dtday', Adj_Expo_StartDate, Expo_CloseDate);
run;


%macro ExportCustom();

%if &flag. = 1 %then %do;
	PROC EXPORT DATA= InternalServicesScored
		OUTFILE= "/ere/local/shared/actuarial/Share/Claims/WPC/Liability/executable/Output/InternalServicesScored.csv"
		DBMS=CSV REPLACE;
	RUN;
%end;
%else %do;
	PROC EXPORT DATA= InternalServicesScored
		OUTFILE= "&output_path_csv/InternalServicesScored.csv"
		DBMS=CSV REPLACE;
	RUN;
%end;

%mend ExportCustom;

%ExportCustom();


data LiabAdj.InternalServicesScored;
	set InternalServicesScored;
run;






options validvarname=V7;




/*macro to change column type to number format*/
%macro changeColFormat2Num(table_name,col_list,format_new);

	%do i=1 %to %eval(%sysfunc(countc(&col_list.,"|"))+1);
		%let col_name = %sysfunc(scan(&col_list.,&i.,"|"));
/*		%put &col_name.;*/
		data &table_name.(drop= temp);
		set &table_name.(rename= &col_name. = temp);
		format &col_name. &format_new.;
		&col_name.=(temp*1.0);
		run;
	%end;
%mend changeColFormat2Num;

/*macro to change column type to number format*/
%macro changeColFormat2Char(table_name,col_list,format_new);

	%do i=1 %to %eval(%sysfunc(countc(&col_list.,"|"))+1);
		%let col_name = %sysfunc(scan(&col_list.,&i.,"|"));
/*		%put &col_name.;*/

		proc sql noprint;
		select type, length+2 into :col_type, :col_length
		from sashelp.vcolumn 
		where libname = 'WORK' and memname = upcase("&table_name.")
			and Name = "&col_name.";
		quit;
		
		%if %qupcase(&col_type.)NE CHAR %then %do;
			data &table_name.(drop= temp);
			set &table_name.(rename= &col_name. = temp);
			format &col_name. $&col_length..;
			&col_name.=Cats(temp);
			run;
		%end;
	%end;
%mend changeColFormat2Char;












/*PROC IMPORT DATAFILE='/ere/local/shared/actuarial/Share/Claims/WPC/Adj Prod by Liability_Template.xlsx' */
/*	DBMS=XLSX */
/*	REPLACE */
/*	OUT=both1;*/
/*	sheet=  "liabiltyWLHours";*/
/*	GETNAMES=yes; */
/*RUN;*/

PROC IMPORT DATAFILE='/ere/local/shared/actuarial/Share/Claims/WPC/TESTING 2/Adj Prod by Liability_Template.xlsx' 
	DBMS=XLSX 
	REPLACE 
	OUT=both1;
	sheet=  "liabiltyWLHours";
	GETNAMES=yes; 
RUN;






%changeColFormat2Char(BOTH1, AdjusterRegion|AdjusterTeamBranch|SupvNum|SupvNam|AdjPosition|AdjNm|AdjNumber|
								MaskEmpl|PayPeriodEnd|PayPeriodEnd|EmpPayPeriod|
								StartDateinPosition|HireDate, $50.)
%changeColFormat2Num(Both1,OldClaims|OldBIExposures|NewInjuryExposures|OpenInjuryExposures|
							CompletedInjuryExposures|NewNonInjuryExposures|OpenNonInjuryExposures|
							CompletedNonInjuryExposures, Best8.);
%changeColFormat2Num(Both1,TotalHoursWorked|TotalRegHrsPaid|TotalOTHrsPaid|TotalPTOHrsPaid, Best8.2);
 



proc sql noprint;
	select max(PayPeriodEnd_1) 
	into :enddate
	from both1;
quit;
proc sql noprint;
	select min(PayPeriodEnd_1) 
	into :startdate
	from both1;
quit;


%put &startdate;
%put &enddate;

%let cutoff=%sysfunc(inputn(22657, JULIANw.), mmddyy10.);
%put &cutoff;


%let cutoff=%sysfunc(inputn(&startdate, JULIANw.), mmddyy10.);
%put &cutoff;


%let from_date_temp=%sysfunc(inputn(%sysfunc(INTNX(day,&startdate,-14)),JULIANw.), mmddyy10.);
%put &from_date_temp;

%let from_date=%unquote(%str(%'&from_date_temp%'));
%put &from_date;

%let to_date_temp=%sysfunc(inputn(&enddate, JULIANw.), mmddyy10.);
%put &to_date_temp;

%let to_date=%unquote(%str(%'&to_date_temp%'));
%put &to_date;

	
	proc sql;
	   create table dups as 
	   select *
	      from both1
	      group by 'AdjNumber'n, 'PayPeriodEnd'n
	      having count(*) gt 1;
	quit;

	
	data both;
		set both1;
		format payperioddate mmddyy10.;

		keep 'AdjusterRegion'n 
		'AdjusterTeamBranch'n
		'AdjNm'n
		'AdjNumber'n
		'PayPeriodEnd'n
		'NewInjuryExposures'n -- 'TotalPTOHrsPaid'n
		'AdjPosition'n
		'SupvNum'n
		'SupvNam'n
		payperioddate
		;

		
		payperiodtemp = Put('PayPeriodEnd'n,8.);
		payperioddate = mdy(input(substr(payperiodtemp,5,2),2.),input(substr(payperiodtemp,7,2),2.),input(substr(payperiodtemp,1,4),4.));

	run;


data both (drop = i);
	set both;

	array FillInZeros[*] NewInjuryExposures -- CompletedNonInjuryExposures;
		do i=1 to hbound(FillInZeros);
	    	if FillInZeros[i]=. then FillInZeros[i]= 0;
	    end;
run;



PROC SQL;
	CREATE TABLE LiabAdj.hcoutput As
		Select
			'AdjusterRegion'n,	
			'AdjusterTeamBranch'n,	
			'AdjPosition'n,	
			'AdjNumber'n,	
			payperioddate,	
			NewInjuryExposures,
			OpenInjuryExposures,
			CompletedInjuryExposures,
			NewNonInjuryExposures,
			OpenNonInjuryExposures,
			CompletedNonInjuryExposures,		
			'TotalHoursWorked'n,
			'TotalRegHrsPaid'n,
			'TotalOTHrsPaid'n,
			'TotalPTOHrsPaid'n,	
			'SupvNum'n,
			'SupvNam'n,
			'AdjNm'n
		From both 
		where payperioddate >= &cutoff
	;
QUIT;


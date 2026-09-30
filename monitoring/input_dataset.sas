/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/




libname inlib "&WORKSPACE_PATH./ASBSAS/inlib/" compress=yes;
libname out "&WORKSPACE_PATH./ASBSAS/monitoring/data/" compress=yes;
libname model "&WORKSPACE_PATH./ASBSAS/models/" compress=yes;


/* %let dir_codes=%sysfunc(pathname(out)); */
%let dir_codes=&WORKSPACE_PATH./ASBSAS/out;

proc sql noprint;
select distinct _variable_,'GRP_'||trim(_variable_) 
into :zmienne separated by ' ',
:zmienne_grp separated by ' '
from model.Scorecard_scorecard1;
quit;
%put &zmienne;
%put &zmienne_grp;

/*proc sql noprint;*/
/*select 'inlib.'||memname into :sets separated by " " */
/*from dictionary.tables where*/
/*libname=upcase("INLIB") and memname like "ABT_%"; */
/*quit; */
%let in_abt=inlib.abt_app;
%let sets=&in_abt;
%put &sets;

/* Please copy belo lines directly from main.sas */
%macro Additional_variables;
length app_IGJM $ 30;
outstanding=app_loan_amount;
credit_limit=app_loan_amount;
app_IGJM = trim(app_char_gender)||'-'||trim(app_char_job_code)||
	'-'||trim(app_char_marital_status);
where '197501'<=period<='198712' and product='css' and decision='A';
%mend;


data out.abt;
	set &sets;
	if _error_ then _error_=0;
	%Additional_variables;
	keep &zmienne default: outstanding: credit_limit cross_response
	period ;
run;


%let zbior=out.abt;
%include "&dir_codes./scoring_code.sas" / source2;

proc delete data=out.abt;
run;

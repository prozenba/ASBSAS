/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/
/*For SAS Viya Workbench  */
%let prefix_dir=&WORKSPACE_PATH./ASBSAS/;

/*For SAS Viya  */
/* %let prefix_dir=/export/viya/homes/&SYSUSERID./ASBSAS/; */

%let nodedir=&prefix_dir.models/;

%let import_data=abt.train_woe;
%let import_validate=abt.valid_woe;

%let lib=out;

/*Train and Valid datsets*/
%let zb=abt.train;
%let zb_v=abt.valid;


/*Valiables definitions*/
%let data_variableset=out.variable_definition;

/*Scoring points variable*/
%let score_points=SCORECARD_POINTS;

/*Target order*/
/*For response models:*/
/*%let order_tar=descending;*/

/*For risk models:*/
%let order_tar=; 

/*Target variable*/
%let tar=default12;

/*Additional parameters to create more than one scorecards*/
%let the_best_model=1;

%let dir_codes=&prefix_dir.codes/;

%let in_abt=inlib.abt_app;
%let prop=0.5;

/**/
/*%let prop=2;*/
/*%let prop=0.02;*/
/*%let prop=0.25;*/
/*%let prop=0.08;*/

/*Libname creations*/
libname abt "&prefix_dir.abt" compress=yes;
libname out "&prefix_dir.out" compress=yes;
libname models "&prefix_dir.models";
libname freq "&prefix_dir.freq";
libname adj "&prefix_dir.adj";
libname inlib "&prefix_dir.inlib" compress=yes;

/*Two special macros to calculate Gini in various ways*/
%macro power(dataset,variable,default); 
	data power;
		powerpercent=.;
	run;

	proc sort data=&dataset(keep=&default &variable) out=pow_tmp1;
		by &variable;
	run;

	data pow_tmp2 / view=pow_tmp2;
		set pow_tmp1;
		integd+&default;
		integpcurve+integd;
		count+1;
	run;

	data power;
	    retain first;
		set pow_tmp2 end=e;
		if e;
		powerabs=integpcurve-integd/2; 
		powerden=integd*(count-integd)/2;
		powerpercent=(powerabs-count*integd/2)/powerden;
		format powerpercent percent10.2;
	run;
%mend power;

%macro powerc(dataset,variable,default); 
	data power;
		powerpercent=.;
	run;
	data powertable;
		set &dataset(keep=&variable &default);
		crit=-&variable;
	run;
	proc rank data=powertable out=tmp1 ties=high descending;
		var crit;
		ranks rang;
	run;

	proc sql;
		create table tmp2 as
		select
			rang,
			sum(&default) as defaults,
			count(*) as nobs 
		from tmp1 
		group by rang;
	quit;

	data tmp3;
		set tmp2;
		cumdef+defaults;
	run;

	data power;
		set tmp3 end=e;
		format powerpercent percent5.2;
		powerabs+nobs*defaults/2+(cumdef-defaults)*nobs; 
		powerden=cumdef*cumdef/2+cumdef*(rang-cumdef)-rang*cumdef/2;
		powerpercent=(powerabs-rang*cumdef/2)/powerden;
		if _error_=1 then _error_=0;
		if e;
	run;
%mend powerc;

/*Important macro to create new variables and define where statement*/
%macro Additional_variables;
length app_IGJM $ 30;
outstanding=app_loan_amount;
credit_limit=app_loan_amount;
app_IGJM = trim(app_char_gender)||'-'||trim(app_char_job_code)||
	'-'||trim(app_char_marital_status);
where '197501'<=period<='198712' and product='css' and decision='A';
%mend;


%include "&dir_codes.train_valid.sas" / source2;

/*Dataset with labels is important for variable reports*/
proc sql;
create table inlib.labels as
select name, label from dictionary.columns
where libname='ABT' and memname='TRAIN';
quit;


%include "&dir_codes.variable_definition.sas" / source2;


/*Maximal number of splitting points, number of categories minus one*/
%let max_n_splitting_points=5;
/*Minimal share of category*/
%let min_percent=3;
%include "&dir_codes.bining_nominal.sas" / source2;

%let min_percent=3;
%include "&dir_codes.bining_nominal_without_joining.sas" / source2;



/*Maximal number of splitting points, number of categories minus one*/
%let max_n_splitting_points=5;
/*Minimal share of category*/
%let min_percent=3;
%include "&dir_codes.tree.sas" / source2;


%macro calc_design;
%include "&dir_codes.coding.sas" / source2;
%include "&dir_codes.variable_pre_selection_1step.sas" / source2;
data &lib..good_variables_stat_1step;
set &lib..variables_stat_1step;
keep variable;
where ar_train>0.05;
run;
%include "&dir_codes.variable_pre_selection_full.sas" / source2;
data &lib..good_variables;
set &lib..variables_stat;
keep variable;
where ar_train>0.05 and .<abs(AR_Diff)<0.2 
and .<H_Br_GRP_TV<0.1 and .<H_GRP_TV<0.1
;
run;
%mend;




proc datasets lib=adj nolist kill;
quit;
%let Bining_int=&lib..Bining_int_nonmon;
%let bining_nominal=&lib..Bining_nominal;
/*%let bining_nominal=&lib..Bining_nominal_wj;*/

%let design=_non_mon;
%include "&dir_codes.variable_corrections.sas" / source2;
%calc_design;
data &lib..chosen_variables;
set &lib..good_variables;
variable=upcase(VARIABLE);
keep variable;
run;
%include "&dir_codes.variable_reports.sas" / source2;


%include "&dir_codes.steps_selection.sas" / source2;
%include "&dir_codes.score_selection.sas" / source2;

proc logistic data=abt.train_woe 
namelen=32 desc;
model &tar=
WOE_ACT9_N_ARREARS 
WOE_ACT_CC 
WOE_ACT_CCSS_DUEUTL 
WOE_ACT_CCSS_MIN_LNINST 
WOE_ACT_CCSS_N_STATC 
WOE_APP_CHAR_JOB_CODE 
WOE_APP_IGJM 
WOE_APP_INCOME
;
run;

%include "&dir_codes.expert_models.sas" / source2;

/*%let insets=&lib..Steps_models;*/
%let insets=&lib..Model_expert;
/*%let insets=&lib..Branch_models;*/
/**/
%include "&dir_codes.model_assessment.sas" / source2;

%let il_seed=100;
/*%let il_seed=10000;*/
/*%let il_seed=20000;*/
%include "&dir_codes.bootstrap_validation.sas" / source2;
%include "&dir_codes.ci_gini.sas" / source2;

%include "&dir_codes.final_report.sas" / source2;


%include "&dir_codes.scoring_code.sas" / source2;



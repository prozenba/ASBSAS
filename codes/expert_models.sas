/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/




/*modele experckie:*/

data subset;
length
method $ 200 control_var $ 1 NumberOfVariables 8 
ScoreChiSq 8 VariablesInModel $ 3000 sbc aic 8;
method='Expert';

VariablesInModel=
'WOE_ACT12_N_ARREARS 
WOE_ACT_CC 
WOE_ACT_CCSS_DUEUTL 
WOE_ACT_CCSS_MIN_LNINST 
WOE_ACT_CCSS_N_STATC 
WOE_APP_CHAR_JOB_CODE'
;

NumberOfVariables=6;
output;

run;



/**/
%let name_method=Method;
%let name_model=Model;
%let name_N_Var=N_Var;
%let name_ar_train=AR_Train;
%let name_ar_valid=AR_Valid;
%let name_vif=Max_VIF_Train;
%let name_corr=Max_Pearson_Train;
%let name_ConIndex=Max_Con_Index_Train;
%let name_ar_diff=AR_Diff;
%let name_max_probChiSq=Max_ProbChiSq;
%let name_min_WaldChiSq=Min_WaldChiSq;
%let def_var=length &name_method $200 &name_model $9000 &name_N_Var &name_ar_train &name_ar_valid &name_min_WaldChiSq &name_max_probChiSq &name_VIF &name_corr &name_conindex 8;
%let list_var=&name_method &name_model &name_N_Var &name_ar_train &name_ar_valid &name_min_WaldChiSq &name_max_probChiSq &name_VIF &name_corr &name_conindex;


%macro licz(method,zmienne,num_vars,train,valid);
%if %sysfunc(exist(a)) %then %do;
proc delete data=a;
run;
%end;

ods listing close;
ods output Association(persist=proc)=a ParameterEstimates=par;
proc logistic data=&train(keep=&tar &zmienne) desc outest=b namelen=32;
model &tar=&zmienne;
run;
ods output close;
ods listing;


%if %sysfunc(exist(a)) %then %do;


data zm;
length zm $ 9000 z $ 32;
/*zm="&zmienne";*/
zm=symget('zmienne');
do i=1 to &num_vars;
z=upcase(scan(zm,i,' '));
output;
end;
run;

proc sql noprint;
select z length=32 into :zm_sort separated by ' ' from zm order by 1; 
quit;
%put &zm_sort;

ods listing close;
ods output Association(persist=proc)=av;
proc logistic data=&valid(keep=&tar &zmienne) desc inest=b namelen=32;
model &tar=&zmienne / maxiter=0;
run;
ods output close;
ods listing;

data n;
set av;
where label2='c';
ar=2*nValue2-1;
call symput('ar_v',put(ar,best12.-L));
run;


ods listing close;
ods output ParameterEstimates(persist=proc)=p CollinDiag(persist=proc)=coll;
/*ods trace on / listing;*/
/*ods trace off;*/
proc reg data=&train(keep=&tar &zmienne);
model &tar=&zmienne / vif collin;
run;
quit;
ods output close;
ods listing;

proc sql noprint;
select max(VarianceInflation) into :vif from p;
select count(*) into :n_beta_minus from par
where estimate<0 and variable ne 'Intercept';

select max(ConditionIndex) into :conindex from coll;
select min(WaldChiSq), max(ProbChiSq) into :WaldChiSq,:ProbChiSq
from par;
quit;

proc corr data=&train(keep=&zmienne) outp=corr(where=(_TYPE_='CORR'))
noprint;
var &zmienne;
run;

data _null_;
set corr end=e;
array t(*) _numeric_;
retain m 0;
do i=_n_+1 to dim(t);
m=max(m,abs(t(i)));
/*put i= t(i)=;*/
end;
if e then call symput('max_corr',put(m,best12.-L));
run;
/*%put &max_corr;*/

data model;
&def_var;
set a;
where label2='c';
&name_ar_train=2*nValue2-1;
&name_VIF=&vif;
&name_method="&method";
&name_corr=&max_corr;
&name_Model=symget('zm_sort');
/*&name_Model=symget('zmienne');*/

&name_N_Var=&num_vars;
&name_ar_valid=&ar_v;
&name_conindex=&conindex;
&name_max_probChiSq=&ProbChiSq;
&name_min_WaldChiSq=&WaldChiSq;
n_beta_minus=&n_beta_minus;
format &name_max_probChiSq PVALUE6.4;
keep &list_var n_beta_minus;
run;

%end;
%mend;


%macro valid_list(inlist,outlist,train,valid);
data models;
&def_var;
length n_beta_minus 8;
format &name_max_probChiSq PVALUE6.4;
delete;
run;
data _null_;
set &inlist(obs=1) nobs=il;
call symput('num_models',put(il,best12.-L));
run;

%do k=1 %to &num_models;
proc sql noprint;
select VariablesInModel,NumberOfVariables,method
into :vars,:num,:met from &inlist(firstobs=&k obs=&k);
quit;
%LICZ(&met,&vars,&num,&train,&valid);
proc append base=models data=model;
run;
%end;

proc sort data=models nodupkey out=&outlist;
by &name_model;
/*by descending ar_train;*/
run;

proc print data=&outlist;
run;
%mend;

%valid_list(subset,&lib..model_expert,&import_data,&import_validate);


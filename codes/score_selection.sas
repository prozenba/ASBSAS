/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/




libname d (&lib);


/*%let ile_zmiennych_pewnych=1;*/


%let start=7;
%let stop=8;
%let best=5;

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
/*%put &def_var;*/
/*options nomprint;*/


/**/
/*proc sql noprint;*/
/*select 'WOE_'||upcase(trim(VARIABLE)) */
/*into :zmienne separated by ' ' from &lib..Good_variables(obs=75)*/
/*;*/
/*quit;*/
proc sql noprint;
select trim(Model) into :zmienne
from &lib..Steps_models(obs=1);
quit;
%put &zmienne *** &sqlobs;


%let interakcje=;




ods listing close;
ods output bestsubsets=score;
proc logistic 
data=&import_data(keep=&tar &zmienne &interakcje) desc namelen=32;
model &tar=&zmienne &interakcje / selection=score best=&best start=&start stop=&stop;
run;
ods output close;
ods listing;








data _null_;
set &import_data(keep=&tar obs=1) nobs=il;
call symput('obs',put(il,best12.-L));
stop;
run;
%put &obs;
data subset;
length method $200;
set score end=e;
sbc=-scorechisq+log(&obs)*
(numberofvariables+1);
aic=-scorechisq+2*
(numberofvariables+1); 
method="SCORE START=&START STOP=&STOP BEST=&BEST";
if e then call symput('num_models',put(_n_,best12.-L));
run;

proc sort data=subset;
by sbc;
run;


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

/*proc print data=&outlist;*/
/*run;*/
%mend;

/*tu sie okresla wszystko*/
%valid_list(subset,&lib..branch_models,&import_data,&import_validate);






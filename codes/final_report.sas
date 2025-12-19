/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



options ls=256;



%let train=sc_train;
%let valid=sc_valid;









%let prawiezero=0.000000001;
%let il_podzialow=30;
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
%let def_var=length &name_method $200 &name_model $9000 &name_N_Var &name_ar_train &name_ar_valid &name_ar_diff &name_min_WaldChiSq &name_max_probChiSq &name_VIF &name_corr &name_conindex 8;
%let list_var=&name_method &name_model &name_N_Var &name_ar_train &name_ar_valid &name_ar_diff &name_min_WaldChiSq &name_max_probChiSq &name_VIF &name_corr &name_conindex;


%let name_ks_score                     =KS_Score;            
%let name_h_score                      =H_Score;              
%let name_h_br_score                   =H_Br_Score;           
%let name_sd_score                     =SD_Score;             
%let name_max_dist_score               =Max_Dist_Score;       
%let name_max_dist_br_score            =Max_Dist_Br_Score;    
%let name_prop_sd_range                =Prop_Sd_Range;        
%let name_ar_score_train               =AR_Score_Train;       
%let name_ar_score_valid               =AR_Score_Valid;       
%let name_ar_score_diff                =AR_Score_Diff;        
%let name_max_abs_sd_zm                =Max_Abs_SD_Zm;        
%let name_prop_max_sd_range_zm         =Prop_Max_SD_Range_Zm; 
%let name_max_corr_valid            =Max_Pearson_Valid;    
%let name_max_vif_valid                =Max_Vif_Valid;        
%let name_max_coindex_valid            =Max_Con_Index_Valid;    

%let def_var_dluga=
length &name_method $200 &name_model $9000 &name_N_Var 
&name_ar_train &name_ar_valid &name_ar_diff 
&name_min_WaldChiSq &name_max_probChiSq 
&name_ar_score_train &name_ar_score_valid &name_ar_score_diff 
&name_ks_score &name_h_score &name_h_br_score 
&name_max_dist_score &name_max_dist_br_score 
&name_sd_score &name_prop_sd_range         
&name_max_abs_sd_zm &name_prop_max_sd_range_zm 
&name_VIF &name_max_vif_valid   
&name_corr &name_max_corr_valid  
&name_conindex &name_max_coindex_valid 8;
           
%let list_var_dluga=
&name_method &name_model &name_N_Var 
&name_ar_train &name_ar_valid &name_ar_diff 
&name_min_WaldChiSq &name_max_probChiSq 
&name_ar_score_train &name_ar_score_valid &name_ar_score_diff 
&name_ks_score &name_h_score &name_h_br_score 
&name_max_dist_score &name_max_dist_br_score 
&name_sd_score &name_prop_sd_range         
&name_max_abs_sd_zm &name_prop_max_sd_range_zm  
&name_VIF &name_corr &name_conindex 
&name_max_vif_valid &name_max_corr_valid &name_max_coindex_valid;
        
proc format;
picture procent (round)
low- -0.005='00.000.000.009,99 %'
(decsep=',' 
dig3sep='.'
fill=' '
prefix='-')
-0.005-high='00.000.000.009,99 %'
(decsep=',' 
dig3sep='.'
fill=' ')
;
run;



%macro przygotuj_histogramy(train,valid,variable);
proc freq data=&train noprint;
table &variable / missing out=ft;
run;
proc freq data=&valid noprint;
table &variable / missing out=fv;
run;
data ft;
set ft;
okres="Train";
run;
data fv;
set fv;
okres="Valid";
run;

data freq_wspolne;
merge 
ft(rename=(percent=percentt count=countt))
fv(rename=(percent=percentv count=countv));
by &variable;
count=sum(countt,countv);
drop okres;
run; 

/*proc sql noprint;*/
/*select max(&variable),min(&variable) into :max,:min*/
/*from freq_wspolne;*/
/*quit;*/
proc means data=freq_wspolne nway noprint;
var &variable;
freq count;
output out=st p1()=min p99()=max;
run;
data _null_;
set st;
call symput('min',put(min,best12.-L));
call symput('max',put(max,best12.-L));
run;
/*%put ***&MAX***&MIN***;*/


data rangi;
set freq_wspolne;
do i=1 to &il_podzialow;
if &variable>=&min+(i-1)*(&max-&min)/&il_podzialow then do;
  ranga=i;
  srodek=&min+(i-1+0.5)*(&max-&min)/&il_podzialow;
  end;
end;
where &variable between &min and &max;
run;

/*proc rank data=freq_wspolne out=rangi groups=&il_podzialow;*/
/*var &variable;*/
/*ranks ranga;*/
/*run;*/

/*proc means data=rangi noprint nway;*/
/*class ranga;*/
/*var &variable percent_200406 percent_200412;*/
/*output out=wyk2 mean(&variable)=&variable sum(percent&okres1)=&okres1 */
/*sum(percent&okres2)=&okres2;*/
/*run; */

proc means data=rangi noprint nway;
class ranga;
var srodek percentt percentv;
output out=wyk2 mean(srodek)=&variable sum(percentt)=Train 
sum(percentv)=Valid;
run; 

proc transpose data=wyk2 out=zb_wyk(rename=(col1=Percent _name_=Period));
var train valid;
by &variable;
run;
proc sort data=zb_wyk;
by period &variable;
run;

data zb_wykm wykm;
delete;
run;

proc means data=Freq_wspolne noprint nway;
var percentt percentv;
output out=wykm sum(percentt)=Train 
sum(percentv)=Valid;
where missing(&variable);
run; 
proc transpose data=wykm out=zb_wykm(rename=(col1=Percent _name_=Period));
var train valid;
run;
proc sort data=zb_wykm;
by period;
run;

data zb_wyk;
length &variable $12;
set zb_wyk(rename=(&variable=old)) zb_wykm(in=z);
&variable=put(old,30.4-L);
if z then &variable='Missing';
drop old _LABEL_;
run;

proc gchart data=zb_wyk;
block &variable / group=period type=sum sumvar=percent 
discrete patternid=group;
label period='Period';
format percent procent.;
run;
quit;
%mend;



%macro przygotuj_histogramy_score(train,valid,variable);
proc freq data=&train noprint;
table &variable / missing out=ft;
run;
proc freq data=&valid noprint;
table &variable / missing out=fv;
run;
data ft;
set ft;
okres="Train";
run;
data fv;
set fv;
okres="Valid";
run;

data freq_wspolne;
merge 
ft(rename=(percent=percentt count=countt))
fv(rename=(percent=percentv count=countv));
by &variable;
count=sum(countt,countv);
drop okres;
run; 

/*proc sql noprint;*/
/*select max(&variable),min(&variable) into :max,:min*/
/*from freq_wspolne;*/
/*quit;*/
proc means data=freq_wspolne nway noprint;
var &variable;
freq count;
output out=st min()=min max()=max;
run;
data _null_;
set st;
call symput('min',put(min,best12.-L));
call symput('max',put(max,best12.-L));
run;
/*%put ***&MAX***&MIN***;*/


data rangi;
set freq_wspolne;
do i=1 to &il_podzialow;
if &variable>=&min+(i-1)*(&max-&min)/&il_podzialow then do;
  ranga=i;
  srodek=&min+(i-1+0.5)*(&max-&min)/&il_podzialow;
  end;
end;
where &variable between &min and &max;
run;

/*proc rank data=freq_wspolne out=rangi groups=&il_podzialow;*/
/*var &variable;*/
/*ranks ranga;*/
/*run;*/

/*proc means data=rangi noprint nway;*/
/*class ranga;*/
/*var &variable percent_200406 percent_200412;*/
/*output out=wyk2 mean(&variable)=&variable sum(percent&okres1)=&okres1 */
/*sum(percent&okres2)=&okres2;*/
/*run; */

proc means data=rangi noprint nway;
class ranga;
var srodek percentt percentv;
output out=wyk2 mean(srodek)=&variable sum(percentt)=Train 
sum(percentv)=Valid;
run; 

proc transpose data=wyk2 out=zb_wyk(rename=(col1=Percent _name_=Period));
var train valid;
by &variable;
run;
proc sort data=zb_wyk;
by period &variable;
run;

data zb_wykm wykm;
delete;
run;

proc means data=Freq_wspolne noprint nway;
var percentt percentv;
output out=wykm sum(percentt)=Train 
sum(percentv)=Valid;
where missing(&variable);
run; 
proc transpose data=wykm out=zb_wykm(rename=(col1=Percent _name_=Period));
var train valid;
run;
proc sort data=zb_wykm;
by period;
run;

data zb_wyk;
length &variable $12;
set zb_wyk(rename=(&variable=old)) zb_wykm(in=z);
&variable=put(old,12.-L);
if z then &variable='Missing';
drop old _LABEL_;
run;

proc gchart data=zb_wyk;
block &variable / group=period type=sum sumvar=percent 
discrete patternid=group;
label period='Period';
format percent procent.;
run;
quit;
%mend;



%macro przygotuj_histogramy_n(train,valid,variable);
proc freq data=&train noprint;
table &variable / missing out=ft;
run;
proc freq data=&valid noprint;
table &variable / missing out=fv;
run;
data ft;
set ft;
Period="Train";
run;
data fv;
set fv;
Period="Valid";
run;
data zb_wyk;
set ft fv;
keep &variable Period percent;
run;

proc gchart data=zb_wyk;
block &variable / group=period type=sum sumvar=percent 
discrete patternid=group;
label 
period='Period'
percent='Percent'
&variable="&variable";
format percent procent.;
run;
quit;
%mend;



%macro przygotuj_histogramy_br(train,valid,variable);
proc means data=&train noprint nway;
class &variable;
var &tar;
output out=ft(drop=_freq_ _type_) mean()=br;
run;
proc means data=&valid noprint nway;
class &variable;
var &tar;
output out=fv(drop=_freq_ _type_) mean()=br;
run;
data ft;
set ft;
Period="Train";
run;
data fv;
set fv;
Period="Valid";
run;
data zb_wyk;
set ft fv;
format br nlpct12.2;
keep &variable Period br;
run;

proc gchart data=zb_wyk;
block &variable / group=period type=sum sumvar=br 
discrete patternid=group;
label 
period='Period'
br='Bad rate'
&variable="&variable";
run;
quit;
%mend;




/*na nowo tworzymy listê zmiennych &zmienne*/
proc sql noprint;
select distinct upcase('WOE_'||trim(Variable)),
quote(upcase(Variable)),
upcase('WOE_'||trim(Variable))||'=T_'||trim(upcase(Variable)),
upcase('WOE_'||trim(Variable))||'=V_'||trim(upcase(Variable)),
'T_'||trim(upcase(Variable)),
'V_'||trim(upcase(Variable)),
'GRP_'||trim(upcase(Variable)),
trim(upcase(Variable))
into :zmienne separated by ' ',
:zm_wciapkach separated by ',',
:renamet separated by ' ',
:renamev separated by ' ',
:zmiennet separated by ' ',
:zmiennev separated by ' ',
:zmiennegrp separated by ' ',
:zmienneorg separated by ' '
from models.Scorecard_Scorecard&the_best_model(rename=(_variable_=variable)) 
where variable ne "Intercept"
order by 1;
%let ilz=&sqlobs;
quit;

%put &ilz;
%put &zmienne;
%put &zmiennet;
%put &zmiennev;
%put &renamet;
%put &renamev;
%put &zmiennegrp;
%put &zmienneorg;
%put &zm_wciapkach;



/*skorowanie zbiorów*/
data kar;
set models.Scorecard_Scorecard&the_best_model(rename=(_variable_=variable));
variable=upcase(variable);
run;
proc sort data=kar;
by variable _group_;
run;
data kar;
set kar;
by variable;
if first.variable then nr+1;
keep variable nr _group_ &score_points;
run;

data &train;
array pt(&ilz,100);
array zmgrp(&ilz) &zmiennegrp;
do i=1 to il;
set kar nobs=il;
pt(nr,_group_)=&score_points;
end;

do i=1 to ild;
set  &import_data nobs=ild;
&score_points=0;
do z=1 to &ilz;
  gr=zmgrp(z);
  &score_points=sum(&score_points,pt(z,gr));
end;
output;
end;
keep &score_points &tar &zmiennegrp &zmienne &zmienneorg;
run;

data &valid;
array pt(&ilz,100);
array zmgrp(&ilz) &zmiennegrp;
do i=1 to il;
set kar nobs=il;
pt(nr,_group_)=&score_points;
end;

do i=1 to ild;
set  &import_validate nobs=ild;
&score_points=0;
do z=1 to &ilz;
  gr=zmgrp(z);
  &score_points=sum(&score_points,pt(z,gr));
end;
output;
end;
keep &score_points &tar &zmiennegrp &zmienne &zmienneorg;
run;





/*policzenie skali modelu*/
proc sort data=models.Scorecard_scorecard&the_best_model out=ms(keep=
_variable_ _group_  _event_rate_ SCORECARD_POINTS);
by _variable_ SCORECARD_POINTS;
where _group_ ne -2;
run;

data skala;
retain min max (0,0);
set ms end=e;
by _variable_;
if first._variable_ then min=sum(min,SCORECARD_POINTS);
if last._variable_ then max=sum(max,SCORECARD_POINTS);
skala=max-min;
if e;
call symput('min',put(min,best12.-L));
call symput('max',put(max,best12.-L));
call symput('skala',put(skala,best12.-L));
keep max min skala;
run;






data _null_;
set skala;
call symput('range_score',put(skala,best12.-L));
run;
%put &range_score;

proc sort data=models.Scorecard_scorecard&the_best_model out=kar;
by _group_;
where _group_ ne -2;
run;

proc transpose data=kar out=t prefix=woe_;
by _group_;
id _variable_;
var &score_points;
run;
data _null_;
set t(obs=1) nobs=il;
call symput('il_grp',put(il,best12.-L));
run;
%put &il_grp;

data scores_train;
array t(&ilz) &zmienne;
array sc(&il_grp,&ilz);
array grp(&ilz) &zmiennegrp;
do o=1 to &il_grp;
	set t;
	do i=1 to &ilz;
	sc(o,i)=t(i);
	end;
end;

do o=1 to ilobs;
	set &train nobs=ilobs;
	do i=1 to &ilz;
	t(i)=sc(grp(i),i);
	end;
	output;
end;
keep &zmienne &score_points &tar;
run;


data scores_valid;
array t(&ilz) &zmienne;
array sc(&il_grp,&ilz);
array grp(&ilz) &zmiennegrp;
do o=1 to &il_grp;
	set t;
	do i=1 to &ilz;
	sc(o,i)=t(i);
	end;
end;

do o=1 to ilobs;
	set &valid nobs=ilobs;
	do i=1 to &ilz;
	t(i)=sc(grp(i),i);
	end;
	output;
end;
keep &zmienne &score_points &tar;
run;


/*liczenie ks_score */
data t;
set scores_train(keep=&score_points);
okres="t";
run;
data v;
set scores_valid(keep=&score_points);
okres="v";
run;
data r;
set t v;
run; 
proc npar1way data=r edf wilcoxon noprint;
class okres;
var &score_points;
output out=ks wilcoxon edf;
run;
data _null_;
set ks;
call symput('ks_score',put(_d_,best12.-L));
run;
%put &ks_score;

/*liczenie*/
/*h_score h_br_score sd_score prop_sd_range*/
/*max_dist_score max_dist_br_score */

proc means data=scores_train(keep=&score_points &tar) noprint;
ways 0 1;
class &score_points;
var &tar;
output out=st(drop=_type_ _freq_) sum()=st n()=nt;
run;

data st;
retain sss ssn;
set st;
if _n_=1 then do;
sss=st; ssn=nt;
end;
else do;
st=st/sss;
nt=nt/ssn;
output;
end;
keep &score_points st nt;
run;

proc means data=scores_valid(keep=&score_points &tar) noprint;
ways 0 1;
class &score_points;
var &tar;
output out=sv(drop=_type_ _freq_) sum()=sv n()=nv;
run;

data sv;
retain sss ssn;
set sv;
if _n_=1 then do;
sss=sv; ssn=nv;
end;
else do;
sv=sv/sss;
nv=nv/ssn;
output;
end;
keep &score_points sv nv;
run;

data r;
merge st sv;
by &score_points;
run;

data w_score;
set r end=e;
retain &name_h_score &name_h_br_score &name_sd_score
&name_max_dist_score &name_max_dist_br_score 0;
array t(4) sv nv st nt;
do i=1 to 4;
if missing(t(i)) then t(i)=0;
end;
&name_max_dist_score=max(&name_max_dist_score,abs(nt-nv));
&name_max_dist_br_score=max(&name_max_dist_score,abs(st-sv));
&name_sd_score=sum(&name_sd_score,&score_points*(nt-nv));
do i=1 to 4;
if t(i)=0 then t(i)=&prawiezero;
end;
&name_h_score=sum(&name_h_score,nt*log(nt/nv));
&name_h_br_score=sum(&name_h_br_score,st*log(st/sv));
keep &name_h_score &name_h_br_score &name_sd_score
&name_max_dist_score &name_max_dist_br_score &name_prop_sd_range;
format &name_prop_sd_range percent12.4;
if e;
&name_prop_sd_range=abs(&name_sd_score)/&range_score;
run;


/*liczenie*/
/*max_abs_sd_zm prop_max_sd_range_zm */

proc means data=scores_train(keep=&zmienne &tar) noprint;
ways 0 1;
class &zmienne;
var &tar;
output out=st(drop=_freq_) n()=nt;
run;

proc sort data=st;
by _type_ &zmienne;
run;

data st;
retain ssn;
set st;
if _n_=1 then ssn=nt;
else do;
nt=nt/ssn;
output;
end;
drop ssn;
/*rename &renamet;*/
run;

proc means data=scores_valid(keep=&zmienne &tar) noprint;
ways 0 1;
class &zmienne;
var &tar;
output out=sv(drop=_freq_) n()=nv;
run;

proc sort data=sv;
by _type_ &zmienne;
run;

data sv;
retain ssn;
set sv;
if _n_=1 then ssn=nv;
else do;
nv=nv/ssn;
output;
end;
drop ssn;
/*rename &renamev;*/
run;

data r;
merge st sv;
by _type_ &zmienne;
rename &renamet;
run;

data w;
set r end=e;
retain &zmienne 0;
array org (&ilz) &zmienne;
array orgt (&ilz) &zmiennet;
array t(2) nv nt;
do i=1 to 2;
if missing(t(i)) then t(i)=0;
end;
do i=1 to &ilz;
if not missing(orgt(i)) then org(i)=sum(org(i),orgt(i)*(nt-nv));;
end;
keep &zmienne;
if e;
run;

proc transpose data=w out=t1(rename=(col1=sd_zm));
var &zmienne;
run;
proc sort data=t1;
by _name_;
run;

proc means data=models.Scorecard_scorecard&the_best_model nway noprint;
var &score_points;
class _variable_;
output out=sc(keep=_variable_ range_zm rename=(_variable_=_name_)) range()=range_zm;
run;
data sc;
set sc;
_name_='WOE_'||trim(upcase(_name_));
run;

data r;
length _name_ $32;
merge t1 sc;
by _name_;
run;

data r;
set r;
prop_sd_zm=abs(sd_zm)/range_zm;
run;

data sd_zmienne;
set r;
_name_=substr(_name_,5);
run;

proc sql noprint;
select max(abs(sd_zm)),max(prop_sd_zm) into :max_abs_sd_zm, :prop_max_sd_range_zm
from r;
quit;
%put &max_abs_sd_zm &prop_max_sd_range_zm;

/*liczenie vif i corr*/
/*train*/
ods listing close;
ods output ParameterEstimates(persist=proc)=p CollinDiag(persist=proc)=coll;
proc reg data=&train(keep=&tar &zmienne);
model &tar=&zmienne / vif collin;
run;
quit;
ods output close;
ods listing;

proc sql noprint;
select max(VarianceInflation) into :vif_t from p;
select max(ConditionIndex) into :conindex_t from coll;
quit;
/*valid*/
ods listing close;
ods output ParameterEstimates(persist=proc)=p CollinDiag(persist=proc)=coll;
proc reg data=&valid(keep=&tar &zmienne);
model &tar=&zmienne / vif collin;
run;
quit;
ods output close;
ods listing;

proc sql noprint;
select max(VarianceInflation) into :vif_v from p;
select max(ConditionIndex) into :conindex_v from coll;
quit;

/*train*/
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
if e then call symput('max_corr_t',put(m,best12.-L));
run;

/*valid*/
proc corr data=&valid(keep=&zmienne) outp=corr(where=(_TYPE_='CORR'))
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
if e then call symput('max_corr_v',put(m,best12.-L));
run;





ods listing close;
ods output Association(persist=proc)=a;
proc logistic data=Scores_train(keep=&tar &score_points) desc outest=b namelen=32;
model &tar=&score_points;
run;
proc logistic data=Scores_valid(keep=&tar &score_points) desc inest=b namelen=32;
model &tar=&score_points / maxiter=0;
run;
ods output close;
ods listing;

data n;
set a;
where label2='c';
ar=2*nValue2-1;
if _n_=1 then call symput('ar_t',put(ar,best12.-L));
if _n_=2 then call symput('ar_v',put(ar,best12.-L));
run;
%put &ar_t &ar_v;

/*%include kat_cal("testy_power.sas");*/
%powerc(Scores_train,&score_points,&tar);
data _null_;
set power;
call symput("ps_train",put(powerpercent,best12.-L));
run;
%put &ps_train;

%powerc(Scores_valid,&score_points,&tar);
data _null_;
set power;
call symput("ps_valid",put(powerpercent,best12.-L));
run;
%put &ps_valid;

data model;
&def_var_dluga;
length ps_valid ps_train ps_diff 8;

format &name_max_probChiSq PVALUE6.4;
format &name_prop_max_sd_range_zm &name_prop_sd_range percent12.4;
format &name_ar_diff &name_ar_score_diff ps_diff percent12.2;

set w_score;

ps_valid=&ps_valid;
ps_train=&ps_train;
ps_diff =(ps_train-ps_valid)
/ps_train;


&name_ks_score=&ks_score;
&name_ar_score_train=&ar_t;        
&name_ar_score_valid=&ar_v; 
&name_ar_score_diff =(&name_ar_score_train-&name_ar_score_valid)
/&name_ar_score_train;

&name_max_abs_sd_zm=&max_abs_sd_zm;
&name_prop_max_sd_range_zm=&prop_max_sd_range_zm;

&name_max_corr_valid=&max_corr_v;
&name_max_vif_valid=&vif_v;
&name_max_coindex_valid=&conindex_v;


&name_corr=&max_corr_t;
&name_vif=&vif_t;
&name_ConIndex=&conindex_t;

keep &list_var_dluga ps_train ps_valid ps_diff;
run;




%let name_ks_01_train       =KS_01_Train        ;
%let name_h_01_train        =H_01_Train         ;
%let name_max_dist_01_train =Max_Dist_01_Train  ;
%let name_ks_01_valid       =KS_01_Valid        ;
%let name_h_01_valid        =H_01_Valid         ;
%let name_max_dist_01_valid =Max_Dist_01_Valid  ;
%let name_c_01_diff         =C_01_Diff          ;
%let name_c_01_train         =C_01_Train        ;
%let name_c_01_valid         =C_01_Valid        ;
%let name_ks_01_diff        =KS_01_Diff         ;
%let name_h_01_diff         =H_01_Diff          ;
%let name_max_dist_01_diff  =Max_Dist_01_Diff   ;
%let name_pr_mfrequent_train     =PR_mfrequent_Train      ; 
%let name_mfrequent_train        =mfrequent_Train         ; 
%let name_pr_miss_train     =PR_Miss_Train      ; 
%let name_n_uni_train       =N_Uni_Train        ;
%let name_pr_mfrequent_valid     =PR_mfrequent_Valid      ; 
%let name_mfrequent_valid        =mfrequent_Valid         ; 
%let name_pr_miss_valid     =PR_Miss_Valid      ; 
%let name_n_uni_valid       =N_Uni_Valid        ;
%let name_h_tv              =H_TV               ; 
%let name_h_br_tv           =H_Br_TV            ; 
%let name_ks_tv             =KS_TV              ; 
%let name_ks_br_tv          =KS_Br_TV           ;
%let name_ar_diff           =AR_Diff            ;
%let name_ar_train          =AR_Train           ;
%let name_ar_valid          =AR_Valid           ;
%let name_h_grp_train       =H_GRP_Train        ; 
%let name_max_dist_grp_train=Max_Mist_GRP_Train ;
%let name_h_grp_valid       =H_GRP_Valid        ; 
%let name_max_dist_grp_valid=Max_Dist_GRP_Valid ;
%let name_h_grp_diff        =H_GRP_Diff         ; 
%let name_max_dist_grp_diff =Max_Dist_GRP_Diff  ;
%let name_h_grp_tv          =H_GRP_TV           ; 
%let name_max_dist_grp_tv   =Max_Dist_GRP_TV    ;
%let name_h_br_grp_tv       =H_Br_GRP_TV        ;
%let name_max_br_dist_grp_tv=Max_Br_Dist_GRP_TV ;










goptions reset=all device=png;
ods listing close;
ods html path="&nodedir"(url=none) body='Report.html' contents='contents.html'
frame='index.html' style=Statistical;

title 'Variables in the model';
proc transpose data=&train(obs=1) out=zm;
var &zmienne;
run;
data zm;
set zm;
_NAME_=substr(_NAME_,5);
run;
ods proclabel='Variables in the model';
proc print data=zm label noobs;
var _name_;
label _name_='Name' ;
run; 

%let condition=1;
/*%let condition=_variable_ in (&zm_wciapkach);*/


title 'Statistics for original variables';
title2 'Quality of variables';
ods proclabel='Quality of variables';
proc print data=&lib..variables_stat label noobs;
var VARIABLE level 
&name_PR_Miss_Train &name_PR_Miss_Valid 
&name_N_Uni_Train &name_N_Uni_Valid 
&name_PR_mfrequent_Train &name_PR_mfrequent_Valid 
&name_mfrequent_Train &name_mfrequent_Valid ;
label
VARIABLE='Name'
level='Measure'
&name_PR_Miss_Train='Percent of missing valuses in training dataset' 
&name_PR_Miss_Valid='Percent of missing valuses in validating dataset' 
&name_N_Uni_Train='Number of distinct values in training dataset'
&name_N_Uni_Valid='Number of distinct values in validating dataset' 
&name_PR_mfrequent_Train='Percent of most frequent nonmissing value in training dataset' 
&name_PR_mfrequent_Valid='Percent of most frequent nonmissing value in validating dataset' 
&name_mfrequent_Train='Most frequent nonmissing value in training dataset' 
&name_mfrequent_Valid='Most frequent nonmissing value in validating dataset' 
;
where &condition;
run;




title 'Statistics for original variables';
title2 'Univariate discriminant power of variables';
ods proclabel='Univariate discriminant power of variables';
proc print data=&lib..variables_stat label noobs;
var VARIABLE level 
KS_01_Train 
KS_01_Valid
H_01_Train 
H_01_Valid
Max_Dist_01_Train 
Max_Dist_01_Valid
C_01_Train 
C_01_Valid
/*PS_Org_train*/
/*PS_Org_valid*/
;
label
VARIABLE='Name'
level='Measure'
KS_01_Train='Kolmogorov-Smirnov between gods and bads in training dataset'
KS_01_Valid='Kolmogorov-Smirnov between gods and bads in validating dataset'
H_01_Train='Kullback-Leibrer distance between gods and bads in training dataset'
H_01_Valid='Kullback-Leibrer distance between gods and bads in validating dataset'
Max_Dist_01_Train='Percent distance between gods and bads in training dataset' 
Max_Dist_01_Valid='Percent distance between gods and bads in validating dataset'
C_01_Train='Area under the ROC between gods and bads in training dataset'
C_01_Valid='Area under the ROC between gods and bads in validating dataset'
/*PS_Org_train='Power statistic in training dataset'*/
/*PS_Org_valid='Power statistic in validating dataset'*/
;

where &condition;
run;




title 'Statistics for original variables';
title2 'Univariate stability power of variables';
ods proclabel='Univariate stability power of variables';
proc print data=&lib..variables_stat label noobs;
var VARIABLE level 
KS_01_Diff  H_01_Diff 
Max_Dist_01_Diff C_01_Diff
H_TV H_Br_TV KS_TV KS_Br_TV 
/*PS_Org_Diff*/
;
label
VARIABLE='Name'
level='Measure'
KS_01_Diff='Difference Kolmogorov-Smirnov on gods/bads between training and validating datasets'
H_01_Diff='Difference Kullback-Leibrer on gods/bads between training and validating datasets' 
Max_Dist_01_Diff='Difference Percent distance on gods/bads between training and validating datasets' 
C_01_Diff='Difference Area under the ROC on gods/bads between training and validating datasets' 
H_TV='Kullback-Leibrer between training and validating datasets'  
H_Br_TV='Kullback-Leibrer only for bads between training and validating datasets'  
KS_TV='Kolmogorov-Smirnov between training and validating datasets'  
KS_Br_TV='Kolmogorov-Smirnov only for bads between training and validating datasets'  
/*PS_Org_Diff='Difference Power statistic between training and validating datasets' */

;
where &condition;
run;

/*wykresy grp*/
%macro wykresy_org;
%do i=1 %to &ilz;
%let z=%scan(&zmienneorg,&i,%str( ));

proc sql noprint;
select level into :level
from &lib..variables_stat
where upcase(VARIABLE)=upcase("&z");
quit;

%if &sqlobs=1 %then %do;
	title "Stability of &level &z graph";
	title2;
	ods proclabel="Stability of original &level &z graph";
	%if &level eq INT %then %do;
		%przygotuj_histogramy(&train,&valid,&z);
	%end; %else %do;
		%przygotuj_histogramy_n(&train,&valid,&z);
	%end;
%end;

%end;
%mend;
%wykresy_org;



title 'Statistics for transformed variables';
title2 'Univariate discriminant power of transformed variables';
ods proclabel='Univariate discriminant power of transformed variables';
proc print data=&lib..variables_stat label noobs;
var VARIABLE 
/*PS_grp_train PS_grp_valid*/
AR_Train AR_Valid 
H_GRP_Train H_GRP_Valid
Max_Mist_GRP_Train Max_Dist_GRP_Valid
;
label
VARIABLE='Name'
AR_Train='AR-WOE between gods and bads in training dataset' 
AR_Valid='AR-WOE between gods and bads in validating dataset' 
H_GRP_Train='Kullback-Leibrer-GRP between gods and bads in training dataset'  
H_GRP_Valid='Kullback-Leibrer-GRP between gods and bads in validating dataset' 
Max_Mist_GRP_Train='Percent distance-GRP between gods and bads in training dataset'   
Max_Dist_GRP_Valid='Percent distance-GRP between gods and bads in validating dataset' 
/*PS_grp_train='Power statistic in training dataset'*/
/*PS_grp_valid='Power statistic in validating dataset'*/
;
where &condition;
run;


title 'Statistics for transformed variables';
title2 'Univariate stability power of transformed variables';
ods proclabel='Univariate stability power of transformed variables';
proc print data=&lib..variables_stat label noobs;
var VARIABLE  
/*PS_grp_Diff*/
AR_Diff 
H_GRP_Diff  
Max_Dist_GRP_Diff H_GRP_TV Max_Dist_GRP_TV H_Br_GRP_TV Max_Br_Dist_GRP_TV
;
label
VARIABLE='Name'
AR_Diff='Difference between AR-GRP on gods/bads between training and validating datasets'
H_GRP_Diff='Difference between Kolmogorov-Smirnov on gods/bads between training and validating datasets'  
Max_Dist_GRP_Diff='Difference Percent distance-GRP on gods/bads between training and validating datasets'  
H_GRP_TV='Kullback-Leibrer-GRP between training and validating datasets'   
Max_Dist_GRP_TV='Percent distance-GRP between training and validating datasets'   
H_Br_GRP_TV='Kullback-Leibrer-GRP only for bads between training and validating datasets'   
Max_Br_Dist_GRP_TV='Percent distance-GRP only for bads between training and validating datasets'  
/*PS_grp_Diff='Difference Power statistic between training and validating datasets' */
;
where &condition;
run;

title "Gini statistics for variables in the model";
ods proclabel="Gini statistics for variables in the model";
proc print data=&lib..variables_stat label noobs;
var VARIABLE 
AR_Train;
label
VARIABLE='Name'
AR_Train='Gini statistics for variables in the model';
format ar_train nlpct12.2;
where VARIABLE in (&zm_wciapkach);
run;



/*wykresy grp*/
%macro wykresy_grp;
%do i=1 %to &ilz;
%let z=%scan(&zmiennegrp,&i,%str( ));
title "Stability of &z graph - distribution";
title2;
ods proclabel="Stability of &z graph - distribution";
%przygotuj_histogramy_n(&train,&valid,&z);


title "Stability of &z graph - Bad rate distribution";
title2;
ods proclabel="Stability of &z graph - Bad rate distribution";
%przygotuj_histogramy_br(&train,&valid,&z);

%end;
%mend;
%wykresy_grp;

/*atrybuty*/
title 'Splitting points for variables';
title2;
ods proclabel='Splitting points for variables';
proc print data=models.Scorecard_scorecard&the_best_model noobs label width=minimum;
var _group_ 
_percent_all_
_number_all_
_number_ind_
_number_good_
_number_bad_
wi ivi
;
id _variable_ ;
by _variable_ notsorted;
label 
_percent_all_='Percent' 
_number_all_='Number of ALL' 
_number_ind_='Number of IND' 
_number_good_='Number of GOOD'
_number_bad_='Number of BAD'
wi='Weight of evidence' br='Bad-rate' ivi='Information value' 
_variable_='Variable'
_group_='Attribute number';
where _group_ ne -2;
run;

/*karta*/
title 'Scorecard';
title2;
ods proclabel='Scorecard';
proc print data=models.Scorecard_scorecard&the_best_model noobs label width=minimum;
var  _label_ SCORECARD_POINTS;
id _variable_ ;
by _variable_ notsorted;
label _label_='Splitting points' 
_variable_='Variable'
_group_='Attribute number';
where _group_ ne -2;
run;

/*punkty*/
proc sql noprint;
select skala into :skala from skala;
quit;
proc means data=models.Scorecard_scorecard&the_best_model nway noprint;
var SCORECARD_POINTS;
class _variable_;
where _group_ ne -2;
output out=sc min=min max=max range=range;
run;
data sc;
set sc;
percent=range/&skala;
run;

title 'Scale of scorecard';
title2;
ods proclabel='Scale of scorecard';
proc print data=skala noobs label;
var min max skala;
label min='Minimum scorcard points' 
max='Maximum scorcard points' 
skala='Range of scorcard points';
run;

proc sort data=sc;
by descending percent;
run;
title "Scale of variable's scorecard points";
title2;
ods proclabel="Scale of variable's scorecard points";
proc print data=sc noobs label;
var min max range percent;
id _variable_;
label 
_variable_='Variable'
min='Minimum scorcard points' 
max='Maximum scorcard points' 
range='Range of scorcard points'
percent='Part of global range'
;
format percent percent12.2;
run;

/*moc modelu discrim*/
title "Discriminant power of model";
title2;
ods proclabel="Discriminant power of model";
proc print data=model noobs label;
var 
/*ps_train ps_valid */
AR_Score_Train AR_Score_Valid;
label 
/*ps_train='Power Statistic on training dataset' */
/*ps_valid='Power Statistic on validating dataset' */
AR_Score_Train='AR on training dataset' 
AR_Score_Valid='AR on validating dataset' 
;
run;

/*ci*/
title "Confidence intervals for C and AR";
title2;
ods proclabel="Confidence intervals for C and AR";
proc tabulate data=models.Ci_c_ar&the_best_model;
var std_c var_c l95_c c u95_c l99_c u99_c std_ar 
var_ar l95_ar ar u95_ar l99_ar u99_ar;
table 
std_c var_c l95_c c u95_c l99_c u99_c std_ar 
var_ar l95_ar ar u95_ar l99_ar u99_ar , sum=''*f=best12.;
run;


/*moc modelu stability*/
title "Stability power of model";
title2;
ods proclabel="Stability power of model";
proc tabulate data=model;
var 
/*ps_diff */
AR_Score_Diff KS_Score H_Score H_Br_Score Max_Dist_Score 
Max_Dist_Br_Score 
SD_Score Prop_Sd_Range 
Max_Abs_SD_Zm 
Prop_Max_SD_Range_Zm 
;
label 
/*ps_diff='Difference between Power Statistic on training and validating datasets'*/
AR_Score_Diff='Difference between AR on training and validating datasets' 
KS_Score='Kolmogorov-Smirnov between scores on training and validating datasets' 
H_Score='Kullback-Leibrer between scores on training and validating datasets' 
H_Br_Score='Kullback-Leibrer only for bads between scores on training and validating datasets'  
Max_Dist_Score='Percent distance between scores on training and validating datasets'  
Max_Dist_Br_Score='Percent distance only for bads between scores on training and validating datasets'  
SD_Score='Score Difference between training and validating datasets' 
Prop_Sd_Range='Part of Score Difference in global scorcards points range'  
Max_Abs_SD_Zm='Maximum of absolute value of Score Difference on variable between training and validating datasets' 
Prop_Max_SD_Range_Zm='Maximum part of score difference on variable in variable scorecard points rage';
table 
/*ps_Diff*f=percent12.2 */
AR_Score_Diff*f=percent12.2 
(KS_Score H_Score H_Br_Score Max_Dist_Score 
Max_Dist_Br_Score SD_Score)*f=best12. 
Prop_Sd_Range*f=percent12.2  
Max_Abs_SD_Zm*f=best12. 
Prop_Max_SD_Range_Zm*f=percent12.2  , sum='';
run;

title "Stability of scorecard points graph";
title2;
ods proclabel="Stability of scorecard points graph";
%przygotuj_histogramy_score(&train,&valid,&score_points);


/*title "Scorecard points and defaults";*/
/*title2;*/
/*ods proclabel="Scorecard points and defaults";*/
/*proc gchart data=&train;*/
/*vbar3d &score_points / subgroup=&tar type=percent legend*/
/*levels=&il_podzialow;*/
/*format &tar nlpct12.2;*/
/*run;*/
/*quit;*/
title "Scorecard points and bad rates";
title2;
ods proclabel="Scorecard points and bad rates";
proc gchart data=&train;
vbar3d &score_points / sumvar=&tar type=mean
levels=&il_podzialow;
label &tar='Bad rate';
format &tar nlpct12.2;
run;
quit;

proc sort data=sd_zmienne;
by descending prop_sd_zm;
run;

/*moc modelu discrim*/
title "Stability of scorecard points on variables";
title2;
ods proclabel="Stability of scorecard points on variables";
proc print data=sd_zmienne noobs label;
var _name_ sd_zm prop_sd_zm;
format prop_sd_zm percent12.2;
label 
_name_='Variable' 
sd_zm='Score difference between training and validating datasets' 
prop_sd_zm='Part of Score Difference in variable scorcards points range'
;
run;


/*collinearity*/
title "Collinearity";
title2;
ods proclabel="Collinearity";
proc tabulate data=model ;
var Max_VIF_Train Max_Vif_Valid 
Max_Pearson_Train Max_Pearson_Valid 
Max_Con_Index_Train Max_Con_Index_Valid;
label 
Max_VIF_Train='MaximumVIF for variables on training dataset' 
Max_Vif_Valid='MaximumVIF for variables on validating dataset'
Max_Pearson_Train='MaximumPearson correlation for variables on training dataset'  
Max_Pearson_Valid='MaximumPearson correlation for variables on validating dataset' 
Max_Con_Index_Train='MaximumCondition Index for variables on training dataset'  
Max_Con_Index_Valid='MaximumCondition Index for variables on validating dataset'
;
table Max_VIF_Train Max_Vif_Valid 
Max_Pearson_Train Max_Pearson_Valid 
Max_Con_Index_Train Max_Con_Index_Valid , sum=''*f=best12.;
run;

proc sql;
create table eff as
select 
_Variable_ as variable,DF,Estimate,StdErr,WaldChiSq,ProbChiSq
from
models.Scorecard_effects&the_best_model as z1, sc as z2
where upcase(substr(variable,5))=upcase(_variable_);
quit;
proc sort data=eff;
by descending estimate;
run;
/*effects*/
title "Effects in the model";
title2;
ods proclabel="Effects in the model";
proc print data=eff noobs label;
var Variable DF Estimate StdErr WaldChiSq ProbChiSq;
where variable ne 'Intercept';
run;

/*bootstrap*/
title "Bootstrap for Gini";
title2;
ods proclabel="Bootstrap for Gini";
ods html select Moments BasicMeasures BasicIntervals
TestsForNormality;
proc univariate data=models.bootstrap&the_best_model all;
var ar;
label ar='Gini';
run;

title "Bootstrap for Gini graph";
title2;
ods proclabel="Bootstrap for Gini graph";
proc gchart data=models.bootstrap&the_best_model;
vbar3d ar / levels=&il_podzialow type=percent;
label ar='Gini';
run;
quit;

title "Bootstrap for KS";
title2;
ods proclabel="Bootstrap for KS";
ods html select Moments BasicMeasures BasicIntervals
TestsForNormality;
proc univariate data=models.bootstrap&the_best_model all;
var ks;
run;

title "Bootstrap for KS graph";
title2;
ods proclabel="Bootstrap for KS graph";
proc gchart data=models.bootstrap&the_best_model;
vbar3d ks / levels=&il_podzialow type=percent;
run;
quit;




ods html close;
ods listing;
goptions reset=all device=png;


/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



libname d (&lib);

%let karta_duza=d.Scorecard_all;

%let id=;



/*data &lib..train;*/
/*set &import_data;*/
/*run;*/
/*data &lib..valid;*/
/*set &import_validate;*/
/*run;*/


/*do liczenia liftów*/
%let centyle=1 2 3 4 5 10 20 30 40 50;
%let wym=%eval(1+%sysfunc(count(&centyle,%str( ))));
%put &wym;
data _null_;
length lifty gainsy $ 300;
array t(&wym) _temporary_ (&centyle) ;
do i=1 to &wym;
/*put t(i)=;*/
lifty=trim(lifty)||' Lift'||trim(put(t(i),best12.-L));
gainsy=trim(gainsy)||' Gains'||trim(put(t(i),best12.-L));
end;
/*put lifty=;*/
/*put gainsy=;*/
call symput('lifty',trim(lifty));
call symput('gainsy',trim(gainsy));
run;
%put &lifty;
%put &gainsy;


%let max_p=1000;
%let min_p=0;
%let stala_pt=1;
%let zmiana_skali=N;
/*%let zmiana_skali=T;*/
%let ile_modeli=1;
%let prawiezero=0.000000001;

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
&name_conindex &name_max_coindex_valid 
&lifty &gainsy
8;
           
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
&name_max_vif_valid &name_max_corr_valid &name_max_coindex_valid
&lifty &gainsy
;
        

data &lib..all_models;
&def_var;
set &insets; 
&name_ar_diff=(&name_ar_train-&name_ar_valid)/&name_ar_train;
format &name_ar_diff percent12.2;
run;

proc sort data=&lib..all_models nodupkey;
by &name_model;
run;

proc sort data=&lib..all_models;
by descending &name_ar_valid;
/*by descending &name_ar_train;*/
run;

/*proc print data=&lib..all_models;*/
/*run;*/
/**/
/*ods listing close;*/
/*goptions reset=all device=activex;*/
/*ods html body="&nodedir.\validation_all_models.html";*/
/*proc print data=&lib..all_models;*/
/*run;*/
/*ods html close;*/
/*ods listing;*/
/*goptions reset=all device=win;*/





%let granica_vif=5;
/*%let granica_vif=1.6;*/
%let granica_corr=0.88;
/*%let granica_corr=0.4;*/
/*%let granica_conindex=350;*/
%let granica_conindex=90;
/*%let granica_conindex=10;*/
%let granica_ar_diff=1;
/*%let granica_ar_diff=0.06;*/
%let granica_ProbChiSq=0.07;



data &lib..good_models;
set &lib..all_models;
where 
&name_vif le &granica_vif 
and &name_corr le &granica_corr
and &name_conindex le &granica_conindex 
and abs(&name_ar_diff) le &granica_ar_diff 
and &name_max_probChiSq le &granica_ProbChiSq
and n_beta_minus=0
;
/*and n_var=10;*/
run;

proc sort data=&lib..good_models;
by descending &name_ar_valid;
run;

/*data &lib..good_models;*/
/*set &lib..good_models(obs=3 firstobs=3);*/
/*run;*/


/*trzeba doliczyæ*/
/*ks_score 
h_score h_br_score sd_score
max_dist_score max_dist_br_score prop_sd_range
ar_score_train ar_score_valid ar_score_diff*/
/*sd_score max_abs_sd_zm prop_max_sd_range_zm */
/*max_probChiSq min_WaldChiSq */
/*max_pearson_valid max_vif_valid max_coindex_valid*/

/*dodatkowo mo¿na dodaæ z poprzednich*/
/*max_h max_h_br max_dist max_dist_br*/
/* */





/*%let train=&import_data;*/
/*%let valid=&import_validate;*/

%macro validuj_dobre(lista,train,valid,max_nr_mod=0);
data _null_;
set &lista(obs=1) nobs=il;
call symput('il',put(il,best12.-L));
run;
%if (&max_nr_mod eq 0 or &max_nr_mod>&il) %then %let max_nr_mod=&il;

data &lista._valid;
&def_var_dluga;
delete;
format &name_max_probChiSq PVALUE6.4;
format &name_prop_max_sd_range_zm &name_prop_sd_range percent12.4;
format &name_ar_diff &name_ar_score_diff percent12.2;
format &lifty 12.2;
format &gainsy percent12.2;
run;

/*poczatek pêtli*/
/*%do nr=1 %to 1;*/
/*%do nr=5 %to 5;*/
%do nr=1 %to &max_nr_mod;
/*poczatek pêtli*/

data model;
set &lib..good_models(firstobs=&nr obs=&nr);
call symput('zmienne',model);
run;
%put &zmienne;


ods listing close;
ods output 
/*Association=testy.Association&nr*/
/*ConvergenceStatus=c OddsRatios=testy.Odds&nr*/
ParameterEstimates=models.Scorecard_Effects&nr;
/*ods trace on / listing;*/
/*ods trace off;*/

/*zamiast logistic lepiej dmreg*/

proc logistic data=&import_data(keep=&tar &zmienne) 
desc outest=b namelen=32;
model &tar= &zmienne;
run;

ods output close;
ods listing;

proc transpose data=b out=tb(drop=_label_ where=(substr(_name_,1,1) ne '_'));
var _numeric_;
where _type_='PARMS';
run;
/**/
/*facctor=20/log(2);*/
/*offset=200-factor*log(50);*/
/*do tego miejsca dobrze*/

/*to poni¿ej gdy zmieniamy scale*/
/*proc sql noprint;*/
/*select variable into :zm1-:zm&sysmaxlong*/
/*from W_modelu_tym order by variable;*/
/*quit;*/
/**/
/**/

/*na nowo tworzymy listê zmiennych &zmienne*/
proc sql noprint;
select &tar,upcase(_name_),quote(substr(upcase(_name_),5)),
upcase(_name_)||'=T_'||trim(substr(upcase(_name_),5)),
upcase(_name_)||'=V_'||trim(substr(upcase(_name_),5)),
'T_'||trim(substr(upcase(_name_),5)),
'V_'||trim(substr(upcase(_name_),5))
into :betas separated by ',', :zmienne separated by ' ',
:zm_wciapkach separated by ',',
:renamet separated by ' ',
:renamev separated by ' ',
:zmiennet separated by ' ',
:zmiennev separated by ' '
from tb where _name_ ne "Intercept"
order by upcase(_name_);
%let ilz=&sqlobs;
select &tar into :alpha
from tb where _name_ eq "Intercept";
quit;

%put &ilz;
%put &zmienne;
%put &zmiennet;
%put &zmiennev;
%put &renamet;
%put &renamev;
%put &zm_wciapkach;
%put &betas;



proc sql;
create table scorecard_scorecard&nr as
select * from &karta_duza
where upcase(variable) in (&zm_wciapkach);
quit;



data f_beta;
length nazwy1-nazwy&ilz $ 32;
array b(&ilz) (&betas);
array nazwy(&ilz)$ (&zm_wciapkach);
set scorecard_scorecard&nr end=e;
n=0;
do i=1 to &ilz;
if variable=nazwy(i) then n=i;
end;
retain first_beta 0;
if grp=1 then do;
	first_beta=first_beta+transformed*b(n)*20/log(2);
	f_beta=transformed*b(n);
	output;
	end;
if e;
first_beta=-first_beta+300;
call symput('alp',put(first_beta,best12.-L));
keep variable f_beta;
run;

proc sql noprint;
select f_beta into :f_betas separated by ','
from f_beta 
order by upcase(variable);
quit;
%put &f_betas;





proc means data=&train noprint nway;
var &zmienne;
output out=s max()=;
run;
proc transpose data=s out=s_max(rename=(col1=max));
var &zmienne;
run;

proc means data=&train noprint nway;
var &zmienne;
output out=s min()=;
run;
proc transpose data=s out=s_min(rename=(col1=min));
var &zmienne;
run;
proc sort data=s_max;
by _name_;
run;
proc sort data=s_min;
by _name_;
run;
data stat_woe;
merge s_max s_min;
by _name_;
_name_=upcase(_name_);
run;
/*zamiast ign_stats:*/



proc transpose data=stat_woe out=twoe;
var min max;
id _name_;
run;


/*aby zmienic scale*/
data _null_;
array b(&ilz) (&betas);
array t(&ilz) &zmienne;
array m(2);
m(1)=0;m(2)=0;

do obs=1 to 2;
	set twoe;
	do i=1 to &ilz;
	m(obs)=m(obs)-(t(i)*b(i)+&alpha/&ilz);
/*	m(obs)=m(obs)-(t(i)*b(i)+&alpha/&ilz);*/
	end;
end;

max_p=&max_p; 
min_p=&min_p;

factor=(max_p-min_p)/abs(m(2)-m(1));
/*factor=(max_p-min_p)/(m(2)-m(1));*/
offset=min_p-min(m(1),m(2))*factor;
/*offset=min_p-m(1)*factor;*/

call symput('factor',put(factor,best12.-L)); 
call symput('offset',put(offset,best12.-L)); 
run;
%put &factor &offset;
/*aby zmienic scale*/


data score_woe;
set twoe;
array t(&ilz) &zmienne;
array b(&ilz) (&betas);
array fb(&ilz) (&f_betas);
%if &zmiana_skali=T %then %do;
	factor=&factor;
	offset=&offset;
%end; %else %do;
	factor=20/log(2);
	offset=300;
/*	offset=200-factor*log(50);*/
%end;
do i=1 to &ilz;
/*pierwsza wersja*/
/*t(i)=-(t(i)*b(i)+&alpha/&ilz)*factor+offset/&ilz;*/
/*if t(i)>=0 then t(i)=int(t(i)+0.4); else t(i)=int(t(i)-0.4);*/
/*druga wersja*/
t(i)=round(-(t(i)*b(i)-fb(i)+&alpha/&ilz)*factor+&alp/&ilz);
end;
keep _name_ &zmienne;
run;

data scale;
set score_woe end=e;
array t(&ilz) &zmienne;
do i=1 to &ilz;
t(i)=dif(t(i));
end;
drop i;
if e;
score=sum(of WOE_:);
call symput('range_score',put(score,best12.-L));
run;
%put &range_score;



/*zrobienie scorecard_scorecard druga czêœæ*/

data models.scorecard_scorecard&nr;
length nazwy1-nazwy&ilz $ 32;
array b(&ilz) (&betas);
array fb(&ilz) (&f_betas);
array nazwy(&ilz)$ (&zm_wciapkach);
%if &zmiana_skali=T %then %do;
	factor=&factor;
	offset=&offset;
%end; %else %do;
	factor=20/log(2);
	offset=300;
/*	offset=200-factor*log(50);*/
%end;
set scorecard_scorecard&nr;
n=0;
do i=1 to &ilz;
if variable=nazwy(i) then n=i;
end;

&score_points=
round(-(transformed*b(n)-fb(n)+&alpha/&ilz)*factor+&alp/&ilz);

keep 
condition variable 
n_bads_cat n_cat n_ind_cat n_goods_cat 
br logit 
Percent Percent_bads Percent_goods Percent_ind 
wi ivi grp
&score_points;

rename variable=_variable_ grp=_group_
condition=_label_ 
percent=_percent_all_ Percent_bads=_percent_bad_ 
Percent_goods=_percent_good_
percent_ind=_percent_ind_
n_bads_cat=_number_bad_ 
n_cat=_number_all_ 
n_ind_cat=_number_ind_ 
n_goods_cat=_number_good_
;
run;



proc sort data=models.Scorecard_scorecard&nr out=ms(keep=
_variable_ _group_  &score_points);
by _variable_ &score_points;
where _group_ ne -2;
run;

data models.scale&nr;
retain min max (0,0);
set ms end=e;
by _variable_;
if first._variable_ then min=sum(min,&score_points);
if last._variable_ then max=sum(max,&score_points);
scale=max-min;
if e;
keep max min scale;
run;



data scores_train;
set &train;
array t(&ilz) &zmienne;
array b(&ilz) (&betas);
array fb(&ilz) (&f_betas);
%if &zmiana_skali=T %then %do;
	factor=&factor;
	offset=&offset;
%end; %else %do;
	factor=20/log(2);
	offset=300;
/*	offset=200-factor*log(50);*/
%end;
&score_points=0;
do i=1 to &ilz;

t(i)=round(-(t(i)*b(i)-fb(i)+&alpha/&ilz)*factor+&alp/&ilz);
&score_points=sum(&score_points,t(i));
end;
keep &zmienne &score_points &tar &id;
run;

data models.score&nr;
set scores_train;
keep &id &tar &score_points;
run;

data scores_valid;
set &valid;
array t(&ilz) &zmienne;
array b(&ilz) (&betas);
array fb(&ilz) (&f_betas);
%if &zmiana_skali=T %then %do;
	factor=&factor;
	offset=&offset;
%end; %else %do;
	factor=20/log(2);
	offset=300;
/*	offset=200-factor*log(50);*/
%end;
&score_points=0;
do i=1 to &ilz;
t(i)=round(-(t(i)*b(i)-fb(i)+&alpha/&ilz)*factor+&alp/&ilz);
&score_points=sum(&score_points,t(i));
end;
keep &zmienne &score_points &tar &id;
run;

data models.score_valid&nr;
set scores_valid;
keep &id &tar &score_points;
run;


/*wstawka na liczenie lift i gains */
/*jest to lift skumulowany i gains te¿*/
%macro licz_lifty;
proc univariate data=scores_train noprint;
var &score_points &tar;
output out=lifty sum=bs bad
pctlpts=&centyle pctlpre=P_;
run;
data _null_;
set lifty;
array t(*) p:;
d=dim(t);
call symput('n_lift',put(d,best12.-L));
call symput('n_bad',put(bad,best12.-L));
do i=1 to d;
call symput('sc'||put(i,best12.-L),put(t(i),best12.-L));
call symput('na'||put(i,best12.-L),substr(vname(t(i)),3));
end;
run;
/*%put &n_lift***&n_bad***&sc1***&na1;*/

%do i=1 %to &n_lift;
proc sql noprint;
select sum(&tar) into :bad&i
from scores_train where &score_points<=&&sc&i;
quit;
/*%put &&bad&i***&&na&i;*/
%end;

data lifty_wynik;
%do i=1 %to &n_lift;
Lift&&na&i=&&bad&i/(&n_bad*&&na&i/100);
Gains&&na&i=&&bad&i/&n_bad;
%end;
format Gains: percent12.2;
format Lift: 12.2;
run;
%mend licz_lifty;

%licz_lifty;




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

proc transpose data=scale(keep=&zmienne) out=t2(rename=(col1=range_zm));
var &zmienne;
run;
proc sort data=t2;
by _name_;
run;

data r;
merge t1 t2;
by _name_;
run;

data r;
set r;
prop_sd_zm=abs(sd_zm)/range_zm;
run;

proc sql noprint;
select max(abs(sd_zm)),max(prop_sd_zm) into :max_abs_sd_zm, :prop_max_sd_range_zm
from r;
quit;
%put &max_abs_sd_zm &prop_max_sd_range_zm;

/*liczenie vif i corr*/
ods listing close;
ods output ParameterEstimates(persist=proc)=p CollinDiag(persist=proc)=coll;
proc reg data=&valid(keep=&tar &zmienne);
model &tar=&zmienne / vif collin;
run;
quit;
ods output close;
ods listing;

proc sql noprint;
select max(VarianceInflation) into :vif from p;
select max(ConditionIndex) into :conindex from coll;
quit;

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
if e then call symput('max_corr',put(m,best12.-L));
run;
/*%put &max_corr;*/





/*%if %sysfunc(exist(a)) %then %do;*/
/*proc delete data=a;*/
/*run;*/
/*%end;*/

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


/*to jeszcze wymaga pracy*/



data model;
&def_var_dluga;
format &name_max_probChiSq PVALUE6.4;
format &name_prop_max_sd_range_zm &name_prop_sd_range percent12.4;
format &name_ar_diff &name_ar_score_diff percent12.2;

set model;
set w_score;

&name_ks_score=&ks_score;
&name_ar_score_train=&ar_t;        
&name_ar_score_valid=&ar_v; 
&name_ar_score_diff =(&name_ar_score_train-&name_ar_score_valid)
/&name_ar_score_train;

&name_max_abs_sd_zm=&max_abs_sd_zm;
&name_prop_max_sd_range_zm=&prop_max_sd_range_zm;

&name_max_corr_valid=&max_corr;
&name_max_vif_valid=&vif;
&name_max_coindex_valid=&conindex;

set lifty_wynik;

keep &list_var_dluga;
run;

proc append base=&lista._valid data=model;
run;

%end;
%mend;


%validuj_dobre(&lib..good_models,&import_data,&import_validate,max_nr_mod=&ile_modeli);









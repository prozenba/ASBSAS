/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



/*%let il_seed=100;*/
/*%let il_seed=10000;*/
/*%let il_seed=20000;*/


libname kal (models);



data score;
set kal.score&the_best_model;
format &tar best12.;
keep &tar &score_points;
run;
proc sort data=score;
by &tar;
where &tar in (0,1);
run;

%macro validuj;

proc sql noprint;
select sum((&tar=1)),sum((&tar=0)) into :jedynki,:zera
from score;
quit;
%put &jedynki***&zera;

data kal.bootstrap&the_best_model;
length seed 
/*ps */
ar ks 8;
delete;
run;

/*%let seed=1;*/

%do seed=1 %to &il_seed;


proc surveyselect data=score out=s(keep=&score_points &tar) noprint
method=urs n=(&zera &jedynki) outhits seed=&seed;
strata &tar;
run;

/*%powerc(s,&score_points,&tar);*/
/*data _null_;*/
/*set power;*/
/*call symput("ps",put(powerpercent,best12.-L));*/
/*run;*/



proc npar1way data=s edf wilcoxon noprint;
class &tar;
var &score_points;
output out=ks(keep=_D_) wilcoxon edf;
run;

data a;
label2='c';
nValue2=.;
run;


ods listing close;
ods output Association(persist=proc)=a;
proc logistic data=s desc namelen=32;
model &tar=&score_points;
run;
ods output close;
ods listing;

data wynik;
set a(where=(label2='c'));
set ks;
/*set power(keep=powerpercent rename=(powerpercent=ps));*/
ar=2*nValue2-1;
seed=&seed;
ks=_d_;
keep seed 
/*ps */
ar ks;
run;

proc append base=kal.bootstrap&the_best_model data=wynik;
run;
%end;


proc means data=kal.bootstrap&the_best_model noprint nway;
var 
/*ps */
ks ar;
output out=kal.cross_stat&the_best_model(drop=_freq_ _type_) mean= p50= min= max= 
cv= range= qrange= uclm= lclm= / autoname;
run; 

%mend;
%validuj;


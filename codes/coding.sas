/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



proc sort data=&Bining_int out=podz;
by variable grp;
run;
data &lib..bining_interval_fin;
set 
podz
;
by variable;
if index(condition,'is not missing')>0 then 
condition='not missing('||compress(variable)||')';
output;
if last.variable then do;
grp=grp+1;
condition='missing('||compress(variable)||')';
output;
end;
run;
proc sort data=&lib..bining_interval_fin;
by variable grp;
run;

data &lib..bining_nominal_fin;
set 
&bining_nominal
;
run;
proc sort data=&lib..bining_nominal_fin;
by variable grp;
run;

/*kodowanie*/
/*od nowa siê liczy iloœci w atrybutach*/
/*zaklada siê ¿e mo¿na te conditionunki modyfikowaæ*/

/*libname t (&lib.);*/
%let kat_kodowanie=%sysfunc(pathname(&lib.));
%put &kat_kodowanie;




%let zb_int=&lib..bining_interval_fin;
%let zb_nom=&lib..bining_nominal_fin;



data podzialy_org;
set &zb_int &zb_nom;
keep condition variable grp;
run;

%let adjvars=;
%let adjnames='id';

proc sql noprint;
select "ADJ."||trim(memname),quote(memname) into :adjvars separated by ' ',
:adjnames separated by ','
from dictionary.tables where
libname='ADJ';
quit;
%put &adjvars;
%put &adjnames;

data podzialy;
set podzialy_org(where=(upcase(variable) not in (&adjnames)))
&adjvars
;
run;


proc sort data=podzialy;
by variable grp;
run;
data podzialy;
set podzialy;
by variable;
if first.variable and last.variable then delete; else output;

/*if last.variable and variable in (&zmienne_otherwise) then do;*/
/*grp=grp+1;*/
/*condition='otherwise';*/
/*output;*/
/*end;*/

if last.variable then do;
grp=grp+1;
condition='otherwise';
output;
end;

run;


filename kod "&kat_kodowanie.\coding_code_tmp.sas";
/*potrzebujemy policzyæ n_cat n_bads_cat*/
data _null_;
length przed za $100 naz $32;
file kod;
if _n_=1 then do;
put "data grp;";
put "set &zb;";
end;

do i=1 to ilobs;
set podzialy nobs=ilobs;
by variable;
if first.variable then do;
	if substr(condition,1,4)='when' then do;
	przed='';za='';
	put "select (" variable ");";
	end; else do;
	przed='when (';za=')';
	put "select;";
	end;
end;

if not last.variable then do;
put przed condition za "do;";
naz="GRP_"||trim(variable);
put naz " = " grp ";";
put "end;";
end;

if last.variable and condition='otherwise' then 
	put 'otherwise ' naz ' = ' grp '; end;';
if last.variable and condition ne 'otherwise' then 
	put 'otherwise ' naz ' = ' '.; end;';

end;

put "run;";
run;

%include "&kat_kodowanie.\coding_code_tmp.sas";

proc means data=grp noprint;
class grp: /missing;
ways 1;
var &tar;
output out=licz sum()=n_bads_cat n()=n_cat nmiss()=n_ind_cat;
where &tar ne .;
run;

data licz;
length variable $32 grp 8;
set licz;
array t(*) grp:;
do i=1 to dim(t);
if not missing(t(i)) then do;
	grp=t(i);
	variable=vname(t(i));
end;
end;
variable=substr(variable,5);
n_goods_cat=n_cat-n_bads_cat;
n_cat=n_cat+n_ind_cat;
if not missing(variable);
keep variable grp n_cat n_bads_cat n_goods_cat n_ind_cat;
run;
proc sort data=licz;
by variable grp;
run;

/*specjalna wstawka*/
data podzialy;
set podzialy;
variable=substr(variable,1,28);
run;
proc sort data=podzialy;
by variable grp;
run;


data podzialy_pol;
merge podzialy licz;
by variable grp;
run;


/*doliczenie woe logit*/
proc sql noprint;
select count(*),sum((&tar=1)),sum((&tar=0)),
sum((&tar=.i or &tar=.d)) into :n,:n_bads,:n_goods,:n_ind
from &zb;
quit;
%put &n***&n_bads***&n_goods***&n_ind;

/*podzialy ze statystykami*/
data &lib..scorecard_all;
set podzialy_pol;
/*ta poprawka do zastanowienia*/
woe=log(((n_goods_cat)/(&n_goods))/((n_bads_cat)/&n_bads));
br=n_bads_cat/n_cat;

if br>0.99 or missing(br) then br=0.99;
if .<br<0.0003 then br=0.0003;

logit=log(n_bads_cat/n_goods_cat);
/*logit=log(br/(1-br));*/
/*liczê woe jako logit*/
transformed=logit;
Percent=n_cat/&n;
Percent_bads=coalesce(n_bads_cat/&n_bads,0);
Percent_goods=coalesce(n_goods_cat/&n_goods,0);
Percent_ind=coalesce(n_ind_cat/&n_ind,0);
wi=log(Percent_goods/Percent_bads);
ivi=(Percent_goods-Percent_bads)*wi;
format percent Percent_bads Percent_goods percent_ind percent12.2;
if _error_=1 then _error_=0;
if missing(percent) then delete;
/*if not missing(condition1) and not missing(condition2) and .<=percent<0.005 then delete;*/
if .<=percent<0.005 then delete;
run;


proc sort data=&lib..scorecard_all;
by variable descending br ;
run;
data &lib..scorecard_all;
set &lib..scorecard_all(drop=grp);
by variable;
if first.variable then grp=0;
grp+1;
otherwise_ind=(condition='otherwise');
run;

/*na razie missing wrzucamy wed³ug porz¹dku 
zale¿nie od tego czy to jest model ryzyka czy response*/

proc sort data=&lib..scorecard_all out=p;
by variable otherwise_ind &order_tar br;
/*by variable n_cat;*/
run;

/*teraz prawdziwe kodowanie*/


filename kod "&kat_kodowanie.\coding_code.sas";
data _null_;
length przed za $100 naz $32;
file kod;
if _n_=1 then do;
put 'data &zbior._woe;';
put 'set &zbior;';
end;

do i=1 to ilobs;
set p nobs=ilobs;
by variable;

if condition ne 'otherwise' then do;
	if first.variable then do;
		if substr(condition,1,4)='when' then do;
		przed='';za='';
		put "select (" variable ");";
		end; else do;
		przed='when (';za=')';
		put "select;";
		end;
	end;

	put przed condition za "do;";
	naz="GRP_"||trim(variable);
	put naz " = " grp ";";
	naz="WOE_"||trim(variable);
	put naz " = " transformed ";";
	put "end;";
end; 


if last.variable then do;
	put 'otherwise do;';
	naz="GRP_"||trim(variable);
	put naz " = " grp ";";
	naz="WOE_"||trim(variable);
	put naz " = " transformed ";";
    put 'end; end;';
end;

end;
put 'keep &keep;';
put 'if _error_=1 then _error_=0;';
put "run;";
run;

%let zbior=&zb;
%let keep=_all_;
%include "&kat_kodowanie.\coding_code.sas";

%let zbior=&zb_v;
%let keep=_all_;
%include "&kat_kodowanie.\coding_code.sas";



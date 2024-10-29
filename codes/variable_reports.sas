/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



options ls=256;

%let nr_cent=99;

proc format;
picture procent (round)
low- -0.005='00.000.000.009,99%'
(decsep=',' 
dig3sep='.'
fill=' '
prefix='-')
-0.005-high='00.000.000.009,99%'
(decsep=',' 
dig3sep='.'
fill=' ')
;
run;

proc format;
picture liczba (round)
low- -0.005='0 000 000 000 009,99'
(decsep=',' 
dig3sep=' '
fill=' '
prefix='-')
-0.005-high='0 000 000 000 009,99'
(decsep=',' 
dig3sep=' '
fill=' ')
;
run;



proc sql noprint;
select 
'WOE_'||
upcase(trim(variable)) 
into :zmienne separated by ' ' from &lib..chosen_variables;
quit;
%put &zmienne;

ods listing close;
ods output
Eigenvalues=Eigenvalues;
/*ods trace on / listing;*/
/*ods trace off;*/
proc princomp data=&import_data(keep=&zmienne);
var &zmienne;
run;
ods output close;
ods listing;



ods listing close;
ods output
ClusterQuality=ClusterQuality
RSquare(match_all)=RSquare2
ClusterSummary(match_all)=ClusterSummary1;
/*ods trace on / listing;*/
/*ods trace off;*/
proc varclus data=&import_data(keep=&zmienne) PROPORTION=0.8;
var &zmienne;
run;
ods output close;
ods listing;

data _null_;
set Clusterquality;
call symput('ncl',
trim(put(NumberOfClusters,best12.-L)));
run;
%put **&ncl**;


%let reportsdir=&prefix_dir.results/%sysfunc(compress(&design,_))/;
%let subdir=reports/;
%put &reportsdir;



ods listing close;
ods html path="&reportsdir" body="All_possible_variables.html" style=statistical;
data test;
set inlib.labels;
run;
proc sort data=test;
by label;
run;
data test;
set test;
Number=_n_;
run;
title "List of all possible variables";
proc print data=test label;
id Number name;
var label;
label
label='Variable description'
name='Variable name'
;
run;
ods html close;
ods listing;



ods listing close;
ods html path="&reportsdir" body="All_variables.html" style=statistical;
data test0;
set &lib..Variables_stat;
gini_before=2*c_01_train-1;
gini_after=ar_train;
diff_gini=(gini_before-gini_after)/gini_before;
Number=_n_;
format gini_before gini_after diff_gini 
PR_Miss_Train PR_mfrequent_Train nlpct12.2;
if _error_=1 then _error_=0;
keep number variable gini_before gini_after diff_gini
level PR_Miss_Train N_Uni_Train PR_mfrequent_Train mfrequent_Train
ar_diff H_GRP_TV H_Br_GRP_TV;
run;
proc sql;
create table test as
select test0.*,label
from test0, inlib.labels
where upcase(name)=upcase(variable)
order by gini_after desc;
quit;
data test;
set test;
Number=_n_;
run;

title "Report of all variables, after simple pre-selection";
proc print data=test label;
id Number variable;
var gini_before gini_after diff_gini label
level PR_Miss_Train N_Uni_Train PR_mfrequent_Train mfrequent_Train
ar_diff
H_GRP_TV
H_Br_GRP_TV
;
label
AR_Diff='Relative difference between Ginis between training and validating datasets'
H_GRP_TV='Kullback-Leibrer between attribute distributions on training and validating datasets'   
H_Br_GRP_TV='Kullback-Leibrer between attribute distributions only for bad cases on training and validating datasets'   
gini_before='Gini before binning' 
gini_after='Gini after binning' 
diff_gini='Difference of gini before and after binning'
variable='Variable name'
label='Variable description'
level='Measure'
PR_Miss_Train='Percent of missing valuses' 
N_Uni_Train='Number of distinct values'
PR_mfrequent_Train='Percent of the most frequent nonmissing value' 
mfrequent_Train='The most frequent nonmissing value' 
;
run;
ods html close;
ods listing;

proc sql;
create table karta as
select * from &lib..Scorecard_all where 
upcase(variable) in 
(select upcase(variable) from &lib..Chosen_variables)
order by variable,grp;
quit;
proc sql noprint;
select count(*),sum((&tar=1)),
sum((&tar=0)),sum((&tar=.i or &tar=.d)) into 
:il,:il_jed,:il_zer,:il_ind
from &zb;
quit;
%put &il***&il_jed***&il_zer***&il_ind;


data karta;
set karta;
POP=n_cat;
GD=n_goods_cat;
BD=n_bads_cat;
IND=n_ind_cat;
pr_POP=POP/&il;
pr_GD=coalesce(GD/&il_zer,0);
pr_BD=coalesce(BD/&il_jed,0);
pr_IND=coalesce(IND/&il_ind,0);
wi=log(pr_GD/pr_BD);
ivi=(pr_GD-pr_BD)*wi;
if _error_=1 then _error_=0;
keep variable POP GD BD IND pr_POP pr_GD pr_BD pr_IND wi ivi br grp condition;
format br pr_POP pr_GD pr_BD pr_IND nlpct12.2 ivi wi numx12.2;
run;

data clusters;
length cl cluster $ 20;
format cluster $20.;
retain cl;
set rsquare&ncl;
if not missing(Cluster) then cl=Cluster;
if missing(Cluster) then Cluster=cl;
cluster='Cluster '||put(input(compress(scan(cluster,-1,' ')),best12.),z3.);
Variable=substr(Variable,5);
keep Variable Cluster RSquareRatio;
run;

proc sql;
create table ivi as
select sum(ivi) as ivi format=numx12.2,variable from karta
group by variable;

create table test_det0 as
select test.*, ivi from test,ivi
where upcase(test.variable)=upcase(ivi.variable)
order by gini_after desc;

create table test_det as
select test_det0.*, Cluster, RSquareRatio from test_det0 left join clusters
on upcase(test_det0.variable)=upcase(clusters.variable)
order by gini_after desc;
quit;

proc sql noprint;
select quote(variable) into :chosen separated by ','
from &lib..Chosen_variables;
quit;
%put &chosen;

data test_det;
length href $ 1000;
set test_det;
Number=_n_;
if variable in (&chosen) then
href= 
'<a href="'||"&subdir."||compress(upcase(variable))
||'.html" '||'target="body">'||compress(upcase(variable))||'</a>'
;
else href=variable;
run;

proc sort data=test_det out=test_dets;
by cluster descending gini_after;
run;

ods listing close;
ods html path="&reportsdir" (url=none)
body="Chosen_variables.html" style=statistical;
title "Report of chosen variables";
proc print data=test_det label;
id Number href;
var gini_before gini_after diff_gini ivi label
level PR_Miss_Train N_Uni_Train PR_mfrequent_Train mfrequent_Train
ar_diff
H_GRP_TV
H_Br_GRP_TV 
Cluster RSquareRatio
;
label
AR_Diff='Relative difference between Ginis between training and validating datasets'
H_GRP_TV='Kullback-Leibrer between attribute distributions on training and validating datasets'   
H_Br_GRP_TV='Kullback-Leibrer between attribute distributions only for bad cases on training and validating datasets'   
href='Variable name (click on name to get details)'
ivi='Information value (iv)'
gini_before='Gini before binning' 
gini_after='Gini after binning' 
diff_gini='Difference of gini before and after binning'
variable='Variable name'
label='Variable description'
level='Measure'
PR_Miss_Train='Percent of missing valuses' 
N_Uni_Train='Number of distinct values'
PR_mfrequent_Train='Percent of the most frequent nonmissing value' 
mfrequent_Train='The most frequent nonmissing value' 
;
run;
ods html close;
ods listing;

ods listing close;
ods html path="&reportsdir" (url=none)
body="Clustered_variables.html" style=statistical;
title "Report of variable clusters";
proc print data=test_dets label width=minimum;
/*id cluster href;*/
by cluster;
var href Number gini_before gini_after diff_gini ivi label
level PR_Miss_Train N_Uni_Train PR_mfrequent_Train mfrequent_Train
ar_diff
H_GRP_TV
H_Br_GRP_TV 
RSquareRatio
;
label
AR_Diff='Relative difference between Ginis between training and validating datasets'
H_GRP_TV='Kullback-Leibrer between attribute distributions on training and validating datasets'   
H_Br_GRP_TV='Kullback-Leibrer between attribute distributions only for bad cases on training and validating datasets'   
href='Variable name (click on name to get details)'
ivi='Information value (iv)'
gini_before='Gini before binning' 
gini_after='Gini after binning' 
diff_gini='Difference of gini before and after binning'
variable='Variable name'
label='Variable description'
level='Measure'
PR_Miss_Train='Percent of missing valuses' 
N_Uni_Train='Number of distinct values'
PR_mfrequent_Train='Percent of the most frequent nonmissing value' 
mfrequent_Train='The most frequent nonmissing value' 
;
run;
ods html close;
ods listing;

ods listing close;
ods html path="&reportsdir" (url=none)
body="Cluster_reports.html" style=statistical;
title "Dimentional reports";
proc print data=Clusterquality label;
run;
proc print data=Clustersummary&ncl label;
run;
proc print data=Eigenvalues label;
run;
ods html close;
ods listing;




/*proc sql noprint;*/
/*select 'inlib.'||memname into :sets separated by " " */
/*from dictionary.tables where*/
/*libname=upcase("INLIB") and (memname like "ABT_1%" */
/*or memname like "ABT_2%"); */
/*quit; */
%let sets=&in_abt;
%put &sets;

proc sql noprint;
select 'GRP_'||compress(upcase(variable)),compress(upcase(variable))
into :zmienne_grp separated by ' ',
:zmienne separated by ' '
from &lib..Chosen_variables;
quit;
%put &zmienne***&sqlobs;

%let dodatkowe=credit_limit;
%let trzymaj=&tar outstanding period quarter year &dodatkowe;
data abt;
set &sets;
%Additional_variables;
quarter=compress(put(input(period,yymmn6.),yyq10.));
year=compress(put(input(period,yymmn6.),year4.));
keep &zmienne &trzymaj;
run;

%let kat_kodowanie=%sysfunc(pathname(&lib.));
%put &kat_kodowanie;
%let zbior=abt;
%let keep=&zmienne_grp &trzymaj;
%include "&kat_kodowanie./coding_code.sas";
/*data abt_woe;*/
/*set abt_woe;*/
/*if &tar in (.,.i,.d) then &tar=0;*/
/*run;*/




%macro make_details;
proc sql noprint;
select distinct upcase(variable) into :zmienne separated by ' '
from &lib..Chosen_variables;
quit;
%let il_zm=&sqlobs;
%put &il_zm***&zmienne;
/*%let i=1;*/

%do i=1 %to &il_zm;
/*%do i=1 %to 1;*/

%let zm=%scan(&zmienne,&i,%str( ));
%put &zm;
%let label=Not defined;
proc sql noprint;
select label into :label from test_det
where upcase(variable) eq upcase("&zm")
and label not like "%'%" and label ne '';
quit;
%let label=&label;
/*%put &label;*/


ods listing close;
ods html path="&reportsdir.&subdir" (url=none)
body="&zm..html" style=statistical;
title "Attributes for variable &zm";
title2 "&label";
title3 'Table with statistics';
proc print data=karta label;
id grp;
var condition br pr_POP pr_GD pr_BD pr_IND POP GD BD IND wi ivi;
where upcase(variable)="&zm";
label
ivi='Information value (ivi)'
POP='Population (POP)' 
GD='Number of goods (GD)' 
BD='Number of bads (BD)' 
IND='Number of indeterminated (IND)' 
pr_POP='Percent of population (%POP)' 
pr_GD='Percent of goods (%GD)' 
pr_BD='Percent of bads (%BD)' 
pr_IND='Percent of indeterminated (%IND)'
wi='Weight of evidence (wi)' 
br='Bad rate (br)'
grp='Attribute number'
condition='Condition'
;
sum POP GD BD IND pr_POP ivi;
run;

goptions reset=all device=png;

%let period=year;
/*%let period=period;*/
%let balvar=outstanding;
/*%let balvar=outstanding_&tar;*/
%let measure=&tar;

data br_am;
set abt_woe;
all=&balvar;
if (&measure in (.d,.i,0,1)) then all_ass=&balvar;
if (&measure in (0)) then good=&balvar;
if (&measure in (1)) then bad=&balvar;
keep GRP_&zm &period all good bad all_ass credit_limit;
run;


proc means data=br_am nway noprint;
class GRP_&zm &period;
var all good bad all_ass credit_limit;
output out=br_am_stat 
sum(all good bad all_ass credit_limit)=all good bad all_ass credit_limit
n(all)=n mean(all credit_limit)=sr credit_limit_sr
n(good bad all_ass)=good_n bad_n all_ass_n
;
run;

data br_am_stat;
set br_am_stat;
br=bad/all_ass;
br_n=bad_n/all_ass_n;
if _error_ then _error_=0;
run;


title "Numbers - all statistics for &measure by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc tabulate data=br_am_stat out=stat_am;
class GRP_&zm &period;
var all good bad good_n bad_n br br_n 
n all_ass credit_limit credit_limit_sr sr;
table
&period='' , GRP_&zm='GRP'*
( 
all='All'*sum=''*f=liczba.
sr='Average'*sum=''*f=liczba.
all='All percent'*rowpctsum=''*f=procent. 
all_ass='All assigned'*sum=''*f=liczba.
n='N'*sum=''*f=20.  
good='Good'*sum=''*f=liczba.
bad='Bad'*sum=''*f=liczba.
br='Bad rate'*sum=''*f=nlpct12.2  
n='All percent N'*rowpctsum=''*f=procent. 
good_n='Good N'*sum=''*f=12.
bad_n='Bad N'*sum=''*f=12.
br_n='Bad rate N'*sum=''*f=nlpct12.2  
credit_limit='Limit percent'*rowpctsum=''*f=procent. 
credit_limit_sr='Average limit'*sum=''*f=liczba.
)
/ box="&period";
run;

goptions reset=all;
symbol i=join v=dot;
title "Chart - number distribution by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc gplot data=stat_am;
plot n_PctSum_01_n*&period=GRP_&zm;
label GRP_&zm='GRP'
n_PctSum_01_n='Number percent';
format n_PctSum_01_n procent.;
run;
quit;


title "Chart - balance distribution by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc gplot data=stat_am;
plot all_PctSum_01_all*&period=GRP_&zm;
label GRP_&zm='GRP'
all_PctSum_01_all='Balance percent';
format all_PctSum_01_all procent.;
run;
quit;


title "Chart - average balance for attributes by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc gplot data=stat_am;
plot sr_sum*&period=GRP_&zm;
label GRP_&zm='GRP'
sr_sum='Average balance';
format sr_sum liczba.;
run;
quit;


title "Chart - average credit limit for attributes by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc gplot data=stat_am;
plot credit_limit_sr_Sum*&period=GRP_&zm;
label GRP_&zm='GRP'
credit_limit_sr_Sum='Average credit limit';
format credit_limit_sr_Sum liczba.;
run;
quit;


title "Chart - Balance bad rate for &measure by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc gplot data=stat_am;
plot br_sum*&period=GRP_&zm;
label br_sum="Balance bad rate &measure" GRP_&zm='GRP';
format br_sum nlpct12.2;
run;
quit;


title "Chart - Number bad rate for &measure by &period on state EM";
title2 "Attributes for variable &zm";
title3 "&label";
proc gplot data=stat_am;
plot br_n_sum*&period=GRP_&zm;
label br_n_sum="Number bad rate &measure" GRP_&zm='GRP';
format br_n_sum nlpct12.2;
run;
quit;
ods html close;
ods listing;
goptions reset=all device=win;


%end;

%mend;
%make_details;

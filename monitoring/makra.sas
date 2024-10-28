/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



options mprint;
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


/*population*/

%macro raport(period,g,des);
ods proclabel="Numbers - Score distribution and descriptive statistics for &des by &period";
title "Score distribution and descriptive statistics for &des by &period";
proc tabulate data=&pop_set out=score_dist;
class band &period;
var score;
where &g;
table
&period='' , band='Score band'*score=''*(n*f=14. rowpctn='Percent'*f=procent.)
score='Score'*(p5 p25 p50 mean p75 p95)*f=numx14.2 / box="&period";
run;

/*AXIS1 label=("Monthly sale [mln PLN]");*/
/*AXIS2 label=("Number of loans");*/
/*AXIS3 label=("Del amount") order=(0 to &mskalikr by 0.1);*/
/*AXIS4 label=("Del number") order=(0 to &mskalikr by 0.1);*/

AXIS1 label=("Score descriptive statistics");
AXIS2 label=("&period");

/*symbol v=dot i=join;*/

symbol1 i=join c=red line=1 v=dot h=0.5 w=2;
symbol2 i=join c=green line=1 v=dot h=0.5 w=2;
symbol3 i=join c=blue line=1  v=dot h=0.5 w=2;
symbol4 i=join c=black line=1 v=dot h=0.5 w=2;
symbol5 i=join c=yellow line=1 v=dot h=0.5 w=2;
symbol6 i=join c=cyan line=1 v=dot h=0.5 w=2;
symbol7 i=join c=brown line=1 v=dot h=0.5 w=2;

symbol8 i=join c=red line=2 v=dot h=0.5 w=2;
symbol9 i=join c=red line=3 v=dot h=0.5 w=2;
symbol10 i=join c=red line=4 v=dot h=0.5 w=2;

symbol11 i=join c=green line=2 v=dot h=0.5 w=2;
symbol12 i=join c=green line=3 v=dot h=0.5 w=2;
symbol13 i=join c=green line=4 v=dot h=0.5 w=2;

symbol14 i=join c=blue line=2 v=dot h=0.5 w=2;
symbol15 i=join c=blue line=3 v=dot h=0.5 w=2;
symbol16 i=join c=blue line=4 v=dot h=0.5 w=2;


symbol17 i=join c=black line=2 v=dot h=0.5 w=2;
symbol18 i=join c=black line=3 v=dot h=0.5 w=2;
symbol19 i=join c=black line=4 v=dot h=0.5 w=2;

symbol20 i=join c=yellow line=2 v=dot h=0.5 w=2;
symbol21 i=join c=yellow line=3 v=dot h=0.5 w=2;
symbol22 i=join c=yellow line=4 v=dot h=0.5 w=2;

symbol23 i=join c=cyan line=2 v=dot h=0.5 w=2;
symbol24 i=join c=cyan line=3 v=dot h=0.5 w=2;
symbol25 i=join c=cyan line=4 v=dot h=0.5 w=2;

symbol26 i=join c=brown line=2 v=dot h=0.5 w=2;
symbol27 i=join c=brown line=3 v=dot h=0.5 w=2;
symbol28 i=join c=brown line=4 v=dot h=0.5 w=2;


title "Score descriptive statistics for &des by &period";
ods proclabel="Plot - Score descriptive statistics for &des by &period";
proc gplot data=score_dist;
plot 
(score_P5 score_P25 score_P50 score_Mean score_P75 score_P95)*&period 
/ overlay legend haxis=axis1 vaxis=axis2;
where _TYPE_='01';
run;
quit;




title "Score distribution for &des by &period";
ods proclabel="Chart - Score distribution for &des by &period";
data dist;
set score_dist;
 Percent=score_PctN_01_score/100; 
/*Percent=score_PctN_01/100;*/
Number=score_N;
where _TYPE_='11';
run;
proc gplot data=dist;
plot percent*&period=band;
label band='Score band';
format percent nlpct12.2;
run;
quit;
%mend;


%macro raport_vars(period,g,des);
data vars;
delete;
run;
/*%do i=1 %to 2;*/
%do i=1 %to &il_zm;

ods proclabel="Numbers - Variable &&v&i";
title "Partial score distribution for &des by &period";
title2 "Variable name: &&v&i";
title3 "Variable description: &&o&i";
proc tabulate data=&pop_set out=score_v;
class &&v&i &period;
where &g;
table
&period='' , &&v&i="Partial score for &&v&i"
*(n*f=14. rowpctn='Percent'*f=procent.)
/ box="&period";
format &&v&i numx12.;
run;
data score_v;
set score_v;
Percent=PctN_01/100;
Number=N;
run;

ods proclabel="Chart - Variable &&v&i";
proc gplot data=score_v;
plot percent*&period=&&v&i;
label &&v&i="Partial score";
format percent nlpct12.2;
run;
quit;

data v;
length name $32;
name="&&v&i";
set score_v;
by &period;
if first.&period then avg_score=0;
avg_score+&&v&i*percent;
if last.&period then output;
keep &period name avg_score;
run;

data vars;
set vars v;
run;
%end;

ods proclabel="Numbers - Variable partial score for &des by &period";
title "Variable partial score for &des by &period";
title2;
title3;

proc tabulate data=vars;
class name &period;
var avg_score;
table &period='', avg_score='Average partial score'*
name='Variable name'*sum=''*f=numx12.2 / box="&period";
run;


symbol1 i=join c=red line=1 v=dot h=0.5 w=2;
symbol2 i=join c=green line=1 v=dot h=0.5 w=2;
symbol3 i=join c=blue line=1  v=dot h=0.5 w=2;
symbol4 i=join c=black line=1 v=dot h=0.5 w=2;
symbol5 i=join c=yellow line=1 v=dot h=0.5 w=2;
symbol6 i=join c=cyan line=1 v=dot h=0.5 w=2;
symbol7 i=join c=brown line=1 v=dot h=0.5 w=2;

symbol8 i=join c=red line=2 v=dot h=0.5 w=2;
symbol9 i=join c=red line=3 v=dot h=0.5 w=2;
symbol10 i=join c=red line=4 v=dot h=0.5 w=2;

symbol11 i=join c=green line=2 v=dot h=0.5 w=2;
symbol12 i=join c=green line=3 v=dot h=0.5 w=2;
symbol13 i=join c=green line=4 v=dot h=0.5 w=2;

symbol14 i=join c=blue line=2 v=dot h=0.5 w=2;
symbol15 i=join c=blue line=3 v=dot h=0.5 w=2;
symbol16 i=join c=blue line=4 v=dot h=0.5 w=2;


symbol17 i=join c=black line=2 v=dot h=0.5 w=2;
symbol18 i=join c=black line=3 v=dot h=0.5 w=2;
symbol19 i=join c=black line=4 v=dot h=0.5 w=2;

symbol20 i=join c=yellow line=2 v=dot h=0.5 w=2;
symbol21 i=join c=yellow line=3 v=dot h=0.5 w=2;
symbol22 i=join c=yellow line=4 v=dot h=0.5 w=2;

symbol23 i=join c=cyan line=2 v=dot h=0.5 w=2;
symbol24 i=join c=cyan line=3 v=dot h=0.5 w=2;
symbol25 i=join c=cyan line=4 v=dot h=0.5 w=2;

symbol26 i=join c=brown line=2 v=dot h=0.5 w=2;
symbol27 i=join c=brown line=3 v=dot h=0.5 w=2;
symbol28 i=join c=brown line=4 v=dot h=0.5 w=2;

ods proclabel="Plot - Variable partial score for &des by &period";
proc gplot data=vars;
plot avg_score*&period =name/ overlay legend;
label name='Variable name' avg_score='Average variable partial score'
&period="&period";
run;
quit;


proc means nway noprint data=&pop_set;
class &period;
var 
%do i=1 %to &il_zm;
&&v&i 
%end;
score;
where &g;
output out=score_impv n(score)=n range(
%do i=1 %to &il_zm;
&&v&i 
%end;
)=
%do i=1 %to &il_zm;
&&v&i 
%end;
 range(score)=score;
run;
data score_impv;
set score_impv;
%do i=1 %to &il_zm;
&&v&i=&&v&i/score;
format &&v&i nlpct12.2;
%end;
run;

ods proclabel="Numbers - Importance of variables for &des by &period";
title "Importance of variables for &des by &period";


proc tabulate data=score_impv;
class &period;
var 
%do i=1 %to &il_zm;
&&v&i 
%end; ;
table
&period='' , sum="Importance of variable"
* (
%do i=1 %to &il_zm;
&&v&i 
%end;
)
*f=nlpct12.2
/ box="&period";
run;

ods proclabel="Plot - Importance of variables for &des by &period";

AXIS1 label=("Importance of variables");

proc gplot data=score_impv;
plot (
%do i=1 %to &il_zm;
&&v&i 
%end;
)*&period
/ overlay legend haxis=axis1;
label &period="&period";
run;
quit;

%mend;



%macro all_distribution(title,group,info,file);

proc sql noprint;
insert into raporty_spis
values('Distribution',"&title for &info","&title._index_score_&file..html");
quit;

goptions device=png;
ods listing close;
ods html path="&dir" (url=none) 
frame="&title._index_score_&file..html"
body="&title._score_b_&file..html"
contents="&title._score_c_&file..html"
style=statistical;
%raport(&time_dim,&group,&info);
%raport_vars(&time_dim,&group,&info);
ods html close;
ods listing;
goptions  device=win;
%mend;

/*gini*/
%macro licz_g(period);
proc means data=&br_set noprint nway;
var &risk_m;
class &period;
output out=stat mean(&risk_m)=
&risk_m;
run;

data gini;
set stat;
keep &period;
run;




%do i=1 %to &il_t;

data &&tar&i;
length &period $ 6 &&tar&i 8;
delete;
run;

proc sql noprint;
select &period into :periods separated by ' '
from stat where &&tar&i>0;
/*from stat where not missing(&&tar&i);*/
quit;
%let il_p=&sqlobs;
%put &il_p***&periods;

%do j=1 %to &il_p;

%let p=%scan(&periods,&j,%str( ));

data a;
label2="Somers' D";
nValue2=.;
run;


ods listing close;
ods output Association(persist=proc)=a;
proc logistic data=&gini_set desc;
model &&tar&i=score;
where &period="&p";
run;
ods output close;
ods listing;

data e;
&period="&p";
set a;
rename nValue2=&&tar&i;
format nValue2 nlpct12.2;
where label2="Somers' D";
run;

data &&tar&i;
set &&tar&i e;
keep &period &&tar&i;
run;


%end;

data gini;
merge gini(in=z) &&tar&i;
by &period;
if z;
run;

%end;

data gini_&period;
length &risk_m 8;
set gini;
run;

%mend;

%macro licz_vars_g(period);
proc means data=&br_set noprint nway;
var &risk_m;
class &period;
output out=stat mean(&risk_m)=
&risk_m;
run;

data gini_vars;
delete;
run;

%do z=1 %to &il_zm;

data gini;
length var $ 32;
set stat;
var="&&v&z";
keep &period var;
run;


%do i=1 %to &il_t;

data &&tar&i;
delete;
run;

proc sql noprint;
select &period into :periods separated by ' '
from stat where &&tar&i>0;
/*from stat where not missing(&&tar&i);*/
quit;
%let il_p=&sqlobs;
%put &il_p***&periods;

%do j=1 %to &il_p;

%let p=%scan(&periods,&j,%str( ));

data a;
label2="Somers' D";
nValue2=.;
run;


ods listing close;
ods output Association(persist=proc)=a;
proc logistic data=&gini_set desc;
class &&v&z;
model &&tar&i=&&v&z;
where &period="&p";
run;
ods output close;
ods listing;

data e;
&period="&p";
set a;
rename nValue2=&&tar&i;
format nValue2 nlpct12.2;
where label2="Somers' D";
run;

data &&tar&i;
set &&tar&i e;
keep &period &&tar&i;
run;


%end;

data gini;
merge gini(in=z) &&tar&i;
by &period;
if z;
run;

%end;

data gini_vars;
set gini_vars gini;
run;

%end;

data gini_vars_&period;
set gini_vars;
run;

%mend;


%macro raport_g(period);
symbol1 i=join c=red line=1 v=dot h=0.5 w=2;
symbol2 i=join c=green line=1 v=dot h=0.5 w=2;
symbol3 i=join c=blue line=1  v=dot h=0.5 w=2;
symbol4 i=join c=black line=1 v=dot h=0.5 w=2;
symbol5 i=join c=yellow line=1 v=dot h=0.5 w=2;
symbol6 i=join c=cyan line=1 v=dot h=0.5 w=2;
symbol7 i=join c=brown line=1 v=dot h=0.5 w=2;

symbol8 i=join c=red line=2 v=dot h=0.5 w=2;
symbol9 i=join c=red line=3 v=dot h=0.5 w=2;
symbol10 i=join c=red line=4 v=dot h=0.5 w=2;

symbol11 i=join c=green line=2 v=dot h=0.5 w=2;
symbol12 i=join c=green line=3 v=dot h=0.5 w=2;
symbol13 i=join c=green line=4 v=dot h=0.5 w=2;

symbol14 i=join c=blue line=2 v=dot h=0.5 w=2;
symbol15 i=join c=blue line=3 v=dot h=0.5 w=2;
symbol16 i=join c=blue line=4 v=dot h=0.5 w=2;


symbol17 i=join c=black line=2 v=dot h=0.5 w=2;
symbol18 i=join c=black line=3 v=dot h=0.5 w=2;
symbol19 i=join c=black line=4 v=dot h=0.5 w=2;

symbol20 i=join c=yellow line=2 v=dot h=0.5 w=2;
symbol21 i=join c=yellow line=3 v=dot h=0.5 w=2;
symbol22 i=join c=yellow line=4 v=dot h=0.5 w=2;

symbol23 i=join c=cyan line=2 v=dot h=0.5 w=2;
symbol24 i=join c=cyan line=3 v=dot h=0.5 w=2;
symbol25 i=join c=cyan line=4 v=dot h=0.5 w=2;

symbol26 i=join c=brown line=2 v=dot h=0.5 w=2;
symbol27 i=join c=brown line=3 v=dot h=0.5 w=2;
symbol28 i=join c=brown line=4 v=dot h=0.5 w=2;



title "Numbers - Risk statistics by &period on state &state";
ods proclabel="Numbers - Risk statistics by &period on state &state";

proc tabulate data=&br_set;
var &risk_m;
class &period;
table &period='', n='Production'*f=14.
(&risk_m)*mean=''*f=nlpct12.2
/ box="&period";
run;


proc means data=&br_set noprint nway;
var &risk_m;
class &period;
output out=stat mean(&risk_m)=
&risk_m;
format &risk_m nlpct12.2;
run;


title "Plot - Production by &period on state &state";
ods proclabel="Plot - Production by &period on state &state";
proc gplot data=stat;
plot _freq_*&period;
format _freq_ 14.;
label _freq_='Production';
run;
quit;

title "Plot - Risk statistics by &period on state &state";
ods proclabel="Plot - Risk statistics by &period on state &state";
proc gplot data=stat;
plot 
(&risk_m)*&period 
/ overlay legend;
format &risk_m nlpct12.2;
run;
quit;



title "Numbers - Gini on different risk statistics by &period on state &state";
ods proclabel="Numbers - Gini on different risk statistics by &period on state &state";
proc tabulate data=gini_&period;
var &risk_m;
class &period;
table &period='', (&risk_m)*sum=''*f=nlpct12.2
/ box="&period";
run;




title "Plot - Gini on different risk statistics by &period on state &state";
ods proclabel="Plot - Gini on different risk statistics by &period on state &state";

proc gplot data=gini_&period;
plot 
(&risk_m) *&period 
/ overlay legend haxis=0 to 1 by 0.1;
format &risk_m nlpct12.2;
run;
quit;

%mend;

%macro raport_vars_g(period);
title "Numbers - Variable Gini on different risk statistics by &period on state &state";
ods proclabel="Numbers - Variable Gini on different risk statistics by &period on state &state";

proc tabulate data=gini_vars_&period;
class var &period;
var &risk_m;
table var=''*&period='',
(&risk_m)*sum=''*f=nlpct12.2
/ box="Variable / &period";
run;
%mend;


%macro all_gini(title);

proc sql noprint;
insert into raporty_spis
values('Gini',"&title","&title._index_gini_&state..html");
quit;



%licz_g(&time_dim);
/*%licz_vars_g(&time_dim);*/

goptions device=png;
ods listing close;
ods html path="&dir" (url=none) 
frame="&title._index_gini_&state..html"
body="&title._b_gini_&state..html" 
contents="&title._c_gini_&state..html"
style=statistical;
%raport_g(&time_dim);
/*%raport_vars_g(&time_dim);*/
ods html close;
ods listing;
goptions  device=win;
%mend;

/*bad rate*/
%macro bad_rate(period,measure);
ods proclabel="Numbers - risk measure &measure for score bands by &period on state &state";
title "Numbers - risk measure &measure for score bands by &period on state &state";
proc tabulate data=&br_set out=stat;
class band &period;
var &measure;
table
&period='' , band='Score band'*(&measure*mean=''*f=nlpct12.2  &measure=''*n='N'*f=12.)  / box="&period";
run;

title "Chart - risk measure &measure for score bands by &period on state &state";
ods proclabel="Chart - risk measure &measure for score bands by &period on state &state";
data stat;
set stat;
Bad_rate=&measure._mean;
Number=&measure._N;
run;

%let cent=0.001;
proc univariate data=stat noprint;
var bad_rate;
output out=cent max=p_&nr_cent;
/*output out=cent pctlpre=P_ pctlpts=&nr_cent;*/
where bad_rate < 1;
run;
data _null_;
set cent;
if p_&nr_cent<0.001 then p_&nr_cent=0.001;
call symput('cent',put(1.2*p_&nr_cent,best12.-L));
run;
%put &cent;

proc gplot data=stat;
plot Bad_rate*&period=band;
label band='Score band'
bad_rate="&measure";
format bad_rate nlpct12.2;
run;
quit;
%mend;
%macro bad_rate_vars(period,measure);
%do i=1 %to &il_zm;

ods proclabel="Numbers - Variable &&v&i";
title "Risk measure &measure for partial score by &period on state &state";
title2 "Variable name: &&v&i";
title3 "Variable description: &&o&i";
proc tabulate data=&br_set out=stat_br;
class &&v&i &period;
var &measure;
table
&period='' , &&v&i="Partial score for &&v&i"*
(&measure*mean=''*f=nlpct12.2  &measure=''*n='N'*f=12.)  / box="&period";
format &&v&i numx12.;
run;

data stat_br;
set stat_br;
Bad_rate=&measure._mean;
Number=&measure._N;
run;

%let cent=0.001;
proc univariate data=stat_br noprint;
var bad_rate;
output out=cent max=p_&nr_cent;
/*output out=cent pctlpre=P_ pctlpts=&nr_cent;*/
where bad_rate < 1;
run;
data _null_;
set cent;
if p_&nr_cent<0.001 then p_&nr_cent=0.001;
call symput('cent',put(1.2*p_&nr_cent,best12.-L));
run;
%put &cent;


ods proclabel="Chart - Variable &&v&i";
proc gplot data=stat_br;
plot Bad_rate*&period=&&v&i;
label &&v&i='Partial score'
bad_rate="&measure";
format bad_rate nlpct12.2;
run;
quit;
%end;
%mend;




%macro all_bad_rate(title);
%do risk_i=1 %to &il_t;
/*%do risk_i=1 %to 1;*/


%let risk_tar=&&tar&risk_i;

proc sql noprint;
insert into raporty_spis
values('Bad rate',"&title for &risk_tar","&title._index_bad_rate_&risk_tar._&state..html");
quit;



goptions device=png;
ods listing close;
ods html path="&dir" (url=none) 
frame="&title._index_bad_rate_&risk_tar._&state..html"
body="&title._b_bad_rate_&risk_tar._&state..html" 
contents="&title._c_bad_rate_&risk_tar._&state..html"
style=statistical;
%bad_rate(&time_dim,&risk_tar);
%bad_rate_vars(&time_dim,&risk_tar);
ods html close;
ods listing;
goptions  device=win;

%end;
%mend;

%macro spis_tresci(title,file);
data raporty_spis;
set raporty_spis;
href= 
'<a href="'||compress(link)||'">'||
trim(raport)||'</a>';
run;

proc sort data=raporty_spis;
by rodzaj raport;
run;

options linesize=256;

goptions device=png;
ods listing close;
ods html path="&dir" (url=none) 
body="&file._index_main.html" 
style=statistical;
title "&title";

proc print data=raporty_spis label;
id rodzaj;
by rodzaj;
var href;
label rodzaj='Report type' href='Report';
run;



ods html close;
ods listing;
goptions  device=win;
%mend;




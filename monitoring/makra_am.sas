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


/*bad rate amount*/
%macro bad_rate_am(period,measure,balvar,desc_bal);
data br_am;
set &gini_set;
all=&balvar;
all_ass=&balvar*(&measure in (.d,.i,0,1));
good=&balvar*(&measure in (0));
bad=&balvar*(&measure in (1));
keep band &period all good bad all_ass;
run;
proc means data=br_am nway noprint;
class band &period;
var all good bad all_ass;
output out=br_am_stat sum(all good bad all_ass)=all good bad all_ass
n(all)=n mean(all)=sr;
run;
data br_am_stat;
set br_am_stat;
br=bad/all_ass;
if _error_ then _error_=0;
run;


ods proclabel="Numbers - risk balance &desc_bal measure &measure for score bands by &period on state &state";
title "Numbers - risk  balance &desc_bal measure &measure for score bands by &period on state &state";
proc tabulate data=br_am_stat out=stat_am;
class band &period;
var all good bad br n all_ass sr;
table
&period='' , band='Score band'*
( 
all='All'*sum=''*f=liczba.
sr='Average'*sum=''*f=liczba.
all='All percent'*rowpctsum=''*f=procent. 
all_ass='All assigned'*sum=''*f=liczba.
n='N'*sum=''*f=20.  
good='Good'*sum=''*f=liczba.
bad='Bad'*sum=''*f=liczba.
br='Bad rate'*sum=''*f=nlpct12.2  
)
/ box="&period";
run;
data stat_am;
set stat_am;
Bad_rate=br_sum;
all=all_sum;
percent=all_PctSum_01_all/100;
Bad=bad_sum;
number=n_sum;
sr=sr_sum;
run;

title "Chart - balance &desc_bal distribution for score bands by &period on state &state";
ods proclabel="Chart - balance &desc_bal distribution for score bands by &period on state &state";
proc gplot data=stat_am;
plot percent*&period=band;
label band='Score band'
percent='Balance percent';
format percent nlpct12.2 all liczba.;
run;
quit;


title "Chart - average balance &desc_bal for score bands by &period on state &state";
ods proclabel="Chart - average balance &desc_bal for score bands by &period on state &state";
proc gplot data=stat_am;
plot sr*&period=band;
label band='Score band'
sr='Average balance';
format all sr liczba.;
run;
quit;

%let cent=0.001;
proc univariate data=stat_am noprint;
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


title "Chart - risk balance &desc_bal measure &measure for score bands by &period on state &state";
ods proclabel="Chart - risk balance &desc_bal measure &measure for score bands by &period on state &state";
proc gplot data=stat_am;
plot Bad_rate*&period=band;
label band='Score band'
bad_rate="&measure";
format bad_rate nlpct12.2 bad liczba.;
run;
quit;
%mend;


%macro bad_rate_vars_am(period,measure,balvar,desc_bal);
%do i=1 %to &il_zm;

data br_am;
set &gini_set;
all=&balvar;
all_ass=&balvar*(&measure in (.d,.i,0,1));
good=&balvar*(&measure in (0));
bad=&balvar*(&measure in (1));
keep &period all good bad &&v&i all_ass;
run;
proc means data=br_am nway noprint;
class &&v&i &period;
var all good bad all_ass;
output out=br_am_stat sum(all good bad all_ass)=all good bad all_ass
n(all)=n mean(all)=sr;
run;
data br_am_stat;
set br_am_stat;
br=bad/all_ass;
if _error_ then _error_=0;
run;


ods proclabel="Numbers - Variable &&v&i";
title "Risk balance &desc_bal measure &measure for partial score by &period on state &state";
title2 "Variable name: &&v&i";
title3 "Variable description: &&o&i";
proc tabulate data=br_am_stat out=stat_am;
class &&v&i &period;
var all good bad br n all_ass sr;
table
&period='' , &&v&i="Partial score for &&v&i"*
(
all='All'*sum=''*f=liczba.
sr='Average'*sum=''*f=liczba.
all='All percent'*rowpctsum=''*f=procent. 
all_ass='All assigned'*sum=''*f=liczba.
n='N'*sum=''*f=20.  
good='Good'*sum=''*f=liczba.
bad='Bad'*sum=''*f=liczba.
br='Bad rate'*sum=''*f=nlpct12.2  
)  / box="&period";
format &&v&i numx12.;
run;
data stat_am;
set stat_am;
Bad_rate=br_sum;
all=all_sum;
percent=all_PctSum_01_all/100;
Bad=bad_sum;
number=n_sum;
sr=sr_sum;
run;

ods proclabel="Chart - Variable &&v&i balance distribution";
title "Chart - balance &desc_bal distribution for partial score by &period on state &state";
title2 "Variable name: &&v&i";
title3 "Variable description: &&o&i";
proc gplot data=stat_am;
plot percent*&period=&&v&i;
label &&v&i='Partial score'
percent='Balance percent';
format percent nlpct12.2 all liczba.;
run;
quit;

ods proclabel="Chart - Variable &&v&i average balance";
title "Chart - average balance &desc_bal for partial score by &period on state &state";
title2 "Variable name: &&v&i";
title3 "Variable description: &&o&i";
proc gplot data=stat_am;
plot sr*&period=&&v&i;
label &&v&i='Partial score'
sr='Average balance';
format all sr liczba.;
run;
quit;

%let cent=0.001;
proc univariate data=stat_am noprint;
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


ods proclabel="Chart - Variable &&v&i balance bad rate";
title "Chart - risk balance &desc_bal measure &measure for score bands by &period on state &state";
title2 "Variable name: &&v&i";
title3 "Variable description: &&o&i";
proc gplot data=stat_am;
plot Bad_rate*&period=&&v&i;
label &&v&i='Partial score'
bad_rate="&measure";
format bad_rate nlpct12.2 bad liczba.;
run;
quit;
%end;
%mend;




%macro all_bad_rate_am(title);
%do risk_i=1 %to &il_t;
%let risk_tar=&&tar&risk_i;
proc sql noprint;
insert into raporty_spis
values('Bad rate begin',"&title for &risk_tar","&title._index_bad_rate_beg_&risk_tar._&state..html");
quit;

goptions device=png;
ods listing close;
ods html path="&dir" (url=none) 
frame="&title._index_bad_rate_beg_&risk_tar._&state..html"
body="&title._b_bad_rate_beg_&risk_tar._&state..html" 
contents="&title._c_bad_rate_beg_&risk_tar._&state..html"
style=statistical;
%bad_rate_am(&time_dim,&risk_tar,Outstanding,begining);
%bad_rate_vars_am(&time_dim,&risk_tar,Outstanding,begining);
ods html close;
ods listing;
goptions device=win;

%end;


%mend;

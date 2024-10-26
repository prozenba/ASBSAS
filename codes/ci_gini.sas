/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



libname kal (models);


ods listing close;
ods output Association=roc;
proc logistic data=kal.score&the_best_model desc namelen=32;
model &tar=&score_points;
run;
ods output close;
ods listing;

data _null_;
set roc;
where label2='c';
call symput('c',put(nvalue2,best12.));
run;
%put &c;
data d;
set kal.score&the_best_model end=e;
n=_n_;
if e then call symput('n_cust',put(n,best12.));
run;
%put &n_cust;
proc means data=d nway noprint;
var n;
class &score_points;
class &tar;
output out=freq(drop=_type_ _freq_) n()=n;
run;
proc sort data=freq;
by &score_points &tar;
run;
proc transpose data=freq prefix=def out=tfreq;
var n;
by &score_points;
id &tar;
run;



proc sql noprint;
select count(distinct &score_points) into :n_score from freq;
quit;
%put &n_score;


data czesci;
length std_c var_c l95_c c u95_c l99_c u99_c std_ar var_ar l95_ar ar u95_ar l99_ar u99_ar 8;
array d(&n_score);
array nond(&n_score);
do i=1 to &n_score;
set tfreq;
d(i)=coalesce(def1,0);
nond(i)=coalesce(def0,0);
end;

SumNonDefaults = 0;
SumDefaults = 0;

do i = 1 To &n_score;
    SumNonDefaults = SumNonDefaults + NonD(i);
    SumDefaults = SumDefaults + D(i);
end;

Equal = 0;
Part1 = 0;
Part2 = 0;
Part3 = 0;
Part4 = 0;

do i = 1 To &n_score;
    Equal = Equal + NonD(i) * D(i);
    do j = 1 To &n_score;
        do k = 1 To &n_score;
            If (k > i And k > j) Or (k < i And k < j) Then do;
                Part1 = Part1 + (D(i) * D(j) * NonD(k));
                Part3 = Part3 + (NonD(i) * NonD(j) * D(k));
            end;
            If (i < k And k < j) Or (j < k And k < i) Then do;
                Part2 = Part2 + (D(i) * D(j) * NonD(k));
                Part4 = Part4 + (NonD(i) * NonD(j) * D(k));
            end;
        end;
    end;
end;

c = &c;
Prob_D_NotEqual_NonD = 1 - Equal / (SumNonDefaults * SumDefaults);
Prob_D_D_ND = (Part1 - Part2) / (SumDefaults * SumDefaults * SumNonDefaults);
Prob_ND_ND_D = (Part3 - Part4) / (SumNonDefaults * SumNonDefaults * SumDefaults);
Nd = SumDefaults;
Nnd = SumNonDefaults;

std_c = (1 / (4 * (Nd - 1) * (Nnd - 1)) * (Prob_D_NotEqual_NonD + (Nd - 1) * Prob_D_D_ND
                + (Nnd - 1) * Prob_ND_ND_D - 4 * (Nnd + Nd - 1) * (c - 0.5) ** 2)) ** 0.5;
var_c=std_c**2;

l95_c=c-probit((1+0.95)/2)*Std_C;
u95_c=c+probit((1+0.95)/2)*Std_C;
l99_c=c-probit((1+0.99)/2)*Std_C;
u99_c=c+probit((1+0.99)/2)*Std_C;

ar=2*c-1;
std_ar=2*Std_C;
var_ar=std_ar**2;

l95_ar=ar-probit((1+0.95)/2)*Std_ar;
u95_ar=ar+probit((1+0.95)/2)*Std_ar;
l99_ar=ar-probit((1+0.99)/2)*Std_ar;
u99_ar=ar+probit((1+0.99)/2)*Std_ar;


output;
keep Std_C var_c c l95_c u95_c l99_c u99_c Std_ar var_ar ar l95_ar u95_ar l99_ar u99_ar;
run;


data kal.ci_c_ar&the_best_model;
set czesci;
label
std_c='Standard deviation of C' 
var_c='Variance of C' 
c='Value of C' 
l95_c='Lower 95% confidence intarval' 
u95_c='Upper 95% confidence intarval' 
l99_c='Lower 99% confidence intarval' 
u99_c='Upper 99% confidence intarval' 
;
label
std_ar='Standard deviation of AR' 
var_ar='Variance of AR' 
ar='Value of AR' 
l95_ar='Lower 95% confidence intarval' 
u95_ar='Upper 95% confidence intarval' 
l99_ar='Lower 99% confidence intarval' 
u99_ar='Upper 99% confidence intarval' 
;
run;

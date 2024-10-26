/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



/*options mprint;*/
libname d (&lib);



%let max_n_uni=20;

%let name_ps_org_diff          =PS_Org_Diff  ;
%let name_ps_org_train         =PS_Org_Train ;
%let name_ps_org_valid         =PS_Org_Valid ;

%let name_ps_grp_diff          =PS_Grp_Diff  ;
%let name_ps_grp_train         =PS_Grp_Train ;
%let name_ps_grp_valid         =PS_Grp_Valid ;

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

%let def_var=
length
&name_pr_miss_train  
&name_pr_miss_valid  
&name_n_uni_train       
&name_n_uni_valid 
 
&name_pr_mfrequent_train 
&name_pr_mfrequent_valid
8
 
&name_mfrequent_train $ 20       
&name_mfrequent_valid $ 20  

&name_ks_01_train  
&name_ks_01_valid 
&name_ks_01_diff

&name_h_01_train
&name_h_01_valid 
&name_h_01_diff

&name_max_dist_01_train        
&name_max_dist_01_valid 
&name_max_dist_01_diff 

&name_c_01_train
&name_c_01_valid
&name_c_01_diff         

&name_ps_org_diff  
&name_ps_org_train 
&name_ps_org_valid 

&name_ps_grp_diff  
&name_ps_grp_train 
&name_ps_grp_valid 
 
&name_ar_train          
&name_ar_valid   
&name_ar_diff  

&name_h_tv              
&name_h_br_tv           
&name_ks_tv             
&name_ks_br_tv          
       
&name_h_grp_train  
&name_h_grp_valid 
&name_h_grp_diff   
 
&name_max_dist_grp_train     
&name_max_dist_grp_valid
&name_max_dist_grp_diff 

&name_h_grp_tv          
&name_max_dist_grp_tv   

&name_h_br_grp_tv       
&name_max_br_dist_grp_tv
8
;



%let prawiezero=0.000000001;
%macro licz_h(z1,z2,variable,wyn);
proc freq data=&z1 noprint;
table &variable / missing out=f1;
run;
proc freq data=&z2 noprint;
table &variable / missing out=f2;
run;
data f1;
set f1;
okres="1";
run;
data f2;
set f2;
okres="2";
run;
data zb;
merge 
f1(rename=(percent=p1))
f2(rename=(percent=p2));
by &variable;
drop count okres;
run; 
data &wyn;
retain maxd h 0;
set zb end=e;
if missing(p1) then p1=0;
if missing(p2) then p2=0;
maxd=max(maxd,abs(p1-p2));
if p1=0 then p1=&prawiezero;
if p2=0 then p2=&prawiezero;
h=sum(h,p1*log(p1/p2));
if e;
maxd=maxd/100;
h=h/100;
keep maxd h;
run;
%mend;



proc sql;
create table &lib..variables_inset_fin as
select upcase(substr(variable,5)) as name
from &lib..good_variables_stat_1step;
quit;


data variables_stat;
length variable $32 level $10;
&def_var;
format
&name_pr_miss_train  
&name_pr_miss_valid  
&name_pr_mfrequent_train 
&name_pr_mfrequent_valid
&name_ks_01_diff
&name_h_01_diff
&name_max_dist_01_diff 
&name_c_01_diff         

&name_ps_org_diff         
&name_ps_grp_diff         

&name_ar_diff  
&name_h_grp_diff   
&name_max_dist_grp_diff 
percent12.2
;
delete;
run;

%macro validuj_zmienne(train,valid,lista,max_il=1);

%global
ks_01_train       
h_01_train        
max_dist_01_train 
ks_01_valid       
h_01_valid        
max_dist_01_valid 
c_01_diff         
c_01_train        
c_01_valid        
ks_01_diff        
h_01_diff         
max_dist_01_diff  
pr_mfrequent_train     
mfrequent_train        
pr_miss_train     
n_uni_train       
pr_mfrequent_valid     
mfrequent_valid        
pr_miss_valid     
n_uni_valid       
h_tv              
h_br_tv           
ks_tv             
ks_br_tv          
ar_diff           
ar_train          
ar_valid          
h_grp_train       
max_dist_grp_train
h_grp_valid       
max_dist_grp_valid
h_grp_diff        
max_dist_grp_diff 
h_grp_tv          
max_dist_grp_tv   
h_br_grp_tv       
max_br_dist_grp_tv
;


data _null_;
set &lista(obs=1) nobs=il;
call symput('il',put(il,best12.-L));
run;
%if (&max_il eq 0 or &max_il>&il) %then %let max_il=&il;
%do i=1 %to &max_il;


%let ps_org_train      =.;
%let ps_org_valid      =.;
%let ps_org_diff       =.;

%let ks_01_train       =. ;
%let h_01_train        =. ;
%let max_dist_01_train =. ;
%let ks_01_valid       =. ;
%let h_01_valid        =. ;
%let max_dist_01_valid =. ;
%let c_01_diff         =. ;
%let c_01_train        =. ;
%let c_01_valid        =. ;
%let ks_01_diff        =. ;
%let h_01_diff         =. ;
%let max_dist_01_diff  =. ;
%let pr_mfrequent_train     =. ;
%let mfrequent_train        =* ;
%let pr_miss_train     =. ;
%let n_uni_train       =. ;
%let pr_mfrequent_valid     =. ;
%let mfrequent_valid        =* ;
%let pr_miss_valid     =. ;
%let n_uni_valid       =. ;
%let h_tv              =. ;
%let h_br_tv           =. ;
%let ks_tv             =. ;
%let ks_br_tv          =. ;
%let ar_diff           =. ;
%let ar_train          =. ;
%let ar_valid          =. ;
%let h_grp_train       =. ;
%let max_dist_grp_train=. ;
%let h_grp_valid       =. ;
%let max_dist_grp_valid=. ;
%let h_grp_diff        =. ;
%let max_dist_grp_diff =. ;
%let h_grp_tv          =. ;
%let max_dist_grp_tv   =. ;
%let h_br_grp_tv       =. ;
%let max_br_dist_grp_tv=. ;




data _null_;
set &lista(obs=&i firstobs=&i);
call symput('z_org',name);
run;

%let z_woe=WOE_&z_org;
%let z_grp=GRP_&z_org;
%put &z_woe &z_org &z_grp;

data train_zm;
set &train(keep=&tar &z_woe &z_org &z_grp);
run;

data valid_zm;
set &valid(keep=&tar &z_woe &z_org &z_grp);
run;


%let level=Pusty;
proc sql noprint;
select upcase(type) into :level
from &data_variableset
where upcase(variable) eq "%upcase(&z_org)";
quit;
%put &z_org &z_woe level=&level;


data z;
set &data_variableset;
where upcase(variable) eq "&z_org";
variable=upcase(variable);
rename variable=variable;
keep variable;
run;

/*na oryginalnych:*/
/*liczba unikalnych wartosci*/
/*najczestsza wartosc oprocz braku*/
/*procent brakow danych*/
/*c i ks lub h na 0 i 1 train i valid*/
/*ks h ks_br h_br na okresach*/
/*c_01_diff*/
/**/


/*na oryginalnych:*/

%macro licz_org(naz,zb_wej);
%global pr_mfrequent_&naz mfrequent_&naz pr_miss_&naz n_uni_&naz 
c_01_&naz ks_01_&naz h_01_&naz max_dist_01_&naz;

proc freq data=&zb_wej(keep=&z_org) noprint ;
table &z_org / out=f missing;
run;
proc sort data=f;
by descending percent;
run;

%let pr_miss_&naz=0;
proc sql noprint;
select PERCENT/100,&z_org into :pr_mfrequent_&naz,:mfrequent_&naz
from f(obs=1) where &z_org is not missing;
select sum(PERCENT)/100 into :pr_miss_&naz
from f where missing(&z_org);
quit;
%put &&pr_mfrequent_&naz &&mfrequent_&naz &&pr_miss_&naz;
data _null_;
set f(obs=1) nobs=il;
call symput("n_uni_&naz",put(il,best12.-L));
run;
%put &&n_uni_&naz;

%let c_01_&naz=.;

%if %sysfunc(exist(a)) %then %do;
proc delete data=a;
run;
%end;

%if (&level eq INT or &n_uni_train <= &max_n_uni) %then %do;
ods listing close;
ods output Association=a;
%if &naz=train %then %do;
	proc logistic data=&zb_wej(keep=&tar &z_org) desc outest=b namelen=32;
	%if &level ne INT %then %do;
	class &z_org;
	%end;
	model &tar=&z_org;
	run;
%end; %else %do;
	proc logistic data=&zb_wej(keep=&tar &z_org) desc inest=b namelen=32;
	%if &level ne INT %then %do;
	class &z_org;
	%end;
	model &tar=&z_org / maxiter=0;
	run;
%end;
ods output close;
ods listing;
%end;

%if %sysfunc(exist(a)) %then %do;
data _null_;
set a;
where label2='c';
if _n_=1 then call symput("c_01_&naz",put(nValue2,best12.-L));
run;
%end;

%put &&c_01_&naz;

%if &level ne INT %then %do;
%let ks_01_&naz=.;
%let max_dist_01_&naz=.;
%licz_h(&zb_wej(keep=&tar &z_org where=(&tar=0)),
&&&naz(keep=&tar &z_org where=(&tar=1)),&z_org,wyn);
data _null_;
set wyn;
call symput("h_01_&naz",put(h,best12.-L));
call symput("max_dist_01_&naz",put(maxd,best12.-L));
run;
%end; %else %do;
%let h_01_&naz=.;
proc npar1way data=&zb_wej(keep=&tar &z_org) edf wilcoxon noprint;
class &tar;
var &z_org;
output out=ks wilcoxon edf;
run;
data _null_;
set ks;
call symput("ks_01_&naz",put(_d_,best12.-L));
run;
%end;
%put &&ks_01_&naz;
%put &&h_01_&naz;
%put &&max_dist_01_&naz;

/*%powerc(&&&naz,&z_org,&tar);*/
/*data _null_;*/
/*set power;*/
/*call symput("ps_org_&naz",put(powerpercent,best12.-L));*/
/*run;*/
%let ps_org_&naz=.;
%put &&ps_org_&naz;

%mend;
%licz_org(train,train_zm);
%licz_org(valid,valid_zm);

%let ps_org_diff=%sysfunc(putn((&ps_org_train-&ps_org_valid)/&ps_org_train,best12.-L));
%put &ps_org_diff;

%let c_01_diff=%sysfunc(putn((&c_01_train-&c_01_valid)/&c_01_train,best12.-L));
%put &c_01_diff;

%let h_01_diff=%sysfunc(putn((&h_01_train-&h_01_valid)/&h_01_train,best12.-L));
%put &h_01_diff;

%let ks_01_diff=%sysfunc(putn((&ks_01_train-&ks_01_valid)/&ks_01_train,best12.-L));
%put &ks_01_diff;

%let max_dist_01_diff=%sysfunc(
putn((&max_dist_01_train-&max_dist_01_valid)/&max_dist_01_train,best12.-L));
%put &max_dist_01_diff;

%macro licz_naokresach_org;
%global h_tv h_br_tv ks_tv ks_br_tv;
%if &level ne INT %then %do;
%licz_h(train_zm(keep=&z_org),valid_zm(keep=&z_org),&z_org,wyn);
data _null_;
set wyn;
call symput("h_tv",put(h,best12.-L));
call symput("h_br_tv",put(maxd,best12.-L));
run;
%let ks_tv=.;
%let ks_br_tv=.;

%end; %else %do;
%let h_tv=.;
%let h_br_tv=.;
data razem;
set train_zm(in=z keep=&z_org &tar) valid_zm(keep=&z_org &tar);
t=z;
run;
proc npar1way data=razem edf wilcoxon noprint;
class t;
var &z_org;
output out=ks wilcoxon edf;
run;
data _null_;
set ks;
call symput("ks_tv",put(_d_,best12.-L));
run;

proc npar1way data=razem(where=(&tar=1)) edf wilcoxon noprint;
class t;
var &z_org;
output out=ks wilcoxon edf;
run;
data _null_;
set ks;
call symput("ks_br_tv",put(_d_,best12.-L));
run;

%end;
%mend;
%licz_naokresach_org;

%put &h_tv &h_br_tv &ks_tv &ks_br_tv;


/*na woe:*/
/*ar_01 na okresach*/
/**/
%macro licz_ar_woe;
%if %sysfunc(exist(a)) %then %do;
proc delete data=a;
run;
%end;

ods listing close;
ods output Association(persist=proc)=a;
proc logistic data=train_zm(keep=&tar &z_woe) desc outest=b namelen=32;
model &tar=&z_woe;
run;
proc logistic data=valid_zm(keep=&tar &z_woe) desc inest=b namelen=32;
model &tar=&z_woe / maxiter=0;
run;
ods output close;
ods listing;

%if %sysfunc(exist(a)) %then %do;
data n;
set a;
where label2='c';
ar=2*nValue2-1;
if _n_=1 then call symput('ar_train',put(ar,best12.-L));
if _n_=2 then call symput('ar_valid',put(ar,best12.-L));
run;
%end;
%mend;
%licz_ar_woe;
%let ar_diff=%sysfunc(putn((&ar_train-&ar_valid)/&ar_train,best12.-L));
%put &ar_diff;
%put &ar_train &ar_valid;


%powerc(train_zm,&z_grp,&tar);
data _null_;
set power;
call symput("ps_grp_train",put(powerpercent,best12.-L));
run;
%put &ps_grp_train;

%powerc(valid_zm,&z_grp,&tar);
data _null_;
set power;
call symput("ps_grp_valid",put(powerpercent,best12.-L));
run;
%put &ps_grp_valid;

%let ps_grp_diff=%sysfunc(putn((&ps_grp_train-&ps_grp_valid)/&ps_grp_train,best12.-L));
%put &ps_grp_diff;






/*na grp:*/
/*h_grp_01 i max_dist na 0 i 1 train i valid*/
/*h_grp_tv max_dist i h_br max_dist_br na okresach*/

%licz_h(train_zm(keep=&tar &z_grp where=(&tar=0)),
train_zm(keep=&tar &z_grp where=(&tar=1)),&z_grp,wyn);
data _null_;
set wyn;
call symput("h_grp_train",put(h,best12.-L));
call symput("max_dist_grp_train",put(maxd,best12.-L));
run;
%put &h_grp_train &max_dist_grp_train;

%licz_h(valid_zm(keep=&tar &z_grp where=(&tar=0)),
valid_zm(keep=&tar &z_grp where=(&tar=1)),&z_grp,wyn);
data _null_;
set wyn;
call symput("h_grp_valid",put(h,best12.-L));
call symput("max_dist_grp_valid",put(maxd,best12.-L));
run;
%put &h_grp_valid &max_dist_grp_valid;

%let h_grp_diff=%sysfunc(putn((&h_grp_train-&h_grp_valid)/&h_grp_train,best12.-L));
%let max_dist_grp_diff=%sysfunc(putn((&max_dist_grp_train-&max_dist_grp_valid)
/&max_dist_grp_train,best12.-L));
%put &h_grp_diff &max_dist_grp_diff;

/*na okresach*/
%licz_h(train_zm(keep=&tar &z_grp),
valid_zm(keep=&tar &z_grp),&z_grp,wyn);
data _null_;
set wyn;
call symput("h_grp_tv",put(h,best12.-L));
call symput("max_dist_grp_tv",put(maxd,best12.-L));
run;
%put &h_grp_tv &max_dist_grp_tv;


%licz_h(train_zm(keep=&tar &z_grp where=(&tar=1)),
valid_zm(keep=&tar &z_grp where=(&tar=1)),&z_grp,wyn);
data _null_;
set wyn;
call symput("h_br_grp_tv",put(h,best12.-L));
call symput("max_br_dist_grp_tv",put(maxd,best12.-L));
run;
%put &h_br_grp_tv &max_br_dist_grp_tv;

data z;
&def_var level $ 10;
set z;
level="&level";
&name_ks_01_train       =&ks_01_train        ;
&name_h_01_train        =&h_01_train         ;
&name_max_dist_01_train =&max_dist_01_train  ;
&name_ks_01_valid       =&ks_01_valid        ;
&name_h_01_valid        =&h_01_valid         ;
&name_max_dist_01_valid =&max_dist_01_valid  ;
&name_c_01_diff         =&c_01_diff          ;
&name_c_01_train        =&C_01_Train         ;
&name_c_01_valid        =&C_01_Valid         ;

&name_ps_org_diff       =&ps_org_diff        ;
&name_ps_org_train      =&ps_org_Train       ;
&name_ps_org_valid      =&ps_org_Valid       ;

&name_ps_grp_diff       =&ps_grp_diff        ;
&name_ps_grp_train      =&ps_grp_Train       ;
&name_ps_grp_valid      =&ps_grp_Valid       ;


&name_ks_01_diff        =&ks_01_diff         ;
&name_h_01_diff         =&h_01_diff          ;
&name_max_dist_01_diff  =&max_dist_01_diff   ;
&name_pr_mfrequent_train     =&pr_mfrequent_train      ; 
&name_mfrequent_train        ="&mfrequent_train"         ; 
&name_pr_miss_train     =&pr_miss_train      ; 
&name_n_uni_train       =&n_uni_train        ;
&name_pr_mfrequent_valid     =&pr_mfrequent_valid      ; 
&name_mfrequent_valid        ="&mfrequent_valid"         ; 
&name_pr_miss_valid     =&pr_miss_valid      ; 
&name_n_uni_valid       =&n_uni_valid        ;
&name_h_tv              =&h_tv               ; 
&name_h_br_tv           =&h_br_tv            ; 
&name_ks_tv             =&ks_tv              ; 
&name_ks_br_tv          =&ks_br_tv           ;
&name_ar_diff           =&ar_diff            ;
&name_ar_train          =&ar_train           ;
&name_ar_valid          =&ar_valid           ;
&name_h_grp_train       =&h_grp_train        ; 
&name_max_dist_grp_train=&max_dist_grp_train ;
&name_h_grp_valid       =&h_grp_valid        ; 
&name_max_dist_grp_valid=&max_dist_grp_valid ;
&name_h_grp_diff        =&h_grp_diff         ; 
&name_max_dist_grp_diff =&max_dist_grp_diff  ;
&name_h_grp_tv          =&h_grp_tv           ; 
&name_max_dist_grp_tv   =&max_dist_grp_tv    ;
&name_h_br_grp_tv       =&h_br_grp_tv        ;
&name_max_br_dist_grp_tv=&max_br_dist_grp_tv ;
run;



proc append base=variables_stat data=z;
run;

%end;
%mend;

%validuj_zmienne(&import_data,&import_validate,&lib..variables_inset_fin,max_il=0);

proc sort data=variables_stat out=&lib..variables_stat;
by descending AR_Train ;
run;
/**/
/*data &lib..variables;*/
/*set variables_stat;*/
/*name='WOE_'||trim(variable);*/
/*keep name;*/
/*run;*/





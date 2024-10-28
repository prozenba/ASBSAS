/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/

goptions reset=all;
%let title=Example of quick and dirty model;
%let dir_codes=c:\karol\oferta_zajec\CS-AUT\software\ASB_SAS\monitoring\;

%let time_dim=Year;
%include "&dir_codes.makra.sas";
%include "&dir_codes.makra_am.sas";

libname inlib "&dir_codes.data\" compress=yes;

%let dir_index=&dir_codes;
%let dir=&dir_index.reports\;

%let state=EM;

proc sql noprint;
	select 
		upcase(name),
		quote(upcase(substr(name,5)))
	into 
		:v1-:v&sysmaxlong,
		:zmm separated by ','
	from dictionary.columns 
	where 
		libname='INLIB'
		and memname='ABT_SCORE' 
		and upcase(name) like 'PSC%'
	order by 1;
quit;
%let il_zm=&sqlobs;
%put &zmm;

proc sql noprint;
	select label
	into :o1-:o&sysmaxlong 
	from dictionary.columns 
	where 
		libname='INLIB'
		and memname='ABT_SCORE' and upcase(name) in (&zmm)
	order by upcase(name);
quit;

%put &il_zm***&v1***&o1;
%put &v2***&o2;


proc rank data=inlib.abt_score out=inlib.score groups=21;
	var SCORECARD_POINTS;
	ranks rank;
run;

/*proc format;*/
/*value bands*/
/*low - 384 ='231 - 384'*/
/*385 - 406 ='385 - 406'*/
/*407 - 423 ='407 - 423'*/
/*424 - 433 ='424 - 433'*/
/*434 - 441 ='434 - 441'*/
/*442 - 449 ='442 - 449'*/
/*450 - 453 ='450 - 453'*/
/*454 - 460 ='454 - 460'*/
/*461 - 466 ='461 - 466'*/
/*467 - 468 ='467 - 468'*/
/*469 - 470 ='469 - 470'*/
/*471 - 479 ='471 - 479'*/
/*480 - 480 ='480 - 480'*/
/*481 - 485 ='481 - 485'*/
/*486 - 491 ='486 - 491'*/
/*492 - 495 ='492 - 495'*/
/*496 - 496 ='496 - 496'*/
/*497 - 502 ='497 - 502'*/
/*503 - 512 ='503 - 512'*/
/*513 - 524 ='513 - 524'*/
/*;*/
/*run;*/



%macro ddd;
	data inlib.score;
		set inlib.score;
		group='A';
		score=SCORECARD_POINTS;
		band=rank;
/*		band=put(score,bands.);*/
		month=period;
		quarter=put(input(period,yymmn6.),yyq6.);
		year=put(input(period,yymmn6.),year4.);
		keep  
			score band group month default: quarter year cross_response
			 outstanding: 
			%do i=1 %to &il_zm;
				&&v&i
			%end;
		;
	run;
%mend ddd;
%ddd;

%let tar1=Default3;
%let tar2=Default6;
%let tar3=Default9;
%let tar4=Default12;
%let il_t=4;

%macro do_m;
	%do i=1 %to &il_t;
		&&tar&i %str( )
	%end;
%mend;
%let risk_m=%do_m;
%put &risk_m;

%let pop_set=inlib.score_temp;
%let gini_set=inlib.score_temp;
%let br_set=br_set_temp;

data br_set(compress=yes);
set inlib.score;
array r(&il_t) &risk_m;
do i=1 to &il_t;
if r(i) in (.i,.d) then r(i)=0;
end;
drop i;
run;


%macro licz(ttt,www);
data inlib.score_temp;
set inlib.score;
where &www;
run;

data br_set_temp;
set br_set;
where &www;
run;


	data raporty_spis;
		length 
			rodzaj $20 
			raport $200 
			link $300
		;
		delete;
	run;

	%all_distribution(&ttt,1,All accounts,all);
	%all_bad_rate(&ttt);
	%all_bad_rate_am(&ttt);
	%all_gini(&ttt);
	%spis_tresci(&ttt &title,&ttt);
%mend;

%licz(total,1);

proc sql;
	create table logo as
	select 
		count(*) as number,
		sum(outstanding) as total_bal
	from inlib.abt_score;
quit;


data logo;
	length subsum total name $ 200;
	format subsum total name $200.;
	set logo;
	total='Total';
run;

/*Links fro main product!*/
data logo;
	set logo;
	total=
		'<a href="'||"reports\"||compress(total)||"_index_main.html"||'">'||trim(total)||'</a>'
	;
run;


options linesize=256;
goptions  device=png;
ods listing close;
ods html 
	body='index.html' 
	path="&dir_index" (url=none)
	style=statistical;

title "&title";
proc tabulate data=logo;
	class total;
/*	class total subsum;*/

	var number total_bal;
	table 
		total='Up-level' all, 
/*		total='Up-level'*subsum='Sub-level' all, */

		number='Number of accounts'*sum=''*f=14. 
		total_bal='Total balance'*sum=''*f=commax20.2
	;
run;
ods html close;
ods listing;
goptions  device=win;

proc delete data=inlib.score;
run;
proc delete data=inlib.score_temp;
run;

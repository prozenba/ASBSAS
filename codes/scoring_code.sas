/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



%let kat_kodowanie=%sysfunc(pathname(&lib.));

/*na razie missing wrzucamy wed³ug porz¹dku 
zale¿nie od tego czy to jest model ryzyka czy response*/
data scorecard;
set models.Scorecard_Scorecard&the_best_model(
rename=(_variable_=variable _label_=condition));
otherwise_ind=(condition='otherwise');
run;

proc sort data=scorecard
out=p;
by variable otherwise_ind &order_tar br;
run;
proc sql;
create table &lib..good_variables_model
as select distinct _variable_
from models.Scorecard_Scorecard&the_best_model;
quit;
/*teraz prawdziwe skorowanie*/


filename kod "&kat_kodowanie.\scoring_code.sas";
data _null_;
length przed za $100 naz $300;
file kod;
if _n_=1 then do;
put 'data &zbior._score;';
put 'set &zbior;';
put "&score_points = 0;";
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
	naz="&score_points=sum(&score_points,"||trim(put(&score_points,best12.-L))||');';
	put naz;

	naz="PSC_"||compress(variable)||"="||trim(put(&score_points,best12.-L))||";";
	put naz;

	put "end;";
end;


if last.variable then do;
	put 'otherwise do;';
	naz="&score_points=sum(&score_points,"||trim(put(&score_points,best12.-L))||');';
	put naz;

	naz="PSC_"||compress(variable)||"="||trim(put(&score_points,best12.-L))||";";
	put naz;

    put 'end; end;';
end;

end;

put "run;";
run;


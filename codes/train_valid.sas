/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



/*proc sql noprint;*/
/*select 'inlib.'||memname into :sets separated by " " */
/*from dictionary.tables where*/
/*libname=upcase("INLIB") and (memname like "ABT_1%" */
/*or memname like "ABT_2%"); */
/*quit; */
%let sets=&in_abt;
%put &sets;

data abt.train abt.valid;
	set &sets;

	%Additional_variables;
	if &tar in (0,1,.i,.d) and ranuni(1)<&prop
	then do;
		if ranuni(1)<0.4 then output abt.valid;
		else output abt.train;
	end;
	if _error_ then _error_=0;
	keep 
	&tar aid cid outstanding period 
	default:
	app:  act:
/*	in normal model building uncomment below line*/
/*	agr: ags:*/
	;
run;



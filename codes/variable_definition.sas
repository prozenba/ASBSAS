/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/


%let zb=abt.train;

proc sql noprint;
	create table &lib..variable_definition as
	select 
			name as variable label='', 
			'int' as type, 
			'y' as ver
	from dictionary.columns 
	where
		libname=upcase("%scan(&zb,1,.)") 
		and memname=upcase("%scan(&zb,2,.)")
		and 
		(
		    upcase(name) like 'AGR%'
		 or upcase(name) like 'ACT%'
		 or upcase(name) like 'AGS%'
		 or upcase(name) like 'APP%')
		and  type='num'
		; 
quit; 

proc sql noprint;
	create table nom as
	select 
		name as variable, 
		'nom' as type, 
		'y' as ver
	from dictionary.columns 
	where
		libname=upcase("%scan(&zb,1,.)") 
		and memname=upcase("%scan(&zb,2,.)")
		and (upcase(name) like 'APP%' 
		  or upcase(name) like 'AGR%'
		  or upcase(name) like 'AGS%'
		  or upcase(name) like 'ACT%')
		and  type='char'; 

	select variable 
	into :zm separated by ' '
	from nom;
quit; 
%let il=&sqlobs;
%put &il***&zm;

%macro licz;
	data uni;
		length variable $32 il 8;
		delete;
	run;

	%do i=1 %to &il;
		%let z=%scan(&zm,&i,%str( ));
		proc sql;
			insert into uni
			select "&z" as variable, count(distinct &z) as il
			from &zb;
		quit;
	%end;
%mend;
%licz;

proc sql;
	insert into &lib..variable_definition 
	select 
		variable, 
		'nom' as type, 
		'y' as ver
	from uni 
/*	where il>=2*/
	where il<=200 and il>=2
	;
quit;

proc sort data=&lib..variable_definition;
by variable;
run;

/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/




libname t (&lib);

proc sql noprint;
	select 
		upcase(variable) 
		into :zm_bez_sklejenia separated by ' '
	from &data_variableset 
	where type in ('nom');
quit;
%let il_zm=&sqlobs;

%put ***&il_zm***&zm_bez_sklejenia;

/*minimalna liczba obs w liœciu*/
data _null_;
	set &zb(obs=1) nobs=il;
	min_il=int(&min_percent*il/100);
	call symput('min_il',trim(put(min_il,best12.-L)));
run;
%put &min_il;
/*%let min_il=2000;*/

data t.bining_nominal_wj;
	length variable $32 condition $300 grp 8;
	delete;
run;

%macro sklejaj;
	%do nr_zm=1 %to &il_zm;
		%let zm=%upcase(%scan(&zm_bez_sklejenia,&nr_zm,%str( )));
		%put &zm;

		proc means data=&zb nway noprint;
			var &tar;
			class &zm;
			output out=br(where=(_freq_ > &min_il)) mean()=br;
		run;

		data podz;
			set br end=e;
			cluster=_n_;
			if e then call symput('il_podz',put(_n_,best12.-L));
		run;

		%put &il_podz;

		%macro koduj;
			%put &zb***&zm;
			proc sql noprint;
				select upcase(type) 
				into :typ 
				from dictionary.columns 
				where
					upcase(libname)="%upcase(%scan(&zb,1,.))"
					and upcase(memname)="%upcase(%scan(&zb,2,.))"
					and upcase(name)="%upcase(&zm)";
			quit;
			%put &typ;

			%do i=1 %to &il_podz;
				%if &typ=CHAR %then %do;
					proc sql noprint;
					select "'"||trim(&zm)||"'" 
					into :cl&i separated by ',' 
					from podz
					where cluster=&i;
					quit;
				%end; %else %do;
					proc sql noprint;
						select &zm 
						into :cl&i separated by ',' 
						from podz
						where cluster=&i;
					quit;
				%end;
			%put &&cl&i;
			%end;

			data podz_nom;
				length variable $32 condition $300;
				%do i=1 %to &il_podz;
					condition="when (&&cl&i)";
					grp=&i;
					variable="&zm";
					output;
				%end;
			run;
		%mend koduj;
		%koduj;

		proc append base=t.bining_nominal_wj data=podz_nom;
		run;
	%end;
%mend sklejaj;

%sklejaj;

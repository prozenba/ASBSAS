/*******************************************************/
/*  (c) Karol Przanowski                               */
/*      kprzan@sgh.waw.pl                              */
/*  (c) Karol Przanowski - Advanced Analytical Support */
/*      kprzan@interia.pl                              */
/*******************************************************/



/*data adj.;*/
/*length grp 8 condition $300 variable $32;*/
/*variable="";*/
/*input;*/
/*condition=_infile_;*/
/*grp=_n_;*/
/*cards;*/
/*;*/
/*run;*/

data adj.ACT_AGE;
length grp 8 condition $300 variable $32;
variable="ACT_AGE";
input;
condition=_infile_;
grp=_n_;
cards;
not missing(ACT_AGE) and ACT_AGE <= 30
30 < ACT_AGE <= 45
45 < ACT_AGE <= 60
60 < ACT_AGE <= 75
75 < ACT_AGE
;
run;



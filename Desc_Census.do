/*--------------------------------------------------------------------------
Desc_Census.do
Name:		Desc_Census 
Goals:		summary statistics of the variables and Describe data
Authors:	Farhad shahryarpoor
Date:       1398.11.10

--------------------------------------------------------------------------*/
********generate dummy variable for highschool graduates****************
gen highschool = 0
replace highschool = 1 if ledu>=3

***************** run using both weighted and unweighted ************
egen	fr_lit  = sum(w1*lit) 	,by(msyear)
egen	fr_prim = sum(w1*(ledu>=2 & ledu!=.)) ,by(msyear)
egen	fr_high = sum(w1*(highschool)) 	,by(msyear)
egen	nm 		= sum(w1), by(msyear)
label var fr_lit "fraction of Literate"
label var fr_prim "fraction of primary"
label var fr_high "fraction of high school"

foreach x of varlist fr_lit fr_prim fr_high {
replace `x' = `x' / nm
	}
preserve 
duplicates drop fr_prim ,force
#d;	
tw 	(con fr_lit 	msyear		,${line1})  ////
(con fr_prim  	msyear 	 	,${line2})      ////
(con fr_high 	msyear 	 	,${line3})      ////
, ${grextra} xlabel(1942(5)1986)     ////
leg(lab(1 "Literate")lab(2 "Primary+") lab(3 "High school+")  r(1)) ///
xti(Birth year, si(small)) yti(Fraction, si(small));   ////
gr export "${outfolder2}Fraction$grext", ${groptions};   

********************************
keep lit highschool age sex size bplace urban Married bplace w1
tabulate Married , g(mar)
rename mar1 married
rename mar2 Widow
rename mar3 Divorce
rename mar4 Single
asdoc sum lit highschool age sex size urban married Widow Divorce Single if bplace!=1 [pw=w1], stat(N mean sd) replace dec(5)
asdoc sum lit highschool age sex size urban married Widow Divorce Single [pw=w1], stat(N mean sd) append dec(4)
asdoc sum lit highschool age sex size urban married Widow Divorce Single if b==1 [pw=w1], stat(N mean sd) append dec(3)

******************************

*
/*--------------------------------------------------------------------------
****************A: generate Diff-In-Diff table (average, D, and DD)*********************
--------------------------------------------------------------------------*/
macro def restrict 		"bornhere==1  [pw=w1]"
macro def regextra 		"cl(dcode) cformat(%4.3f)"

macro def depvar "highschool"
	
* Birth:  	Birth: [-6,-2] 	vs. C: [38-18] at 23 Sep 1980	
reg ${depvar} birXpr wabirth waprov  if ///
((sage>=18 & sage<=38) | (sage>=-6 & sage<=-2)) & bplace==1 [pw=w1], ${regextra}		
lincom 	waprov + _cons						,cformat(%4.3f)	
lincom 	wabirth + _cons						,cformat(%4.3f)	
lincom 	birXpr 	+ wabirth + waprov +  _cons	,cformat(%4.3f)	
	
lincom 	birXpr 	+ wabirth 	,cformat(%4.3f)
lincom 	birXpr 	+ waprov 	,cformat(%4.3f)
	
* Both: [-1,5] vs. C: [38-18] at 23 Sep 1980
reg ${depvar} doXpr wadoub waprov  if ///
((sage>=18 & sage<=38) | (sage>=-1 & sage<=5)) & bplace==1 [pw=w1], ${regextra}		
lincom 	waprov + _cons						,cformat(%4.3f)	
lincom 	wadoub + _cons						,cformat(%4.3f)	
lincom 	doXpr 	+ wadoub + waprov +  _cons	,cformat(%4.3f)	

lincom 	doXpr 	+ wadoub 	,cformat(%4.3f)
lincom 	doXpr 	+ waprov 	,cformat(%4.3f)
	
* School:  	Birth: [6,10] 	vs. C: [38-18] at 23 Sep 1980	
reg ${depvar} priXpr waprim waprov  if ///
((sage>=18 & sage<=38) | (sage>=6 & sage<=10)) & bplace==1 [pw=w1], ${regextra}
	
lincom 	priXpr + waprim + waprov + _cons	,cformat(%4.3f)	
lincom 	waprim 	+ _cons						,cformat(%4.3f)	
lincom 	waprov 	+ _cons						,cformat(%4.3f)	
	
lincom 	priXpr 	+ waprov	,cformat(%4.3f)
lincom 	priXpr 	+ waprim 	,cformat(%4.3f)
	
	
*Placebo	Tp: 1940-1962 vs. C:1930-1939
gen			placebo = (sage>=18 & sage<=29) if sage!=.
gen			plaXpr 	=  placebo  * waprov

reg 	${depvar} plaXpr placebo waprov if ///
(sage>=18 & sage<=38)  & bplace==1 [pw=w1], ${regextra}		
		
lincom 	waprov + _cons						,cformat(%4.3f)	
lincom 	placebo + _cons						,cformat(%4.3f)	
lincom 	plaXpr 	+ placebo + waprov +  _cons	,cformat(%4.3f)	
	
lincom 	plaXpr 	+ placebo 	,cformat(%4.3f)
lincom 	plaXpr 	+ waprov 	,cformat(%4.3f)
	

/*--------------------------------------------------------------------------
*****************D: % non-migrant in cohorts and war provinces****************
--------------------------------------------------------------------------*/
qui sum sage
macro def mins = r(min)
macro def maxs = r(max)
egen	tmp1 = sum(w1*(bplace==1)) if bplace!=. ,by(sage waprov)
egen	tmp2 = sum(w1) if bplace!=. ,by(sage waprov)
gen		fr_nmig = tmp1 / tmp2
drop tmp1 tmp2
	
#d ;
tw 	(con fr_nmig sage if waprov==1,${line1}) (con fr_nmig sage if waprov==0,${line2})
,leg(lab(1 "War") lab(2 "non-War")) 
xti(Age at 23 Sep 1980, margin(medsmall)) xscale(reverse)
yti(Fraction of non-migrant individuals,  margin(medsmall))
xlabel(${mins}(2)${maxs}, labsi(small) grid glc(gs14)glw(vthin) glp("_..")) 
ylabel(,labsi(small) glc(gs14)glw(vthin) glp("_..")) 
graphregion(color(white));
gr export "${outfolder}D2$grext", ${groptions};
#d cr

****************************Map of war and non-war areas****************************
***************************Create required files***************************
shp2dta using "${dtafiles}Map/", database(iran) coordinates(irancoord) genid(id)  /***this file isn't in my directory***/

***************************
use "${dtafiles}Map/iran.dta",clear
	
cap drop	waprov
gen 	 	waprov = 0
replace		waprov = 5 if prov==6	//Khuzestan
replace 	waprov = 4 if prov==16	//Ilam
replace		waprov = 3 if prov==12	//Kordestan
replace 	waprov = 2 if prov==5	//Kermanshah
replace 	waprov = 1 if prov==4	//W. Azerbaijan
	
spmap waprov using "${dtafiles}Map/irancoord.dta", id(id)  fcolor(white  gs10) legenda(off) 
gr export "${outfolder2}Map$grext", ${groptions}

	
	
	
	


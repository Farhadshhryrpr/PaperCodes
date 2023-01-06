/*--------------------------------------------------------------------------
Regs_Census.do 
Name:		Reg_Census
Goals:		Regressions
Authors:	Farhad shahryarpoor
Date:		1398.11.10		
Contains all DD regressions using census 2011
--------------------------------------------------------------------------*/
	
******************	Core variables	**********************
**********************************************************	
cap drop wabirth waprim wadoub
gen			wabirth 	= (sage>=-8 & sage<=-2) if sage!=.
label var	wabirth		"=1 if early years of life spent during war"
	
gen			waprim		= (sage>=6 & sage<=10)	if sage!=.
label var	waprim		"=1 if any of primary grades studied during war"
	
gen			wadoub  	= (sage>=-1 & sage<=5)	if sage!=.
	
gen			birXpr 	= wabirth * waprov
gen			priXpr 	= waprim  * waprov
gen			doXpr 	= wadoub  * waprov
	
gen			urbXpr	= urban * waprov
gen			sizXpr	= size * waprov
gen			sexXpr	= sex * waprov
qui		tab married,g(d_mar)
forvalues i=2(1)4{
	gen		dm`i'Xpr= d_mar`i' * waprov
	}
	
cap drop	tr*
qui sum	msyear
macro def	min_msyear = r(min)
gen			tr 	  = msyear - $min_msyear +1 
gen			trXwar = waprov * tr
gen			tr2 	  = tr^2
gen			tr2Xwar = waprov * tr2
gen			tr3 	  = tr^3
gen			tr3Xwar = waprov * tr3

* 
******************	Province specific linear trends	**********************
**************************************************************************	
cap drop	trXdpr*
qui tab prov 	,gen(dpr)
foreach x of varlist dpr2-dpr30 {
	qui gen		trX`x'= tr * `x'
	}

macro def regextra 		"cl(dcode) cformat(%4.3f)"

*
****************** A: Main Regressions, highschool	**********************
**************************************************************************	


macro def All		" "
macro def Allw		"[pw=w1]"
macro def Bplace 	"if bplace==1"
macro def Bplacew 	"if bplace==1  [pw=w1]"
	
foreach x in  "Allw" "Bplacew" {
	
macro def restrict = "${`x'}"
macro l restrict
	
reg 	highschool doXpr birXpr priXpr wadoub wabirth waprim waprov ${restrict}, ${regextra}
outreg2 using "${outfolder}main.xls",  excel dec(3) nocons keep(doXpr birXpr priXpr wadoub wabirth waprim waprov)

*** cohort & prov FE
reg 	highschool doXpr birXpr priXpr i.msyear i.prov ${restrict}, ${regextra}
outreg2
	
*** cohort & district FE
areg 	highschool doXpr birXpr priXpr i.msyear ${restrict}, ${regextra} a(dcode)
outreg2
	
*** Controls -- prefered specification
areg 	highschool doXpr birXpr priXpr i.msyear ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ${restrict}, ${regextra} a(dcode)
outreg2

*** Province specific linear trend
areg 	highschool doXpr birXpr priXpr i.msyear  ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ///
trXdpr* ${restrict}, ${regextra} a(dcode)
outreg2
}	
*
****************** B: Splitting the sample, highschool	**********************
******************************************************************************
*** Boys vs. Girls	
areg 	highschool doXpr birXpr priXpr i.msyear  ///
urban urbXpr size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X trXdpr* ///
if bplace==1 & sex==0 [pw=w1], ${regextra} a(dcode)
outreg2  using "${outfolder}Split.xls", excel dec(3) nocons keep(doXpr birXpr priXpr) adjr2

areg 	highschool doXpr birXpr priXpr i.msyear  ///
urban urbXpr size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X trXdpr* ///
if bplace==1 & sex==1 [pw=w1], ${regextra} a(dcode)
outreg2
		
*** Rural
reg 	highschool doXpr birXpr priXpr i.msyear i.prov ///
size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X trXdpr* ///
if bplace==1 & sex==0 & urban==0 [pw=w1], ${regextra}
outreg2

reg 	highschool doXpr birXpr priXpr i.msyear i.prov ///
size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X trXdpr* ///
if bplace==1 & sex==1 & urban==0 [pw=w1], ${regextra}
outreg2
	
*** Urban
reg 	highschool doXpr birXpr priXpr i.msyear i.prov ///
size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X trXdpr* ///
if bplace==1 & sex==0 & urban==1 [pw=w1], ${regextra}
outreg2

reg 	highschool doXpr birXpr priXpr i.msyear i.prov ///
size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X trXdpr* ///
if bplace==1 & sex==1 & urban==1 [pw=w1], ${regextra}
outreg2

*
****************** C: Full interactions	**********************
**************************************************************
quietly: tab msyear 	, g(dyr)			
cap drop waXyr*
forvalues i= 2(1)45 {
    quietly: gen waXyr`i' = dyr`i' * waprov
	}
qui sum sage
macro def mins = r(min)
macro def maxs = r(max)
*** For born here
areg highschool waXyr* dyr2-dyr45 ///
sex sexXpr size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ///
if bplace==1   [pw=w1], ${regextra} a(dcode)
mat def A = e(b)
mat def V = e(V)
mat def VV = J(45,3,0)	
	
forvalues j=2(1)45 {
    macro def i = `j'-1
	mat VV[`j',1]= A[1,$i]
	mat VV[`j',2]= sqrt(V[$i,$i])
	mat VV[`j',3]= ${maxs} - $i 
	}
	
mat VV[1,3] = ${maxs} 
cap drop coef* 
svmat VV , names(coef)
gen			coef_95  = coef1 + 1.96 * coef2
gen			coef_952 = coef1 - 1.96 * coef2
	
#d ;
tw 	(con coef1 coef3,${line1})(con coef_95 coef3,${lci95})(con coef_952 coef3,${lci95})
,leg(off) 
xti(Age at 23 Sep 1980, margin(medsmall)) xscale(reverse)
yti(,  margin(medsmall))
xlabel(${mins}(2)${maxs}, labsi(small) grid glc(gs14)glw(vthin) glp("_..")) 
ylabel(,labsi(small) glc(gs14)glw(vthin) glp("_..")) 
graphregion(color(white));
gr export "${outfolder}F1$grext", ${groptions};
#d cr

*** For born here divide by male and female
foreach gender in 0 1 {
	
areg highschool waXyr* dyr2-dyr45 ///
	size sizXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ///
	if bplace==1 & sex==`gender'  [pw=w1], ${regextra} a(dcode)
mat def A = e(b)
mat def V = e(V)

mat def VV = J(45,3,0)	
	
forvalues j=2(1)45 {
	macro def i = `j'-1
	mat VV[`j',1]= A[1,$i]
	mat VV[`j',2]= sqrt(V[$i,$i])
	mat VV[`j',3]= ${maxs} - $i
	}
	
mat VV[1,3] = ${maxs}
cap drop coef* 
svmat VV , names(coef)
gen			coef_95  = coef1 + 1.96 * coef2
gen			coef_952 = coef1 - 1.96 * coef2
	
#d ;
tw 	(con coef1 coef3,${line1})(con coef_95 coef3,${lci95})(con coef_952 coef3,${lci95})
,leg(off) 
xti(Age at 23 Sep 1980, margin(medsmall)) xscale(reverse)
yti(,  margin(medsmall))
xlabel(${mins}(2)${maxs}, labsi(small) grid glc(gs14)glw(vthin) glp("_..")) 
ylabel(-0.2(0.05)0.1,labsi(small) glc(gs14)glw(vthin) glp("_..")) 
graphregion(color(white));
gr export "${outfolder}F1_`gender'$grext", ${groptions};
#d cr
	}
*
	
	
/*--------------------------------------------------------------------------
D: Robustness checks
1. keep East and War prov
2. Remove Tehran
3. Remove provincial capital districts
4. Look only at provincial capitals
5. Separate regressions for War provinces
6. Remove Kordestan
7. Remove Khuzestan
8. Collapse to prov-msyear observations	
--------------------------------------------------------------------------*/
macro def exTehran 	"prov!=23"
macro def exCentres "caprov==0"
macro def inCentres "caprov==1"
macro def Kordestan "(prov==12 | waprov==0)"
macro def Khuzestan "(prov==6 | waprov==0)"
macro def WAzar 	"(prov==4 | waprov==0)"
macro def Kermanshah "(prov==5 | waprov==0)"
macro def Illam 	"(prov==16 | waprov==0)"
macro def exKordestan "prov!=12"
macro def exKhuzestan "prov!=6"
	
* Benchmark
areg 	highschool doXpr birXpr priXpr i.msyear  ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2Xpr dm3Xpr dm4Xpr ///
trXdpr* if bplace==1 [pw=w1], ${regextra} a(dcode)
outreg2 using "${outfolder}Robust1.xls", replace excel dec(3) nocons keep(doXpr birXpr priXpr) adjr2
	
* Now robustness checks
foreach x in "exTehran" "exCentres" "inCentres" "Kordestan" "Khuzestan" "WAzar" "Kermanshah" "Illam" ///
        "exKordestan" "exKhuzestan"  {
	macro l `x'	
	areg 	highschool doXpr birXpr priXpr i.msyear  ///
			urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2Xpr dm3Xpr dm4Xpr ///
			trXdpr* if bplace==1 & $`x' [pw=w1], ${regextra} a(dcode)
	outreg2
	}
*
	
* Run on collapsed data
preserve
	
collapse highschool waprov doXpr birXpr priXpr trXdpr* d_mar* urban size sex	///
(count) n=highschool if bplace==1 [pw=w1],by(msyear prov)
replace n = int(n)
drop if msyear==. | prov==.
	
gen			urbXpr	= urban * waprov
gen			sizXpr	= size * waprov
gen			sexXpr	= sex * waprov
forvalues i=2(1)4{
	gen		dm`i'Xpr= d_mar`i' * waprov
	}

reg highschool doXpr birXpr priXpr i.msyear i.prov ///
	, rob cformat(%4.3f)
outreg2 using "${outfolder}Robust2_ostad.xls", excel dec(3) nocons keep(doXpr birXpr priXpr) adjr2

	
reg 	highschool doXpr birXpr priXpr i.msyear i.prov ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2Xpr dm3Xpr dm4Xpr ///
, rob cformat(%4.3f) 
outreg2
	
reg 	highschool doXpr birXpr priXpr i.msyear i.prov ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2Xpr dm3Xpr dm4Xpr ///
trXdpr* , rob cformat(%4.3f) 
outreg2
	
restore

*
****************** Use provincial stats on educ inputs	**********************
******************************************************************************
areg 	highschool doXpr birXpr priXpr i.msyear  ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ///
if bplace==1 & lstu!=. [pw=w1], ${regextra} a(dcode)
outreg2 using "${outfolder}Robust3.xls", excel dec(3) nocons keep(doXpr birXpr priXpr lstu lsch) adjr2
		
areg 	highschool doXpr birXpr priXpr lsch lstu i.msyear ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ///
if bplace==1 [pw=w1], ${regextra} a(dcode)
outreg2
		
areg 	highschool doXpr birXpr priXpr lsch lstu i.msyear ///
urban urbXpr size sizXpr sex sexXpr d_mar2 d_mar3 d_mar4 dm2X dm3X dm4X ///
trXdpr* if bplace==1 [pw=w1], ${regextra} a(dcode)
outreg2

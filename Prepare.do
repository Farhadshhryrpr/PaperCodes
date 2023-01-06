/******************************************************************************* 
Name:		Prepare
Goals:		data cleaning
Authors:	Farhad shahryarpoor
Date:		1398.11.10
********************************************************************************/
**********prepare birth month **************
destring Col05,replace force
rename Col05 bmonth
replace bmonth = . if bmonth>12 | bmonth <1
label var bmonth "Birth Month (Persian Cal)"

************** prepare birth year************
destring Col06, replace force
rename Col06 byear
label var byear "Birth Year (Persian Cal)"
*********************************************
**********************drop age<25 & age>70 (age at 1 mehr 1390)*********************
drop if (byear==65 & bmonth>=7) | (byear>=66)
drop if (byear==20 & bmonth<=6) | byear<=19
drop if age<25 | age>70
*********************************************
***********Prepare birth year****************
gen byear1 = 1400 + byear if Col05_Gham==1 & age=<32
replace byear1 = 1300 + byear if Col05_Gham==1 & age>32
replace byear1 = 1400 + byear if Col05_Gham==1 & age==32
*********************************************
destring age, replace force
gen byear1 = 1400 + byear if Col05_Gham==1 & age<32
replace byear1 = 1300 + byear if Col05_Gham==1 & age>32
replace byear1 = byear1 - 42
replace byear1 = 1300 + byear if Col05_Gham==0 & age<90
replace byear1 = 1200 + byear if Col05_Gham==0 & age>90
replace byear1 = 1300 if byear==0
replace byear1 = 1200 + byear if byear==99 & Col05_Gham==0
rename byear1 perbyear
label var perbyear "Persian birth year"
*********************Prepare GREG and persian CAL*********************
gen mbyear = perbyear + 621
gen bdate = monthly(string(perbyear)+"-"+string(bmonth),"YM")
gen mbdate = bdate + tm(2011m3) - tm(1390m12)
label var 	bdate "Birth date (Persian Cal)"
label var 	mbdate "Birth date (Greg Cal)"

*********************Create dummy for war province *********************
gen waprov = (Ostan ==4 | Ostan ==5 | Ostan ==6 | Ostan==12 | Ostan == 16)
label var 	waprov "=1 if lives in war province"
*********************Create old province*********************
gen oprov = Ostan
replace oprov = 3 if Ostan==24
replace oprov = 2 if Ostan==27
replace oprov = 9 if Ostan==28 | Ostan==29
replace oprov = 0 if Ostan==23
replace oprov = 0 if Ostan==25
replace oprov = 1 if Ostan==19
replace oprov = 1 if Ostan==26
replace oprov = 0 if Ostan==30
label var oprov "Old province compatibility"

*********************Create  Adj birth year (Persian Cal) & Adj birth year (Greg Cal) & Age at 23 Sep 1980/1 Mehr 1359*********************
gen			syear		= yofd(dofm(bdate - 6)) + 1
gen			msyear		= syear + 621
label var	syear	"Adj birth year (Persian Cal)"
label var	msyear	"Adj birth year (Greg Cal)"

gen			sage = tm(1980m9) - msyear
label var	sage	"Age at 23 Sep 1980/1 Mehr 1359"

*********************prepare Variable and assign label to them*********************
destring Col04, replace
recode Col04 (2=0)
rename Col04 sex
label var sex "=1 if one is MAN"
label define gender1 1"MALE" 0"FEMALE"
label value sex gender1

rename col19 lit
label define lit1 0"Illiterate" 1"Literate"
destring lit, replace force
label value lit lit1
label var lit "=1 if one is Literate"


rename col39 bplace
label define bplace1 1"here" 2"other town" 3"other village" 4"abroad"
destring bplace, replace force
label value bplace bplace1
label var bplace  "Birth place"


rename col30 Married
label define Mar 1"Married" 2"Widow" 3"Divorce" 4"Single"
destring Married, replace force
label value Married Mar
label var Married "Marriage status"

rename col18 student
destring student, replace force
recode student (2=1) (3=0)
label define stu 1"Student" 0"Non-student"
label value student stu
label var student "=1 if the one is student in 1390/2011"


gen dcode = string(Ostan) + Shahrestan

rename Col03 relation
label var relation "relation base on head"


rename col20_Code educode
label var educode "Education code "

label define RU1 0"Rural" 1"Urban"
destring RU, replace
label value RU RU1
rename RU urban
label var urban "=1 if urban"


label var Weight  "Individual Weight in sample"
rename Weight w1

label var age  "age in 1390/2011"

rename Ostan prov
label var prov "Province"
********************** dummy for whether district contain the provincal capital*********************
g caprov = 0
replace caprov = 1 if dcode == "2301" | dcode == "303"  |dcode == "105" 	    ///
				| dcode == "707" 	  |dcode == "1204"  |dcode == "401" 		///
				| dcode == "1503"     | dcode == "1002" | dcode =="1304" 		///
				| dcode == "2401" 	  | dcode == "603" 	| dcode == "1601" 		///	
				| dcode == "001" 	  | dcode == "2603" | dcode == "808" 		///
				| dcode == "1105"	  | dcode == "916"  | dcode == "2901" 	    ///
				| dcode == "2802" 	  | dcode == "2501" | dcode == "2202"     	///
				| dcode == "207" 	  | dcode == "2705" | dcode == "1801"   	///
				| dcode == "502"      | dcode == "2002" | dcode == "2105" 		///
				| dcode == "1701"     | dcode == "1904" |dcode == "1402"        ///
				| dcode == "3001"
label var caprov "=1 if district of province capital"
	

*********************Merge school & Student and prepare essential variable*********************
merge m:m oprov syear using "${dtafiles}educationformerge.dta", 
drop if _merge == 2
drop _merge year 
cap drop lsch lstu
gen		lsch = ln(schools)
gen		lstu = ln(totalstudents)
label var lsch "Ln(primary schools) in province"
label var lstu "Ln(primary students) in province"

******************************************
save "${dtafiles}First.dta"
*********************Family size*********************
gen size = 1
collapse (sum) size, by(KhanevarID)
save "${dtafiles}familysize.dta"
******************************************
*********************merge family size with base data*********************
use "${dtafiles}First.dta", clear
merge m:m KhanevarID using "${dtafiles}familysize.dta"
label var size "family size"

*********************keep Interest variable *********************
keep KhanevarID size prov Shahrestan urban relation sex bmonth byear student lit educode ledu married bplace w1 age perbyear mbyear bdate mbdate waprov caprov oprov syear msyear sage schools totalstudents stPschool stPclass lsch lstu dcode

order KhanevarID prov Shahrestan dcode urban relation size w1 sex bmonth byear student lit educode ledu married bplace age perbyear mbyear bdate mbdate syear msyear sage waprov caprov oprov schools totalstudents stPschool stPclass lsch lstu
******************************************	
save "${dtafiles}Final.dta", replace
******************************************



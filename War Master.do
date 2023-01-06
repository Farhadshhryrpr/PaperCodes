/*--------------------------------------------------------------------------
* War master.do
* Start here; all war analysis originate from this file
* War dates: 22 Sep 1980 -- 20 Aug 1988
* master do file for Econometrics I Stata Assignments project
* Authors:	Farhad shahryarpoor 
* Date:		1398.11.10
--------------------------------------------------------------------------*/
macro 	def		root		"C:\Users\HP\Desktop\Project\CNSS90\"
cd 		"${root}"
	
macro 	def 	dofiles		"${root}Code\"
macro 	def 	dtafiles	"${root}Data\"
macro 	def 	outfolder 	"${root}Results\"
cap 	mkdir 				${outfolder}


do "${dofiles}Macros.do"
	
	
/*--------------------------------------------------------------------------
A: Cleaning Census
--------------------------------------------------------------------------*/


* Open raw data and clean
use  "${dtafiles}Census90.dta", clear      /*** It is not in my directory ***/
do "${dofiles}prepare.do"
		
	
/*--------------------------------------------------------------------------
B: Descriptive
--------------------------------------------------------------------------*/
use "${dtafiles}Final.dta",clear
do "${dofiles}Desc_Census.do"
	
/*--------------------------------------------------------------------------
C: Analysis
--------------------------------------------------------------------------*/
use "${dtafiles}Final.dta",clear
do "${dofiles}Regs_Census.do"
		

	

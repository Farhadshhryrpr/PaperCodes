/******************************************************************************* 
* Name:		Macros
* Goals:	Define Macros
* Authors:	Farhad shahryarpoor
* Date:		1398.11.10
********************************************************************************/

macro 	def 	groptions 	"width(1800) height(1200) replace"
macro 	def		grext		".png"	
	
macro def	line1	"sort m(none) 	lp(solid) 	lc(gs0) mc(gs0)"
macro def	line2	"sort m(O) lp(solid) 	lc(gs8) mc(gs8)"
macro def 	line3	"sort m(Oh)	lp(longdash) lc(gs0) mc(gs0)"
macro def 	line4	"sort m(Dh) lp(longdash) lc(gs8) mc(gs8)"
macro def lci95 "sort m(none none) lp("-" "-") lc(gs7 gs7) lw(thin thin)"
macro def 	vline	"lp(solid)	lc(gs8)"

#d;
macro def 	grextra "
xlabel(,angle(0) labsi(small) grid glc(gs14)glw(vthin) glp("_..")) 
ylabel(,labsi(small) glc(gs14)glw(vthin) glp("_.."))
graphregion(color(white))";
#d cr

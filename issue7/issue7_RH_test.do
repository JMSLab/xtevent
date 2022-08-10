*===============================================================================       
* Xtevent issue 7          
* Author: Ray Huang 
*===============================================================================

********************************************************************************
**************************** PLOT 2 XTEVENT COMMANDS ***************************
********************************************************************************

clear all
if "`c(username)'" == "rayhuang" {
	cd "/Users/rayhuang/Documents/JMSLab/xtevent-git/test"
	}
set more off
use example31.dta, clear

* Create fake data for second outcome variable
set seed 42
set obs 20000
g yy = rnormal(1.8, 3)
sum yy

xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5) 
estimates store ycoefs
xtevent yy eta , panelvar(i) timevar(t) policyvar(z) window(5) 
estimates store yycoefs

* Get coefficients from xtevent when y is the outcome var
estimates restore ycoefs
mat ycoefs_mat = e(delta)'
svmat ycoefs_mat
rename ycoefs_mat1 ycoefs_var

* Get coefficients from xtevent when yy is the outcome var
estimates restore yycoefs
mat yycoefs_mat = e(delta)'
svmat yycoefs_mat
rename yycoefs_mat1 yycoefs_var

* Get x-axis values
mat X1 = (-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6)'
svmat X1
* Offset second x-axis slightly
mat X2 = (-6.2,-5.2,-4.2,-3.2,-2.2,-1.2,-0.2,0.8,1.8,2.8,3.8,4.8,5.8)'
svmat X2

tw (scatter ycoefs_var X1)  ///
	(scatter yycoefs_var X2)

	
********************************************************************************
****************************** DiD Imputation Test *****************************
********************************************************************************

xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5) 
event_plot e(delta)#e(V), stub_lag(_k_eq_m#) stub_lead(_k_eq_p#)

	

event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-14(1)5) ///
	title("Sun and Abraham (2020)")) stub_lag(L#event) stub_lead(F#event) together
********************************************************************************
*********************************** OFFSET *************************************
********************************************************************************
* First, set a max for how many graphs can be combined
* By default, if offset is not speicfied the graphs will be offset. There will 
*	no offset if offest(0) is specified.
* Create syntax option = offset
* eq_n = number of commands we want to plot

if ("`offset'"=="") {
	local offset 0
	if (`eq_n'>1) forvalues eq=1/`eq_n' {
		local offset `offset' `=0.2*`eq'/`eq_n''
	}
}

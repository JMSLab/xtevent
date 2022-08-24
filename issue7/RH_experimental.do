*===============================================================================       
* Xtevent issue 7          
* Author: Ray Huang 
*===============================================================================

********************************************************************************
**************************** PLOT 2 XTEVENT COMMANDS ***************************
********************************************************************************
set scheme sj
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
**************************** xteventplot pseudocode ****************************
********************************************************************************

program define xteventplot
	syntax [anything(name=eqlist)], [options]
		- add offset options for custom offsets
	
	local eq_n : word count `eqlist'

	capture errors 
	- add additional errors here if necessary, e.g. check if num models > limit
	- or if options not allowed with multiple models are not specified
	
	display information about option selection
	- e.g. if "`ci'"=="noci" di as txt _n...
	
	prepare offset values
	
	forvalue in 1/`eq_n'{
		get stored estimates e.g. e(df), e(delta), e(Vdelta), etc
		
		proceed as we did prior:
			- e.g. calculate CIs
			
		if `eq_n' > 1{
			offset
		}
		
		* Note: certain options will not work w/ multiple plots (like p-values)
		* Q: what other options are we going to reserve for single model plots?
			
		store info for plotting in a local
		
	}
	
if eq_n>1 { 
	overlay plots w/ multiple models
}
else{
	overlay plots the old way
}

end 


********************************************************************************
**************************** xteventplot testing *******************************
********************************************************************************
set scheme sj
clear all
if "`c(username)'" == "rayhuang" {
	cd "/Users/rayhuang/Documents/JMSLab/xtevent-git/test"
	}
set more off
use example31.dta, clear

set seed 42
set obs 20000
g y2 = rnormal(1.8, 3)

xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5) 
estimates store model1
xtevent y2 eta , panelvar(i) timevar(t) policyvar(z) window(5) 
estimates store model2


xteventplot model1 model2










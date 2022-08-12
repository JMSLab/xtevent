*===============================================================================       
* Xtevent issue 35        
* Author: Ray Huang 
* Estimate a basic event study using EventStudyIntereact package and xtevent example
* https://github.com/lsun20/EventStudyInteracts
*===============================================================================

*net install github, from("https://haghish.github.io/github/")
* Dependencies: 
*ssc install avar
*ssc install reghdfe
*ssc install ftools

********************************************************************************
********************************** Load data ***********************************
********************************************************************************

clear all
set more off
if "`c(username)'" == "rayhuang" {
	cd "/Users/rayhuang/Documents/JMSLab/xtevent-git/test"
	}
use example31.dta, clear

label var y "depvar"
label var i "idcode"
label var t "time"
label var eta "indepvar"
label var z "policyvar"

drop zeta
drop u
drop e
drop alpha
drop x

********************************************************************************
******************************* EventStudyInteract *****************************
********************************************************************************

*  Gen the cohort categorical variable based on when the individual is first treated
gen treatment_year = t if z == 1
by i: egen first_treatment = min(treatment_year)
drop treatment_year

* Generate relative time categorical variable
g rt = t - first_treatment

* Generate control
gen never_treated = (first_treatment == .)

* Generate relative indicators, and leave out the distant leads
forvalues k = 6(-1)2{
	gen g_`k' = rt == -`k'
}

forvalues k = 0/6{
	gen g`k' = rt == `k'
}


* Use IW estimator to estimate dynamic effect on log wage w/ each relative time:
eventstudyinteract y g_* g0-g6 ,cohort(first_treatment) control_cohort(never_treated) absorb(i.i i.t) vce(cluster i)

* Compare to
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5)




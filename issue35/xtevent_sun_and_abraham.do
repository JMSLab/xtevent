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
label var i "individual"
label var t "time"
label var eta "indepvar"
label var z "policyvar"

********************************************************************************
******************************* EventStudyInteract *****************************
********************************************************************************

* Generate indicator for the never-treated to use as control group
by i: egen avg_z = mean(z)
gen never_treated = 0
replace never_treated = 1 if avg_z == 0

/*
Time and unit FE

*/
eventstudyinteract y... ,cohort() control_cohort(never_treated) absorb(i, t) vce(cluster)

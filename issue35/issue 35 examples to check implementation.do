************* issue 35: examples to check implementation *****************

*install branch version 
*net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/issue35_implement_estimation_robust_treatment_heterogeneity") replace

*directory for the large version of example31 
global input "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\35"

*load example dataset
use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
xtset i t

*generate variable of treatment time
gen timet=t if z==1
by i: egen time_of_treat=min(timet)
drop timet
*generate never treated indicator 
gen never_treat=time_of_treat==.

*default 
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe  

************ verify equivalence between xtevent and EventStudyInteract ********

*Sun-Abraham within xtevent (cohort + control_cohort + reghdfe)
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 

*EventStudyInteract
cap drop g*
xtevent y, panelvar(i) t(t) policyvar(z) window(3) impute(stag) savek(g, noestimate)
eventstudyinteract y g_eq_m4-g_eq_m2 g_eq_p0-g_eq_p4, cohort(time_of_treat) ///
            control_cohort(never_treat) covariates(x)  ///
			absorb(i t) vce(cluster i)
			
**************** test postestimation options on xtevent  ********************

*diffavg 
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) diffavg

*trend adjustment by GMM
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) trend(-2,method(gmm) saveoverlay)
xteventplot, overlay(trend)

***check the returned matrices
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
ereturn list
*cohort-relative-time effects
mat li e(b_interact)
*variance of cohort-relative time effects
mat li e(V_interact)
*cohort shares
mat li e(ff_w)
*variance of cohort shares
mat li e(Sigma_ff)

*option to save interactions
cap drop aa_*
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) savek(aa, saveint)
describe aa_*

*save them again: expect an error
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) savek(aa, saveint)
drop aa_*

*specify saveint without cohort and control_cohort (expect an error)
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe savek(aa, saveint)

*xteventplot 
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) trend(-2,method(gmm) saveoverlay)
xteventplot 
graph export adj_trend.png, replace 
xteventplot, overlay(trend)
graph export overlay_trend.png, replace 

xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat)
xteventplot, smpath(line)
graph export smpath.png, replace 

*xteventtest
xteventtest, coefs(1 2)

**************************** compare xtevent base vs xtevent' SA with a large dataset that doesn't have heterogenous treatment effects ***********

*load example dataset
use "$input/lib/test/example31_large.dta", clear
xtset i t

*add random id to create random subsamples
gen ran=runiform()
by i: egen ran2=min(ran)
sort ran2 i t

preserve
bysort i t: keep if _n==1
sort ran2 i t
gen rid=_n
keep i t rid
save "$input/lib/test/randomid.dta", replace 
restore 
merge m:1 i t using "$input/lib/test/randomid.dta", nogen
drop ran ran2
keep if rid<=50000 //keep up to 50,000 to speed computations


*generate variable of treatment time
gen timet=t if z==1
bysort i: egen time_of_treat=min(timet)
drop timet
*generate never treated indicator 
gen never_treat=time_of_treat==.

*compare with various sample sizes
foreach i in 1000 10000 50000{
******* comparing with a sample size of `i'
*default   
xtevent y x if rid<=`i', panelvar(i) t(t) policyvar(z) window(3) impute(stag)  
estimates store base_`i'  

*Sun-Abraham within xtevent (cohort + control_cohort)
xtevent y x if rid<=`i', panelvar(i) t(t) policyvar(z) window(3) impute(stag) cohort(time_of_treat) control_cohort(never_treat) 
estimates store sa_`i' 

coefplot  base_`i' sa_`i', vertical keep(_k*) xlabel(, angle(vertical))
graph export _`i'.png, replace 
}

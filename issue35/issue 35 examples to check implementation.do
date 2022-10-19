************* issue 35: examples to check implementation *****************

*install branch version 
*net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/issue35_implement_estimation_robust_treatment_heterogeneity") replace

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

*Sun and Abraham within xtevent (cohort + control_cohort + reghdfe)
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 

*EventStudyInteract
cap drop g*
xtevent y, panelvar(i) t(t) policyvar(z) window(3) impute(stag) savek(g, noestimate)
eventstudyinteract y g_eq_m4-g_eq_m2 g_eq_p0-g_eq_p4, cohort(time_of_treat) ///
            control_cohort(never_treat) covariates(x)  ///
			absorb(i t) vce(cluster i)
			
****** test postestimation options on xtevent 

*diffavg 
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) diffavg

*trend adjustment by GMM
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) trend(-2,method(gmm) saveoverlay)

***check the returned matrices
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
ereturn list
*cohort-relative time effects
mat li e(b_interact)
*variance of cohort-relative time effects
mat li e(V_interact)
*cohort shares
mat li e(ff_w)
*variance of cohort shares
mat li e(Sigma_ff)

*option to save interactions
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) saveint(aa)
describe aa_*

*save them again: expect an error
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) saveint(aa)
drop aa_*

*xteventplot 
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) trend(-2,method(gmm) saveoverlay)
xteventplot 
xteventplot, overlay(trend)
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat)
xteventplot, smpath(line)


*xteventtest
xteventtest, coefs(1 2)


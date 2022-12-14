

********** compare imputation rules*********************+
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

*Sun-Abraham (no imputation)
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store no_imputation

*Sun-Abraham (impute(nuchange))
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) impute(nuchange) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store nuchange

*Sun-Abraham (impute(stg))
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store stag

*Sun-Abraham (impute(instg))
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) impute(instag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store instag 

esttab no_imputation nuchange stag instag, keep(_k*) se mtitles(no_imputation nuchange stag instag)

**compute standarized time variable 
bys i: egen tt=min(t) if z==1
by i: egen tt2=min(tt)
by i: gen tsd=t-tt2

*add missing values after treatment time, between treatment indicators
replace z=. if i<200 & tsd==4

*repeat estimation table
*Sun-Abraham (no imputation)
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store no_imputation

*Sun-Abraham (impute(nuchange))
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) impute(nuchange) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store nuchange

*Sun-Abraham (impute(stg))
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) impute(stag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store stag

*Sun-Abraham (impute(instg))
xtevent y eta, panelvar(i) t(t) policyvar(z) window(3) impute(instag) vce(cluster i) reghdfe cohort(time_of_treat) control_cohort(never_treat) 
est store instag 

esttab no_imputation nuchange stag instag, keep(_k*) se mtitles(no_imputation nuchange stag instag)


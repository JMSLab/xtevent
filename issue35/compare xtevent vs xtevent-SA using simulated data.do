************ xtevent-SA using simulated data
*compare xtevent vs xtevent-SA using a dataset with treatment heterogeneity

*code for the simulated data is from https://github.com/borusyak/did_imputation/blob/main/five_estimators_example.do

*where to save the plot 
global output "C:/Users/tino_/Dropbox/PC/Documents/xtevent/issues/35"

// Generate a complete panel of 300 units observed in 15 periods
clear all
timer clear
set seed 10
global T = 15
global I = 300

set obs `=$I*$T'
gen i = int((_n-1)/$T )+1 					// unit id
gen t = mod((_n-1),$T )+1					// calendar period
tsset i t

// Randomly generate treatment rollout years uniformly across Ei=10..16 (note that periods t>=16 would not be useful since all units are treated by then)
gen Ei = ceil(runiform()*7)+$T -6 if t==1
bys i (t): replace Ei = Ei[1]
gen K = t-Ei 								// "relative time", i.e. the number periods since treated (could be missing if never-treated)
gen D = K>=0 & Ei!=. 						// treatment indicator

// Generate the outcome with parallel trends and heterogeneous treatment effects
gen tau = cond(D==1, (t-12.5), 0) 			// heterogeneous treatment effects (in this case vary over calendar periods)
gen eps = rnormal()							// error term
gen Y = i + 3*t + tau*D + eps 				// the outcome (FEs play no role since all methods control for them)
//save five_estimators_data, replace

*i: panelvar
*t: timevar
*D: policyvar
*Ei: cohort variable
*K: relative time variable

* control cohort variable:
tab Ei //cohort variable
sum Ei
gen lastcohort = Ei==r(max) // dummy for the latest- or never-treated cohort

*xtevent-ols
cap drop _k*
xtevent Y, panelvar(i) timevar(t) policyvar(D) window(4) impute(stag) vce(cluster i) reghdfe
estimates store xtevent
xteventplot

*xtevent-SA
xtevent Y, panelvar(i) timevar(t) policyvar(D) window(4) impute(stag) vce(cluster i) reghdfe cohort(Ei) control_cohort(lastcohort)
estimates store xtevent_SA
xteventplot

*EventStudyInteract
cap drop _k*
xtevent Y, panelvar(i) timevar(t) policyvar(D) window(4) impute(stag) savek(_k, noestimate)
eventstudyinteract Y _k_eq_m5-_k_eq_m2 _k_eq_p0-_k_eq_p5, vce(cluster i) absorb(i t) cohort(Ei) control_cohort(lastcohort)

*compare 
coefplot xtevent xtevent_SA , keep(_k_eq_m5 _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 _k_eq_p5) vertical xlabel(, angle(vertical))
graph export "$output/xtevent_vs_xteventSA.png", replace




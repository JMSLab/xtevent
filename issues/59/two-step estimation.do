********************** two-step estimation (Hansen, 2007) ************

* directory
*global dir "T:\pretrendstest"
global dir "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\5_august"

*load repeated_cross_sectional dataset
use "$dir\large_repeated_cross_sectional_example31.dta", clear

* I'll keep the balanced subsample for now
tab state
*drop if inlist(state,2,11,34,45,49,54)
drop if inlist(state,24,25,33)


*gen a random id. This will be used to run the models for different sample sizes
set seed 1
cap drop rid 
gen rid_=runiform()
sort rid
gen rid=_n
drop rid_
sort state t i  


*gen differenced policyvar
preserve 
keep state t z 
by state t: keep if _n==1
*collapse (min) z, by(state t)
xtset state t
by state (t): gen zd=z-l1.z

*generate evet-time dummies 
by state (t): gen _k_eq_m3=F3.zd
by state (t): gen _k_eq_m2=F2.zd
by state (t): gen _k_eq_m1=F1.zd
by state (t): gen _k_eq_p0=L0.zd
by state (t): gen _k_eq_p1=L1.zd
by state (t): gen _k_eq_p2=L2.zd
by state (t): gen _k_eq_p3=L3.zd

*generate endpoints 
by state (t): gen double _k_eq_m4 = (1-F3.z)
order _k_eq_m4, before(_k_eq_m3)
by state (t): gen double _k_eq_p4= l4.z
order _k_eq_p4, after(_k_eq_p3)

drop z
tempfile cal
save `cal'

restore
*merge back to the individual level dataset 
qui merge m:1 state t using `cal', nogen
sort state t i
order zd _k_*, after(z)


*********** compare: directly estimating equation 3 vs two-step procedure 

local values "100000 500000 1000000 2000000"
foreach i of local values {
di "subsample: `i'"
cap drop subsample 
gen subsample=1 if rid<=`i'

*estimate a baseline model 
*estimate equation 3) by OLS
reg y u _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t i.state if subsample==1

*gen clusterid
*cap drop double_cluster
*egen double_cluster=group(state t)
*reg y u _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t i.state, cluster(double_cluster)

estimates store baseline 
cap drop samp 
gen samp = e(sample)

*average number of observations per cell
preserve 
keep if samp 
cap drop nobs 
by state t: gen nobs=_N 
mean nobs 
restore 

*two-step estimation 
*step 1
* reghdfe y u if samp, absorb(c_hat=i.t#i.state) resid keepsingletons nocons
reg y u i.state#i.t 
cap drop c_hat 
predict c_hat
replace c_hat = c_hat - _b[u]*u - _b[_cons]

*step 2 
preserve
keep if samp
by state t: keep if _n==1
xtset state t
* xtdescribe
* tab state
reg c_hat _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t i.state
est store reg
xtgls c_hat _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t i.state, panels(h)
est store xtglsh
xtgls c_hat _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t i.state, panels(iid)
est store xtglsiid
xtreg c_hat _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t, re
est store re
restore

esttab baseline reg xtglsh xtglsiid re, keep(_k*) se nodepvars  
*esttab baseline reg xtglsh xtglsiid re using "$dir\subsample_`i'.csv", keep(_k*) se nodepvars replace 

}
.
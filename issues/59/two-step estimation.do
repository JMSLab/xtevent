********************** two-step estimation (Hansen, 2007) ************

* directory
global dir "T:\pretrendstest"

*load repeated_cross_sectional dataset
use "$dir\repeated_cross_sectional_example31.dta", clear

* I'll keep the balanced subsample for now
* tab state
drop if inlist(state,2,11,34,45,49,54)

*gen differenced policyvar
preserve 
collapse (min) z, by(state t)
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

*estimate a baseline model 
reg y u _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 i.t i.state
estimates store baseline 

gen samp = e(sample)

*estimate equation 3)
*where:
*w=u
*C=X+Z= event-time dummies + time effects+state fixed effects = _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4  i.t i.state
*X includes time effects and the event-time dummies 
*Z incldues state effects 
*step 1
* reghdfe y u if samp, absorb(c_hat=i.t#i.state) resid keepsingletons nocons
reg y u i.state#i.t 
predict c_hat
replace c_hat = c_hat - _b[u]*u - _b[_cons]

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

esttab baseline reg xtglsh xtglsiid re, keep(_k*) se


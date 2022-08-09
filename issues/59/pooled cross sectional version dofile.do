************************* pooled-cross sectional version  ************

* directory
global dir "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\5_august"


*assign treatment randomly 

clear
*specify 50 states 
set obs 50
gen state=_n
set seed 1
gen rand=runiform()
sort rand
gen state2=_n
sort state 
drop rand
save "$dir\state_assign.dta", replace

*load dataset
use "$dir/example31_large.dta", clear

xtset i t
by i (t): gen zd=z-L1.z
by i: gen tt=t if zd==1
by i: egen tt2=max(tt)
replace tt2=0 if missing(tt2)
drop zd tt
order i t tt2 z y, first
*tt2 are cohorts based on treatment time
*e.g. tt2=5 includes units that received treatment in time=5
sort tt2 i t

/*
*assign a state based on the observation's treatment time 
*never treated 
gen state= runiformint(1,3) if tt2==0
order state, after(z)
*treated 
forvalues i=1/20{
local j=`i'*3+1
local z=(`i'*3+1)+2
di "(`j',`z') if `i'"
replace state= runiformint(`j',`z') if tt2==`i'
}
.
*/

*assign a state based on the observation's treatment time 
*never treated 
gen state= runiformint(1,30) if tt2==0 //never treated states goes from 1 to 30
order state, after(z)
*treated 
forvalues i=1/20{
local j=`i'+30
replace state= `j' if tt2==`i' //assign cohort `i' to state `j'
}
.
tab state t 
/*note that from state 1 to 30 we re-assign at unit-time level, but from states 31 to 50, we are assigning a whole unit (and its 20 observations) to a single state. This way, there are more observations in each state-time cell.
*/
*average number of observations per state-time cell
bysort state t: egen cellm=mean(_N)
mean cellm //2,184
drop cellm

*what percentage of observations correspond to never-treated units?
count if tt2==0
di 1407760/2000000 //70.33%

*notice that due to the way it was constructed, treatment is correlated with state 
sort state t i
order state t tt2 z i

*recode state id: randomly assign treatment time by state 
merge m:1 state using "$dir\state_assign.dta"
list if _merge==2
drop if _merge==2

drop state _merge
corr state2 z
order state, first
sort state t i 
rename tt2 treattime 
rename state2 state

lab var state "state id"
lab var treattime "treatment time"
lab var i "individual id"

*reg y z i.t i.state

save "$dir\large_repeated_cross_sectional_example31.dta", replace

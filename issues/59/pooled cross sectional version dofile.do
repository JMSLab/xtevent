************************* pooled-cross sectional version  ************

* directory
global dir "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59"


*assign treatment randomly 

clear
*specify 63 states 
set obs 63
gen state=_n
set seed 1
gen rand=runiform()
sort rand
gen state2=_n
sort state 
drop rand
save "$dir\state_assign.dta", replace

*load dataset
use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear

xtset i t
by i (t): gen zd=z-L1.z
by i: gen tt=t if zd==1
by i: egen tt2=max(tt)
replace tt2=0 if missing(tt2)
drop zd tt
order i t tt2 z y, first
sort tt2 i t

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
*but this way treatment is correlated with state 
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

save "$dir\repeated_cross_sectional_example31.dta", replace


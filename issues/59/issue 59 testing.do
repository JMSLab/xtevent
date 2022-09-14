****************** issue 59 testing *******************

*install the xtevent version from the branch
net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/issue59_-allow-for-data-structures-that-cannot-be-xtseted") replace

*load the small version of the repeated cross-sectional dataset example31
use "https://github.com/JMSLab/xtevent/blob/issue_59-allow-for-data-structures-that-cannot-be-xtseted/issues/59/small_repeated_cross_sectional_example31.dta?raw=true", clear

************** test correct implementation of 1st appraoch 
xtset, clear
*add missing values to policyvar 
replace z=. if state==1 & t==12 
replace z=. in 1

* default  
cap drop aa*
xtevent y, panelvar(state) t(t) policyvar(z) window(5) repeatedcs savek(aa)

* trend 
cap drop aa*
xtevent y, panelvar(state) t(t) policyvar(z) window(5) trend(-3, method(ols)) repeatedcs savek(aa)


* trend & impute 
cap drop aa*
xtevent y, panelvar(state) t(t) policyvar(z) window(5) trend(-3, method(ols)) impute(instag) repeatedcs savek(aa)

* trend & impute, saveimp
cap drop aa*
cap drop *imputed
xtevent y, panelvar(state) t(t) policyvar(z) window(5) trend(-3, method(ols)) impute(instag, saveimp) savek(aa) repeatedcs

*insert a different value in a state-time cell
replace z=1 in 1
cap drop aa*
cap drop *imputed
xtevent y, panelvar(state) t(t) policyvar(z) window(5) trend(-3, method(ols)) impute(instag, saveimp) savek(aa) repeatedcs
replace z=0 in 1

xteventplot

*IV
*error 
xtevent y, panelvar(state) t(t) policyvar(z) window(5) proxy(x)

******************************  get_unit_time_effects (2nd approach) *****************
*please, mannually install the ado file in your computer

*default
get_unit_time_effects y u eta, panelvar(state) timevar(t)
*don't show the regression output
get_unit_time_effects y u eta, panelvar(state) timevar(t) noo
*omit constant in the regression
get_unit_time_effects y u eta, panelvar(state) timevar(t) noo noconstant
*specify file's name and route
get_unit_time_effects y u eta, panelvar(state) timevar(t) name(C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation\effect_file.dta)
*specify only file's name 
cd "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation"
get_unit_time_effects y u eta, panelvar(state) timevar(t) name(effect_file)
*ohter options passed to regress 
get_unit_time_effects y u eta, panelvar(state) timevar(t) vce(robust) level(90)

************************ get_unit_time_effects + xtevent ***********************
get_unit_time_effects y u eta, panelvar(state) timevar(t) name(C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation\effect_file.dta)
bysort state t (z): keep if _n==1
keep state t z
merge m:1 state t using "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation\effect_file.dta"
drop _merge
cap drop aa*
xtevent effects, panelvar(state) t(t) policyvar(z) window(5) savek(aa)
xteventplot

******************* verify that estimation for panel datasets keep working 

use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
cap drop aa*
xtevent y, panelvar(i) t(t) policyvar(z) window(5) savek(aa)
xteventplot

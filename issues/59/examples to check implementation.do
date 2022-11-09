****************** issue 59: examples to check implementation *******************

*directory where to save plots
global plots "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation"
*install the xtevent version from the branch
*net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/issue_59-allow-for-data-structures-that-cannot-be-xtseted") replace

*load the small version of the repeated cross-sectional dataset example31
use "https://github.com/JMSLab/xtevent/blob/issue_59-allow-for-data-structures-that-cannot-be-xtseted/issues/59/small_repeated_cross_sectional_example31.dta?raw=true", clear

************** test correct implementation of 1st appraoch ****************

****** _eventols

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

*insert a different value in a state-time cell: expect an error
replace z=1 in 1
cap drop aa*
cap drop *imputed
xtevent y, panelvar(state) t(t) policyvar(z) window(5) trend(-3, method(ols)) impute(instag, saveimp) savek(aa) repeatedcs
replace z=0 in 1

*xteventplot
cap drop aa*
xtevent y, panelvar(state) t(t) policyvar(z) window(5) trend(-3, method(gmm) saveoverlay) impute(stag) repeatedcs
xteventplot
graph export test_xteventplot.png, replace
xteventplot, overlay(trend)

************* IV
use "https://github.com/JMSLab/xtevent/blob/issue_59-allow-for-data-structures-that-cannot-be-xtseted/issues/59/small_repeated_cross_sectional_example31.dta?raw=true", clear
xtset, clear //cannot xtset panelvar and timevar 
*add missing values to policyvar 
replace z=. if state==1 & t==12 

*default 
xtevent y, panelvar(state) t(t) policyvar(z) window(5) proxy(x) repeatedcs 

*impute 
xtevent y, panelvar(state) t(t) policyvar(z) window(5) impute(stag) proxy(x)  repeatedcs 

*trend 
*trend not allowed in the IV setting

*nofe (then, it uses ivregress)
xtevent y, panelvar(state) t(t) policyvar(z) window(5) impute(stag) proxy(x) repeatedcs nofe

*reghdfe (then, it uses ivreghdfe)
xtevent y, panelvar(state) t(t) policyvar(z) window(5) impute(stag) proxy(x) repeatedcs reghdfe

*xteventplot 
xtevent y, panelvar(state) t(t) policyvar(z) window(5) impute(stag) proxy(x)  repeatedcs 
xteventplot
xteventplot, overlay(iv)

******************************  get_unit_time_effects (2nd approach) *****************
*please, mannually install the ado file in your computer

*load the small version of the repeated cross-sectional dataset example31
use "https://github.com/JMSLab/xtevent/blob/issue_59-allow-for-data-structures-that-cannot-be-xtseted/issues/59/small_repeated_cross_sectional_example31.dta?raw=true", clear
xtset, clear
*add missing values to policyvar 
replace z=. if state==1 & t==12 
replace z=. in 1

*default: save it as get_unit_time_effects.dta in the current directory
cap erase unit_time_effects.dta
get_unit_time_effects y u eta, panelvar(state) timevar(t)
*replace get_unit_time_effects.dta file
get_unit_time_effects y u eta, panelvar(state) timevar(t) replace
*don't show the regression output
get_unit_time_effects y u eta, panelvar(state) timevar(t) replace noo
*specify file's name and route
get_unit_time_effects y u eta, panelvar(state) timevar(t) replace name("C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation\effect_file.dta")
*specify only file's name 
cd "$plots"
get_unit_time_effects y u eta, panelvar(state) timevar(t) replace name(effect_file)

*error if there is a variable named effects 
gen effects=.
get_unit_time_effects y u eta, panelvar(state) timevar(t) name("C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation\effect_file.dta") replace 
drop effects
*use load option to load the effects file 
get_unit_time_effects y u eta, panelvar(state) timevar(t) name("C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\59\implementation\effect_file.dta") replace load

************************ get_unit_time_effects + xtevent ***********************
use "https://github.com/JMSLab/xtevent/blob/issue_59-allow-for-data-structures-that-cannot-be-xtseted/issues/59/small_repeated_cross_sectional_example31.dta?raw=true", clear
xtset, clear
*add missing values to policyvar 
replace z=. if state==1 & t==12 
replace z=. in 1

get_unit_time_effects y u eta, panelvar(state) timevar(t) name("$plots\effect_file.dta") replace 
bysort state t (z): keep if _n==1
keep state t z
merge m:1 state t using "$plots\effect_file.dta"
drop _merge
cap drop aa*
xtevent effects, panelvar(state) t(t) policyvar(z) window(5) savek(aa)
xteventplot
graph export "$plots\get_utf_plus_xtevent.png", replace

******************* verify that estimation for panel datasets keep working 

use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
xtevent y, panelvar(i) t(t) policyvar(z) window(5) impute(stag) trend(-3)
xteventplot

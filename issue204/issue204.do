

cd "C:\Users\B18945\Downloads\temp20240515_2\xtevent-204-erroneously-dropping-variables-owing-to-inexact-variable-name-match\issue204"

**** Check that the program drops only the reserved variables
use "example31.dta", clear
*event-time dummies and event-time variable 
gen __k_myvar=1
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) // it didn't drop the variable __k_myvar
*trend 
gen _ttrend_myvar=1
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) trend(-2, method(ols)) // it didn't drop the variable _ttrend_myvar

*** error message when existing variables and replace suboption 
use "example31.dta", clear
*save event-time dummies + event-time variable 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa) 
*expect an error 
cap noi xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa)
*add replace suboption 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa, replace)
*rename the event-time dummies and the event-time variable 
rename aa_eq_* aa_eq_*_myvar
rename aa_evtime aa_evtime_myvar
*no error because variable names don't match 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa)

**** Check saving of interaction variables in SA's framewok 
use "example31.dta", clear
*save interaction variables 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa, saveint) sunabraham 
* try to save them again and expect an error 
cap noi xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa, saveint) sunabraham 
*rename the variables 
rename aa_eq_* aa_eq_*_myvar
rename aa_evtime aa_evtime_myvar
rename aa_interact_* aa_interact_*_myvar 
*no error because variable names don't match 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa, saveint) sunabraham
*save them again, replacing the ones that match the name 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) savek(aa, saveint replace) sunabraham

**** IV 
use "example31.dta", clear
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) proxy(x)
*savek
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) proxy(x) savek(aa)
*try to save again and expect an error 
cap noi xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) proxy(x) savek(aa)
*rename variables 
rename aa_eq_* aa_eq_*_myvar
rename aa_evtime aa_evtime_myvar
*no error because variable names don't match 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) proxy(x) savek(aa)
*save them again, replacing the ones that match the name 
xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(stag) proxy(x) savek(aa, replace) 



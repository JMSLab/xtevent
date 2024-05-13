*ado-files: C:\Users\B18945\ado\plus\x
*local directory: C:\Users\B18945\Downloads\xtevent-189-difference-of-averages-doesnt-include-all-coefficients

cd "C:\Users\B18945\Downloads\xtevent-177-allow-replacing-when-saving-event-time-dummies\issue177"

cap log close 
log using issue177.txt, replace text 

*load dataset from 
*https://github.com/JMSLab/xtevent/blob/main/test/example31.dta

***** OLS
use example31, clear 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) savek(aa)
*expect an error 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) savek(aa)
*add replace suboption 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) savek(aa, replace)
* savek with a different prefix (it doesn't drop the "aa" variables)
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) savek(aaa)
*add replace suboption: it replaces only the "aa" variables
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) savek(aa, replace)

*combine noestimate + replace 
use example31, clear 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) savek(aa, noestimate)
*expect an error 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) savek(aa, noestimate)
*add replace suboption
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) savek(aa, noestimate replace)

***** IV
use example31, clear 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) proxy(x) savek(aa)
*expect an error 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) proxy(x) savek(aa)
*add replace suboption 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) proxy(x) savek(aa, replace)

***** trend
use example31, clear 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) trend(-2, method(ols)) savek(aa)
*expect an error 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) trend(-2, method(ols)) savek(aa)
*add replace suboption 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(max) trend(-2, method(ols)) savek(aa, replace)


***** interaction variables in SA' framework  
use example31, clear 
xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) cohort(create) savek(aa, saveint)
*expect an error 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) cohort(create) savek(aa, saveint)
*add replace suboption 
cap noi xtevent y eta, panelvar(i) timevar(t) pol(z) impute(stag) window(6) cohort(create) savek(aa, saveint replace)

log close 
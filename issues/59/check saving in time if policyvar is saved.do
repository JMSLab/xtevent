********** check increase in speed if saving the imputed policyvar *************
*load the small version of the repeated cross-sectional dataset example31
use "https://github.com/JMSLab/xtevent/blob/issue_59-allow-for-data-structures-that-cannot-be-xtseted/test/example31.dta?raw=true", clear

timer clear
timer on 1
forvalues i=1/10{
xtevent y, panelvar(i) t(t) policyvar(z) window(5) proxy(x) impute(stag) 
}
timer off 1

timer on 2
cap drop z_imputed
xtevent y, panelvar(i) t(t) policyvar(z) window(5) proxy(x) impute(stag, saveimp) 
forvalues i=1/9{
xtevent y, panelvar(i) t(t) policyvar(z_imputed) window(5) proxy(x) impute(stag) 
}
timer off 2
timer list
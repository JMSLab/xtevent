*************** issue 28 examples *******************************

***********************************************
******************** OLS **********************
*create sample
clear all
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
*insert missing valus
replace z=. if t<4 | t>17
replace z=. if inlist(t,10) & id==1
xtset id t

******* invalid imputation name *********************
*defult (don't call the impute option)
xtevent y, policyvar(z) w(2)

*introduce an invalid option
xtevent y, policyvar(z) w(2) impute(imputation)
*valid option
xtevent y, policyvar(z) w(2) impute(instag)

******** add imputed variable to the database *******

xtevent y, policyvar(z) w(2) impute(instag, saveimp)
*error 
xtevent y, policyvar(z) w(2) impute(instag, saveimp)
*drop it
cap drop z_imputed
*no error if no saveimp 
xtevent y, policyvar(z) w(2) impute(instag)
xtevent y, policyvar(z) w(2) impute(instag)
*invalid suboption
xtevent y, policyvar(z) w(2) nodrop impute(instag, saveimp save)

**********************************************************************
************************* IV *******************************************

clear all
set obs 60
gen id = 1
replace id = 2 if _n > 20
replace id=3 if _n>40
bys id: gen t = _n

gen y = uniform()
gen x=runiform(2,3)
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
replace z=. if id==1 & (t<3 | t>16)
replace z=. if inlist(t,10) & id==1
xtset id t

***************** imputation succeeds **********************
*default 
xtevent y, policyvar(z) proxy(x) w(2) 
*impute and don't generate imputed policyvar
xtevent y, policyvar(z) proxy(x) w(2) impute(instag)
*no error if re-run since saveimp is not specified
xtevent y, policyvar(z) proxy(x) w(2) impute(instag)

*impute and and add imputed policyvar
xtevent y, policyvar(z) proxy(x) w(2) impute(instag, saveimp)
cap drop z_imputed

*************** imputation fails ********************************
replace z=0.5 if id==1 & t==7 //policyvar is not binary 

*impute and don't generate imputed policyvar 
xtevent y, policyvar(z) proxy(x) w(2) impute(instag)

*impute and generate imputed policyvar 
xtevent y, policyvar(z) proxy(x) w(2) impute(instag, saveimp)

***************************************************************
********************** STATIC ******************************
clear all
set obs 60
gen id = 1
replace id = 2 if _n > 20
replace id=3 if _n>40
bys id: gen t = _n

gen y = uniform()
gen x=runiform(2,3)
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
replace z=. if id==1 & (t<3 | t>16)
replace z=. if inlist(t,10) & id==1
xtset id t
************* ols static
*default
xtevent y, policyvar(z) static
*dont add the imputed policyvar
xtevent y, policyvar(z) static impute(instag)
*add the imputed policyvar
xtevent y, policyvar(z) static impute(instag, saveimp)
cap drop z_imputed

************* IV static
*default
xtevent y, policyvar(z) proxy(x) static
*dont add the imputed policyvar
xtevent y, policyvar(z) proxy(x) static impute(instag)
*add the imputed policyvar
xtevent y, policyvar(z) proxy(x) static impute(instag, saveimp)
cap drop z_imputed

************************************************************
****************** check binary *******************************
clear all
set obs 60
gen id = 1
replace id = 2 if _n > 20
replace id=3 if _n>40
bys id: gen t = _n

gen y = uniform()
gen x=runiform(2,3)
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
replace z=. if id==1 & (t<3 | t>16)
replace z=. if inlist(t,10) & id==1
xtset id t

*policyvar is binary
*nuchange
xtevent y, policyvar(z) window(2) impute(nuchange)
*policyvar is not binary
replace z=0.5 if id==1 & t==7
xtevent y, policyvar(z) window(2) impute(nuchange, saveimp) //nuchange is not subject to passing binary
cap drop z_imputed
*but the program check binary in any case
xtevent y, policyvar(z) window(3) impute(nuchange, saveimp) trend(-2)
drop z_imputed
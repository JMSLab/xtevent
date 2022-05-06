******** examples to verify the implementation of the impute() option ***********


*from the helpfile:
/*
    impute(string) imputes missing values in policyvar and uses this new
        variable as the actual policyvar. It also adds the new variable to the
        database.

        impute(nuchange) imputes missing values in policyvar according to
            no-unobserved change: it assumes that, for each unit: i) in periods
            before the first observed value, the policy value is the same as
            the first observed value; and ii) in periods after the last
            observed value, the policy value is the same as the last observed
            value.

        impute(stag) applies no-unobserved change if policyvar satisfies
            staggered-adoption assumptions for all units: i) policyvar must be
            binary; and ii) once policyvar reaches the adopted-policy state, it
            never reverts to the unadopted-policy state. See Freyaldenhoven et
            al. (2019) for detailed explanation of the staggered case.
            Additionally, for all units: i) the first-observed value must be
            the unadopted-policy-state value, and the last-observed value must
            be the adopted-policy-state value; or ii) all policy values in the
            observed data range must be either adopted-policy-state values or
            unadopted-policy-state values.

        impute(instag) applies impute(stag) and additionally imputes missing
            values inside the observed data range: a missing value or a group
            of them will be imputed only if they are both preceded and followed
            by the unadopted-policy state or by the adopted-policy state.
*/

clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 

xtset id t

******* balanced scenario *********************
*defult (don't call the impute option)
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) //implies imputation of the endpoints
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(nuchange)

****** missing values in the extremes ***********
replace z=. if t<4 & id==1
replace z=. if t<6 & id==2
replace z=. if t>15

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag)
*no-unobserved-change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(nuchange) 

****** missing values inside the observed range ****************
replace z=0 if t<5 & id==1
replace z=0 if t<6 & id==2
replace z=1 if t>15

replace z=. if t==6 & id==1
replace z=. if t==9 & id==1

*default
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(nuchange) //nothing to impute
*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) //nothing to impute
*instag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(instag) 

****** missing values inside and outside ********************
replace z=. if t<4 & id==1
replace z=. if t>15 & id==1
replace z=0 if id==1 & t==6
*default
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*no-unobserved-change 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(nuchange)
*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag)
*instag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(instag)
 

***** not following staggered behavior (no-revertion) ****************
replace z=0 if t==9 & id==1

*stag
cap drop *k*
xtevent y, policyvar(z) w(1) nodrop impute(stag) //stag fails & warning message
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(1) nodrop impute(nuchange)

*with missing value inside
replace z=. if inlist(t,9,10) & id==1
replace z=0 if t==11 & id==1

cap drop *k*
xtevent y, policyvar(z) w(1) nodrop impute(stag) //stag fails & warning message

***** not following "bounds" condition: e.g., 0 at the beggining and 1 at the end, or only zeros or only ones, but without missing values inside the observed data range
replace z=1 if inlist(t,9,10,11) & id==1
replace z=0 if id==1 & !missing(z)

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) 

*add missing values inside the observed data range
replace z=. if id==1 & t==8 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) // stag fails & reverts to default

********** missing times in the middle *********************
replace z=0 if t<10 & id==1
replace z=1 if t>=10 & id==1
replace z=. if t<4
replace z=. if t>15

drop in 11

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
/* missing observation in t=11 and id=1 affects differently the event-time dummies (inserting 1 missings vs 2 missings) depending on the order of the forwards and lags that defines the M's and P's variables. The matrix will not be symmetric. */

*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) 

************ missing times in the extremes *******************

clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen z=(t>=9)
replace z=0 if t==9 & id==2

drop in 1/4

xtset id t

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag)

******************* impute inner missing values  ********************
clear all

*create sample
set obs 60
gen id = 1
replace id = 2 if _n > 20
replace id = 3 if _n > 40
bys id: gen t = _n

gen y = uniform()
gen z=(t>=9)
replace z=0 if t==9 & id==2
xtset id t

******* both sides are bounded
replace z=. if inlist(t,10,11) & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

*instag: outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(instag) //nothing to impute in the extremes 

****** missing values are not equally bounded 
replace z=1 if inlist(t,10,11) & id==1
replace z=. if inlist(t,8,9) & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop //warning message: unknown treatment time. Don't exclude the unit

*outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(instag) //it excludes the unit 

****** outer and inner missing values
replace z=1 if inlist(t,8,9) & id==1
replace z=. if inlist(t,9,10) & id==1
replace z=. if t<4 & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

*outer imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag)

*outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(instag) 

****** equally bounded & missing time 
replace z=0 if t<4 & id==1
replace z=1 if inlist(t,9,10) & id==1
replace z=. if inlist(t,9,10,11) & id==1
drop if t==10 & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

*outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(instag) 

******** warning message when some units have unknown event time ********

*show warning message when unknown event-time is due to missing values in the policy variable
clear all

*create sample
set obs 60
gen id = 1
replace id = 2 if _n > 20
replace id = 3 if _n > 40
bys id: gen t = _n

gen y = uniform()
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 

xtset id t

replace z=. if inlist(t,7,8) & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop //it doesn't exclude the unit

*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) // it excludes the unit. Only exclude if stag or instag

*********** don't generate time variable (__k) when there are more than one event ***** 
clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 

xtset id t

replace z=0 if id==1 & t==9

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop //in default it never generates __k
*stag 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) //generate __k only if stag conditions are satisfied. This conditions imply that each unit has zero or one event. 

**************** not binary ********************************
replace z=1 if id==1 & t==9
replace z=0.5 if id==1 & t==7
*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*stag 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) //binary condition fails. It reverts to default


*************************** binary of type 0/2 ***************************
clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen z=2*(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 

xtset id t

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) 

***************** staggered case allows units with only zeros/ones ************
clear all

*create sample
set obs 60
gen id = 1
replace id = 2 if _n > 20
replace id = 3 if _n > 40
bys id: gen t = _n

gen y = uniform()
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
replace z=0 if id==1
replace z=. if id==1 & (t<4 | t>15)
xtset id t

*** only zeros 
*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*stag
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) 

*** only ones  
replace z=1 if id==1 & z==0
*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*stag 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) 

*add an inner missing value, so stag will fail
replace z=. if id==1 & t==9
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute(stag) 

********************** IV **********************************
clear all

*create sample
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
replace z=. if inlist(t,9,10) & id==1
xtset id t

*default 
cap drop k*
xtevent y, policyvar(z) proxy(x) w(2) savek(k)

*outer imputation 
cap drop k*
xtevent y, policyvar(z) proxy(x) w(2) savek(k) impute(stag)

*outer & inner imputation 
cap drop k*
xtevent y, policyvar(z) proxy(x) w(2) savek(k) impute(instag)


***************** ols static ************************

clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen x=runiform(2,3)
gen u=runiform(3,4)
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
replace z=. if id==1 & (t<3 | t>16)
replace z=. if inlist(t,9,10) & id==1
xtset id t

*default 
cap drop k*
xtevent y, policyvar(z) static 

*instag 
cap drop k*
xtevent y, policyvar(z) static impute(instag) // "policyvar_imputed" is included in the regression

***************** IV static ****************************

clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen x=runiform(2,3)
gen u=runiform(3,4)
gen z=(t>=8)
replace z=0 if t==8 & id==2 //policy starts at different times 
replace z=. if id==1 & (t<3 | t>16)
replace z=. if inlist(t,9,10) & id==1
xtset id t

*default 
cap drop k*
xtevent y, policyvar(z) proxy(x) static 

*outer imputation  
cap drop k*
xtevent y, policyvar(z) proxy(x) st impute(stag)

*outer & inner imputation  
cap drop k*
xtevent y, policyvar(z) proxy(x) st impute(instag)



* examples

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

******* balanced scenario
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

****** missing values in the extremes (imputes)
replace z=. if t<5 & id==1
replace z=. if t<6 & id==2
replace z=. if t>15

*no imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop 
*imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute

****** missing values inside 
replace z=0 if t<5 & id==1
replace z=0 if t<6 & id==2
replace z=1 if t>15

replace z=. if t==6 & id==1
replace z=. if t==9 & id==1

cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

****** missing values inside and outside
replace z=. if t<5 & id==1
replace z=. if t>15 & id==1
replace z=0 if id==1 & t==6
*no imputation 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*imputation 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute 

***** not following staggered behavior (no-revertion) 
replace z=0 if t==9 & id==1

*imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute //imputation fails

***** not following staggered behavior (0 at the beggining and 1 at the end) 
replace z=1 in 9
replace z=0 if id==1 & !missing(z)

cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute //imputation fails

****** missing times in the middle 
replace z=0 if t<10 & id==1
replace z=1 if t>=10 & id==1
replace z=. if t<5
replace z=. if t>15

drop in 11

*no imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
/* missing observation in t=11 and id=1 affects differently the event-time dummies (inserting 1 missings vs 2 missings) depending on the order of the forwards and lags that defines the M's and P's variables. The matrix will not be symmetric. */

*imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop impute
************ missing times in the extremes 

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

cap drop *k*
xtevent y, policyvar(z) w(2) nodrop




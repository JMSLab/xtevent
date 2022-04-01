* examples: implementation of options nuchange (no unobserved change) & stag (staggered)

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
*defult
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop nuchange

****** missing values in the extremes 
replace z=. if t<4 & id==1
replace z=. if t<6 & id==2
replace z=. if t>15

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag
*no-unobserved-change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop nuchange 

****** missing values inside 
replace z=0 if t<5 & id==1
replace z=0 if t<6 & id==2
replace z=1 if t>15

replace z=. if t==6 & id==1
replace z=. if t==9 & id==1

*default
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop nuchange

****** missing values inside and outside
replace z=. if t<4 & id==1
replace z=. if t>15 & id==1
replace z=0 if id==1 & t==6
*default
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag
*no-unobserved-change 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop nuchange 

***** not following staggered behavior (no-revertion) 
replace z=0 if t==9 & id==1

*staggered
cap drop *k*
xtevent y, policyvar(z) w(1) nodrop stag //staggered fails
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(1) nodrop nuchange

*with missing value inside
replace z=. if inlist(t,9,10) & id==1
replace z=0 if t==11 & id==1

cap drop *k*
xtevent y, policyvar(z) w(1) nodrop stag //staggered fails

***** not following staggered behavior (0 at the beggining and 1 at the end) 
replace z=1 if inlist(t,9,10,11) & id==1
replace z=0 if id==1 & !missing(z)

*staggered
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag //staggered fails
*no unobserved change
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop nuchange

****** missing times in the middle 
replace z=0 if t<10 & id==1
replace z=1 if t>=10 & id==1
replace z=. if t<4
replace z=. if t>15

drop in 11

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
/* missing observation in t=11 and id=1 affects differently the event-time dummies (inserting 1 missings vs 2 missings) depending on the order of the forwards and lags that defines the M's and P's variables. The matrix will not be symmetric. */

*staggered
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag 
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

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop
*staggered 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag

******************* replace inner missing values  ********************
clear all

*create sample
set obs 40
gen id = 1
replace id = 2 if _n > 20
bys id: gen t = _n

gen y = uniform()
gen z=(t>=9)
replace z=0 if t==9 & id==2
xtset id t

******* equally bounded
replace z=. if inlist(t,10,11) & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

*outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop instag

****** not equally bounded
replace z=1 if inlist(t,10,11) & id==1
replace z=. if inlist(t,8,9) & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop //warning: for some units we don't know treatment time

*outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop instag //fails

****** outer and inner missing values
replace z=1 if inlist(t,8,9) & id==1
replace z=. if inlist(t,9,10) & id==1
replace z=. if t<4 & id==1

*default 
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop

*outer imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop stag

*outer & inner imputation
cap drop *k*
xtevent y, policyvar(z) w(2) nodrop instag 

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
xtevent y, policyvar(z) w(2) nodrop instag


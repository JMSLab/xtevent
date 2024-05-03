*ado-files: C:\Users\B18945\ado\plus\x
*local directory: C:\Users\B18945\Downloads\xtevent-170-let-the-window-option-choose-a-window-range

cd "C:\Users\B18945\Downloads\xtevent-170-let-the-window-option-choose-a-window-range\issue170"
cap log close 
log using issue170.txt, replace text 


*load dataset from 
*https://github.com/JMSLab/xtevent/blob/main/test/example31.dta
use example31, clear

******************************** Error messages  ******************************

*** Window(max|balanced) can be used only if impute(stag|instag) is specified
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(max)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced) impute(nuchange)

*** Error messages due incorrect specification of window  
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5.5)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(hello)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(hello -3)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(3.5 5.5 7.8)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(3 5 7)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-3)

*** errors because policyvar doesn't follow staggered adoption 
* no binary
use example31, clear
replace z= 0.5 in 7 
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(max)
*it reverts
use example31, clear
replace z= 0 in 8
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(max)
*always treated or never-treated units don't take the adopted or unadopted policy values 
use example31, clear
replace z= 1 if  i==1
replace z=. in 8
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(max)

*** errors if the calculated limits for window are problematic 

*calculated left window is positive or right window is negative 
use example31, clear
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(balanced)
replace z= 0 if t==20 & inlist(i, 54, 187, 240, 312, 315, 357, 446, 479, 487, 635, 687, 709, 748, 751, 887, 923, 943) // these units are causing the right window limit to be negative. Turn them into never-treated units 
xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(balanced) 


********************************* Examples to check correct functionality  ******************************

** OLS

use example31, clear
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(max) // requires adding impute()
xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(max)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(balanced) //balanced window is too narrow, this is not a problem of the option but a limit imposed by this dataset
*Try with another dataset 

* compare with eventdd and its help file's dataset 
webuse set www.damianclarke.net/stata/
webuse bacon_example, clear 
generate timeToTreat = year - _nfd
eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) // calculated window limits are -20 and 26, plus the endpoints 
*eventdd's balanced option (it estimates with maximum window, but shows plot that corresponds to balanced time periods only)
eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips))  balanced // calcualted window is (-4, 10), plus the endpoints 

* now use that dataset with xtevent command 
*max
xtevent asmrs pcinc asmrh cases, timevar(year) panelvar(stfips) policyvar(post) impute(stag) window(max) // same window as with the eventdd command 
xteventplot // x-axis labels are cramped. Leave adjustment to the user?
*balanced
xtevent asmrs pcinc asmrh cases, timevar(year) panelvar(stfips) policyvar(post) impute(stag) window(balanced) // same window as with the eventdd command
xteventplot

** missing values in varlist 
use example31, clear
gen pois = rpoisson(5) in 1/200
xtevent y eta i.pois, panelvar(i) timevar(t) pol(z) window(max) impute(stag) plot // window=(-15, 12) and endpoints={-16, 13}
* marksample (the marker for non-missing observations in varlist) doesn't interfer with mark (the marker for if & in conditions)
xtevent y eta i.pois if i<4, panelvar(i) timevar(t) pol(z) window(max) impute(stag) plot // window=(-12, 12) and endpoints={-13, 13}


******* IV

*** return to the example31 dataset 
use example31, clear
cap noi xtevent y eta, panelvar(i) timevar(t) policyvar(z) proxy(x) impute(stag) window(max) // instrument is collinear
* try same specification but with a narrower observed data range 
keep if inrange(t,5,15)
xtevent y eta, panelvar(i) timevar(t) policyvar(z) proxy(x) impute(stag) window(max)
*balanced 
cap noi xtevent y eta, panelvar(i) timevar(t) policyvar(z) proxy(x) impute(stag) window(balanced) // cannot test because balanced window is too narrow 

*** try csdid's dataset 
use "https://friosavila.github.io/playingwithstata/drdid/mpdta.dta", clear
xtset countyreal year 
gen ttreat = year - first_treat
gen z=(ttreat>=0)
csdid  lemp lpop , ivar(countyreal) time(year) gvar(first_treat) method(dripw)
set seed 3
gen eta=runiform()
*max
xtevent lemp lpop, timevar(year) panelvar(countyreal) policyvar(z) proxy(eta) impute(stag) window(max)
*balanced 
cap noi xtevent lemp lpop, timevar(year) panelvar(countyreal) policyvar(z) proxy(eta) impute(stag) window(balanced) //cannot test "balanced" with this dataset, window is too narrow 


*Check that lead in proxyiv is not outside estimation window 
use example31, clear
cap noi xtevent y eta, panelvar(i) timevar(t) policyvar(z) proxy(x) impute(stag) window(max) proxyiv(5 e 20)

** missing values in varlist 
use example31, clear
keep if inrange(t,5,15) //
gen pois = rpoisson(5) in 1/2000
xtevent y eta i.pois, panelvar(i) timevar(t) pol(z) impute(stag) proxy(x) window(max)  // window=(-9, 8) and endpoints={-10, 9}
* marksample (the marker for non-missing observations in varlist) doesn't interfer with mark (the marker for if & in conditions)
xtevent y eta i.pois if i<40, panelvar(i) timevar(t) pol(z) window(max) impute(stag) // window=(-8, 7) and endpoints={-9, 8}


****************** interaction with other options **************************************

* coefficient to normalize is outside the calculated window 
use example31, clear
replace z= 0 if t==20 & inlist(i, 54, 187, 240, 312, 315, 357, 446, 479, 487, 635, 687, 709, 748, 751, 887, 923, 943) // to overcome the problem with left window being positive or right window being negative 
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(balanced) norm(2)

*trend 
use example31, clear
xtevent y eta , panelvar(i) timevar(t) policyvar(z) trend(-10, method(ols)) impute(stag) window(max)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) trend(-20, method(gmm)) impute(stag) window(max)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) trend(-15, method(ols)) impute(stag) window(balanced)


*** xteventplot overlay 
use example31, clear
*static 
xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(stag) window(max)
xteventplot, overlay(static)
*trend 
xtevent y eta , panelvar(i) timevar(t) policyvar(z) trend(-10, method(ols) saveoverlay) impute(stag) window(max)
xteventplot, overlay(trend)

*************** Examples to check that implementation doesn't alter other functionalities  ************************

* window 
use example31, clear
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(3)
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-3 5)
*impute 
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-18 16) // need to add impute()
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-18 16) impute(nuchange)
* trend adjustment 
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-18 16) impute(nuchange) trend(-3)
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-18 16) impute(nuchange) trend(-3, method(gmm))
* IV
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(6) impute(nuchange) proxy(zeta)

log close 



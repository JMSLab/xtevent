
cap log close 
log using issue170_examples.txt, replace text 


*load dataset from 
*https://github.com/JMSLab/xtevent/blob/main/test/example31.dta
use example31, clear

******************************** Errors  ******************************

* Error messages due incorrect specification of window  
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5.5)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(hello)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(hello -3)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(3.5 5.5 7.8)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(3 5 7)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-3)

***** errors because policyvar doesn't follow staggered adoption 
* no binary
use example31, clear
replace z= 0.5 in 7 
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(max)
*it reverts
use example31, clear
replace z= 0 in 8
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(max)
*always treated or never-treated units don't take the adopted or unadopted policy values 
use example31, clear
replace z= 1 if  i==1
replace z=. in 8
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(max)

****** errors if the found limits for window are problematic 

*found left window is positive or right window is negative 
use example31, clear
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced)
replace z= 0 if t==20 & inlist(i, 54, 187, 240, 312, 315, 357, 446, 479, 487, 635, 687, 709, 748, 751, 887, 923, 943) // these units are causing the right window limit to be negative. Turn them into never-treated units 
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced) 
* Window is too narrow 
use example31, clear
replace z= 0 if t==20 & inlist(i, 54, 187, 240, 312, 315, 357, 446, 479, 487, 635, 687, 709, 748, 751, 887, 923, 943) // to overcome the problem with left window being positive or right window being negative 
replace z= 1 if t==2 & inlist(i,236,608,931) // to shorten the left window 
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced) 
* coefficient to normalize is outside the found window 
use example31, clear
replace z= 0 if t==20 & inlist(i, 54, 187, 240, 312, 315, 357, 446, 479, 487, 635, 687, 709, 748, 751, 887, 923, 943)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced) norm(2)


********************************* Examples to check correct functionality  ******************************

use example31, clear
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(max) // requires adding impute()
xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(nuchange) window(max)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(balanced)
cap noi xtevent y eta , panelvar(i) timevar(t) policyvar(z) impute(nuchange) window(balanced) // even after adding impute() window is too narrow, but this is not a problem with the option but a limit imposed by this dataset
*Try with other dataset 

****** compare with eventdd and its help file's dataset 
webuse set www.damianclarke.net/stata/
webuse bacon_example, clear 
generate timeToTreat = year - _nfd
eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m women") xlabel(-20(5)25)) // found window limits are -20 and 26, plus the endpoints 
*eventdd's balanced option (it estimates with maximum window, but shows plot that corresponds to balanced time periods only)
eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m women")) balanced // found window is (-4, 10), plus the endpoints 

***xtevent command 
** OLS
*max
xtevent asmrs pcinc asmrh cases, timevar(year) panelvar(stfips) policyvar(post) impute(nuchange) window(max) // same window as with the eventdd command 
xteventplot // x-axis labels are cramped. Leave correction to the user?
*balanced
xtevent asmrs pcinc asmrh cases, timevar(year) panelvar(stfips) policyvar(post) impute(nuchange) window(balanced) // same window as with the eventdd command
xteventplot

******* IV
*** return to the example31 dataset 
use example31, clear
xtevent y eta, panelvar(i) timevar(t) policyvar(z) impute(nuchange) proxy(x) window(3)
cap noi xtevent y eta, panelvar(i) timevar(t) policyvar(z) impute(nuchange) proxy(x) window(max) // instrument is collinear
* try with a narrower observed data range 
keep if inrange(t,5,15)
xtevent y eta, panelvar(i) timevar(t) policyvar(z) impute(nuchange) proxy(x) window(max)
*balanced 
cap noi xtevent y eta, panelvar(i) timevar(t) policyvar(z) impute(nuchange) proxy(x) window(balanced) // cannot test because balanced window is too narrow 

*** try csdid's dataset 
use "https://friosavila.github.io/playingwithstata/drdid/mpdta.dta", clear
xtset countyreal year 
gen ttreat = year - first_treat
gen z=(ttreat>=0)
csdid  lemp lpop , ivar(countyreal) time(year) gvar(first_treat) method(dripw)
set seed 3
gen eta=runiform()
*max
xtevent lemp lpop, timevar(year) panelvar(countyreal) policyvar(z) impute(nuchange) proxy(eta) window(max)
*balanced 
cap noi xtevent lemp lpop, timevar(year) panelvar(countyreal) policyvar(z) impute(nuchange) proxy(eta) window(balanced)


*************** Examples to check that changes don't alter other functionalities  ************************

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


cap log close

cap log using test.log, replace text

clear all

/*=========================================================================
                        1: Load data 
===========================================================================*/	
use "example31.dta", clear


/*=========================================================================
                        2: Run tests
===========================================================================*/
	
graph drop _all

*------------------------ 2.1: Replicate 2a and test basic funcionality ----------------------------------

xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(5)

* Testing xtset options

xtevent y eta, policyvar(z) window(5) plot
xtevent y eta, policyvar(z) panelvar(i) window(5) plot
xtevent y eta, policyvar(z) timevar(t) window(5) plot


/* Must fail
xtevent y eta, policyvar(z) panelvar(z) window(5) 
xtevent y eta, policyvar(z) timevar(z) window(5) 
*/

* Testing noci, nosupt, nozeroline, nominus1label
xtevent y eta, policyvar(z) timevar(t) window(5)
xteventplot, noci
xtevent y eta, policyvar(z) timevar(t) window(5)
xteventplot, nosupt
xtevent y eta, policyvar(z) timevar(t) window(5)
xteventplot, nozeroline
xtevent y eta, policyvar(z) timevar(t) window(5)
xteventplot, nominus1label

* A common axis plot with labels
gen y2 = y + 5
xtevent y eta, policyvar(z) timevar(t) window(5)
loc lab : di %-9.2f `=e(y1)'
loc lab=strtrim("`lab'")
xteventplot, nominus1label ylab(-3 0 `"0 (`lab')"' 3) name(g1) /* " */
xtevent y2 eta, policyvar(z) timevar(t) window(5)
loc lab : di %-9.2f `=e(y1)'
loc lab=strtrim("`lab'")
xteventplot, nominus1label ylab(-3 0 `"0 (`lab')"' 3) name(g2) /* " */
graph combine g1 g2
drop y2

* Test if/in
xtevent y eta if i<100, panelvar(i) timevar(t) policyvar(z) window(5) plot
xtevent y eta in 1/600 , panelvar(i) timevar(t) policyvar(z) window(5) plot
xtevent y eta in 1/600 if i<30 , panelvar(i) timevar(t) policyvar(z) window(5) plot

* Test nofe, note
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) nofe plot
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) nofe note plot

* Test smoothest line
xtevent eta, panelvar(i) timevar(t) policyvar(z) window(4) 
xteventplot, smpath(scatter)
xteventplot, smpath(line)
xteventplot, smpath(line, technique("nr 10 bfgs 10"))

* Test more suptreps

cap graph drop g1
cap graph drop g2

xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(3) 
xteventplot, suptreps(20) name(g1)
xteventplot, suptreps(1e6) name(g2)

graph combine g1 g2, rows(1)

graph drop g1
graph drop g2

* Test savek
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) savek(a)
des a_eq*, s
des a_evtime, s
drop a*

xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) savek(b)

* Test factor variables in varlist
cap gen pois=rpoisson(5)
xtevent y eta i.pois, panelvar(i) timevar(t) policyvar(z) window(5) plot
cap drop pois
* Test time series variables in varlist

xtevent y l.eta , panelvar(i) timevar(t) policyvar(z) window(5) plot
xtevent y f.eta , panelvar(i) timevar(t) policyvar(z) window(5) plot

* Test asymmetric window
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-4 2) plot

* Test normalizations

xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(-1) plot
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(-2) plot
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(-6) plot
* xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(-7) plot
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(1) plot 
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(5)plot 

graph drop _all

* Test exclusion of unbalanced units with ambiguous eventtime
gen z2 = z
replace z2 = . if i==1 & t==7 
xtevent y eta, policyvar(z2) window(5) 
drop z2

* Test reghdfe
xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(3) reghdfe plot

* Test reghdfe, proxy and absorbing a variable 
gen k=round(x) //generate a categorical variable. Use it as a control 
xtevent y eta, policyvar(z) window(3) proxy(x) nofe note addabsorb(k) reghdfe

*Test additional cluster and robust specifications
xtevent y eta, policyvar(z) window(3) proxy(x) nofe note addabsorb(k) reghdfe robust cluster(i)
*equivalent specification (it admits use of vce)
xtevent y eta, policyvar(z) window(3) proxy(x) nofe note addabsorb(k) reghdfe vce(robust cluster i)

/*
*Test other standar-error specifications (not allowed)
xtevent y eta, policyvar(z) window(3) proxy(x) nofe note addabsorb(k) reghdfe vce(bootstrap) //will show an error message
*/

*Imputation of policyvar without verifying staggered adoption conditions
xtevent y eta, policyvar(z) timevar(t) window(5) impute(nuchange)

*outer imputation of policyvar verifying staggered adoption conditions
xtevent y eta, policyvar(z) timevar(t) window(5) impute(stag)

*outer and inner imputation of policyvar verifying staggered adoption conditions
xtevent y eta, policyvar(z) timevar(t) window(5) impute(instag)

*outer and inner mputation of policyvar. Adds the imputed policyvar to the database
xtevent y eta, policyvar(z) timevar(t) window(5) impute(instag, saveimp)
drop z_imputed

*imputation fails if staggered conditions are not satisfied. It reverts to no imputation
replace z=0.5 in 7
xtevent y eta, policyvar(z) timevar(t) window(5) impute(instag)
replace z=1 in 7

*Trend adjustment. Default method is GMM
xtevent y eta, policyvar(z) timevar(t) window(5) trend(-3)

*Trend adjustment. Use OLS instead
xtevent y eta, policyvar(z) timevar(t) window(5) trend(-3, method(ols))

*Compare: 1) no adjustment; 2) adjustment by GMM and; 3) adjustment by OLS
xtevent y eta, policyvar(z) timevar(t) window(5) 
xteventplot, name(g1)
xtevent y eta, policyvar(z) timevar(t) window(5) trend(-3, method(gmm))
xteventplot, name(g2)
xtevent y eta, policyvar(z) timevar(t) window(5) trend(-3, method(ols))
xteventplot, name(g3)

graph combine g1 g2 g3, rows(2)

graph drop g1
graph drop g2
graph drop g3

graph drop _all

*Overlay trend plot
xtevent y eta, policyvar(z) timevar(t) window(5) trend(-3, method(gmm) saveov)
xteventplot, overlay(trend)

/*
*Overlay trend plot fails because suboption "saveov" was not specified
xtevent y eta, policyvar(z) timevar(t) window(5) trend(-3, method(gmm))
xteventplot, overlay(trend)
*/

* Overlay static plot
xtevent y eta, policyvar(z) timevar(t) window(5)
xteventplot, overlay(static)

* Test graphic options
gen y2 = y - z
xtevent y2 eta, policyvar(z) timevar(t) window(5)
xteventplot, smplotopts(lcolor(green)) smpath(line)
xteventplot, ciplotopts(lcolor(green))
xteventplot, suptciplotopts(lcolor(green))
xteventplot, scatterplotopts(mcolor(green))
xteventplot, overlay(static) staticovplotopts(lcolor(red))

xtevent y2 eta, policyvar(z) timevar(t) window(5) trend(-3, saveov)
xteventplot, overlay(trend) trendplotopts(lcolor(red))
xtevent y eta, policyvar(z) proxy(x) window(5)
xteventplot, overlay(iv) scatterplotopts(mcolor(green red))
drop y2

*------------------------ 2.2: Replicate 2b and test basic funcionality without controls ----------------------------------

xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) plot

* Testing xtset options

xtevent y , policyvar(z) window(5) plot
xtevent y , policyvar(z) panelvar(i) window(5) plot
xtevent y , policyvar(z) timevar(t) window(5) plot


/* Must fail
xtevent y eta, policyvar(z) panelvar(z) window(5) 
xtevent y eta, policyvar(z) timevar(z) window(5) 
*/

* Testing noci, nosupt, nozeroline, nominus1label
xtevent y , policyvar(z) timevar(t) window(5)
xteventplot, noci
xtevent y , policyvar(z) timevar(t) window(5)
xteventplot, nosupt
xtevent y , policyvar(z) timevar(t) window(5)
xteventplot, nozeroline
xtevent y , policyvar(z) timevar(t) window(5)
xteventplot, nominus1label



* Test if/in
xtevent y if i<100, panelvar(i) timevar(t) policyvar(z) window(5) plot
xtevent y in 1/600 , panelvar(i) timevar(t) policyvar(z) window(5) plot
xtevent y in 1/600 if i<30 , panelvar(i) timevar(t) policyvar(z) window(5) plot

* Test nofe, note
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) nofe plot
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) nofe note plot

* Test smoothest line
xtevent y , panelvar(i) timevar(t) policyvar(z) window(3) 
xteventplot, smpath(scatter)
xteventplot, smpath(line)
/* maximum order allowed is 10
xteventplot, smpath(line, maxorder(25))
xteventplot, smpath(line, maxorder(30))
*/
xteventplot, smpath(line, technique("nr 10 bfgs 10"))


* Test more suptreps

cap graph drop g1
cap graph drop g2

xtevent y, panelvar(i) timevar(t) policyvar(z) window(3) 
xteventplot, suptreps(20) name(g1)
xteventplot, suptreps(1e6) name(g2)

graph combine g1 g2, rows(1)

graph drop g1
graph drop g2

* Test savek
xtevent y, panelvar(i) timevar(t) policyvar(z) window(5) savek(a)
des a_eq*, s
des a_evtime, s
drop a*

* Test factor variables in varlist
cap gen pois=rpoisson(5)
xtevent y i.pois, panelvar(i) timevar(t) policyvar(z) window(5) plot
cap drop pois

* Test asymmetric window
xtevent y , panelvar(i) timevar(t) policyvar(z) window(-4 2) plot

* Test normalizations

xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) norm(-1) plot
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) norm(-2) plot
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) norm(-6) plot
* xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) norm(-7) plot
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) norm(1) plot 
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) norm(5) plot 

graph drop _all

* Test exclusion of unbalanced units with ambiguous eventtime
gen z2 = z
replace z2 = . if i==1 & t==7 
xtevent y , policyvar(z2) window(5) 
drop z2

* Overlay static plot
xtevent y , policyvar(z) timevar(t) window(5)
xteventplot, overlay(static) 

*------------------------ 2.3: Replicate 2c  ----------------------------------

* Replicate 2c
xtevent y x , panelvar(i) timevar(t) policyvar(z) window(5) plot

* areg y x _k_eq* i.t , absorb(i) cluster(i)

*------------------------ 2.4: Replicate 2d and test basic funcionality  ----------------------------------

* Replicate 2d
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) plot

* Test alternative ways of specifying iv
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) proxyiv(1) plot
xteventplot, smpath(scatter)
/*
* This should not work now, for leads write 1
cap gen f1z=f1.z
cap noi xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) proxyiv(f1z)
cap drop f1z
*/

* Other leads
xtevent y , panelvar(i) timevar(t) policyvar(z) window(4) proxy(x) proxyiv(2) plot
xteventplot, smpath(scatter)
xtevent y , panelvar(i) timevar(t) policyvar(z) window(4) proxy(x) proxyiv(3) plot
xteventplot, smpath(scatter)

* Test additional instruments

xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) proxyiv(1 2) plot
xteventplot, smpath(scatter, technique("nr 10 bfgs 10"))
xtevent y , panelvar(i) timevar(t) policyvar(z) window(4) proxy(x) proxyiv(3 4) plot
xteventplot, smpath(scatter, technique("nr 10 bfgs 10"))

* Test both normalizations
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) norm(-3) proxy(x) proxyiv(1) plot

* Test additional proxys
cap gen x2=rnormal()
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x x2) proxyiv(1 2) plot
* Must fail
* xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x x2) proxyiv(1)
cap drop x2

* Testing xtset options

xtevent y , policyvar(z) window(5) proxy(x) plot
xteventplot, levels(90 95 99)
xtevent y , policyvar(z) panelvar(i) window(5)  proxy(x)
xtevent y , policyvar(z) timevar(t) window(5)  proxy(x)

/* Must fail
xtevent y , policyvar(z) panelvar(z) window(5) proxy(x)
xtevent y , policyvar(z) timevar(z) window(5) proxy(x)
*/

* Testing noci, nosupt, nozeroline, nominus1label
xtevent y , policyvar(z) timevar(t) window(5) proxy(x)
xteventplot, nosupt
xteventplot, noci
xteventplot, nozeroline
xteventplot, nominus1label

* Test if/in
xtevent y if i<100, panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) plot
xtevent y in 1/600 , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) plot
xtevent y in 1/600 if i<30 , panelvar(i) timevar(t) policyvar(z) window(5) proxy(x) plot

* Test nofe, note
xtevent y, panelvar(i) timevar(t) policyvar(z) window(5) nofe proxy(x)

* Note: Warning for the omitted time dummy comes from ivregress 2sls

xtevent y, panelvar(i) timevar(t) policyvar(z) window(5) nofe note proxy(x)

* Test savek
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) savek(a) proxy(x)
des a_eq*, s
des a_evtime, s
drop a_*


* Test factor variables in varlist
cap gen pois=rpoisson(5)
xtevent y i.pois, panelvar(i) timevar(t) policyvar(z) window(5) proxy(x)
cap drop pois

* Test asymmetric window
xtevent y , panelvar(i) timevar(t) policyvar(z) window(-4 2) proxy(x) plot
xtevent y , panelvar(i) timevar(t) policyvar(z) window(-2 2) proxy(x) plot

* Test overlay plots
graph drop _all
	
xteventplot, y
xteventplot, proxy
xteventplot, overlay(iv)
xteventplot
xteventplot, overlay(static)





*------------------------ 2.5: Replicate 2e and test basic funcionality  ----------------------------------

* Replicate 2e
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) trend(-3, saveov) plot

* Test overlay plot
xteventplot, overlay(trend)


/* Must fail
xtevent y eta, policyvar(z) panelvar(z) window(5) trend(-3 5)
xtevent y eta, policyvar(z) timevar(z) window(5) trend(-3 5)
*/

* Testing noci, nosupt, nozeroline, nominus1label
xteventplot, noci
xteventplot, nosupt
xteventplot, nozeroline
xteventplot, nominus1label

* Must fail
* xtevent y eta if i<100, panelvar(i) timevar(t) policyvar(z) window(5) trend(-8 5)


* Test nofe, note
xtevent y, panelvar(i) timevar(t) policyvar(z) window(5) nofe trend(-3) plot
xtevent y, panelvar(i) timevar(t) policyvar(z) window(5) nofe note trend(-3) plot

* Test savek
xtevent y, panelvar(i) timevar(t) policyvar(z) window(5) savek(a) trend(-3)
des a_eq*, s
des a_evtime, s
drop a_*

* Test factor variables in varlist
cap gen pois=rpoisson(5)
xtevent y i.pois, panelvar(i) timevar(t) policyvar(z) window(5) trend(-3)
cap drop pois
* Test time series variables in varlist

xtevent y l.eta , panelvar(i) timevar(t) policyvar(z) window(5) trend(-3)

* Test asymmetric window
* Must fail
* xtevent y eta , panelvar(i) timevar(t) policyvar(z) window(-4 2) trend(-3 5)
xtevent y , panelvar(i) timevar(t) policyvar(z) window(-4 6) trend(-3) plot

* Test overlay plot
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) trend(-3, saveov) plot
xteventplot, overlay(trend)

*------------------------ 2.6: Hypotheses tests  ----------------------------------

xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(3)

xteventtest, coefs(1 2)
xteventtest, coefs(1 2) cumul
xteventtest, coefs(-2 -3) 
xteventtest, allpre
xteventtest, allpre cumul
xteventtest, allpost
xteventtest, allpost cumul
xteventtest, coefs(1 2) testopts(coef)
xteventtest, linpretrend
xteventtest, overidpre(2)
xteventtest, overidpost(3)
xteventtest, overid

cap log close

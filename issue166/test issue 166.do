clear all 
cap log close  
log using "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\166\test issue 166.txt", replace text 

******* test issue 166

*Setup
webuse nlswork, clear
*year variable has many missing observations.
*Create a time variable that ignores these gaps.
by idcode (year): gen time=_n
xtset idcode time
*Generate a policy variable that follows staggered adoption.
by idcode (time): gen union2 = sum(union)
replace union2 = 1 if union2 > 1


******** default estimation (no trend adjustment)
qui xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(-5 9) cluster(idcode) impute(stag)
xteventplot //overid tests are added by default

xteventtest, coefs(1 2)
xteventtest, allpre 
xteventtest, allpost 
xteventtest, constanteff 
xteventtest, overid 
xteventtest, overidpre(2) 
xteventtest, overidpost(2) 

********* Adjust the pre-trend by estimating a linear trend by OLS & window option
qui xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(-5 9) cluster(idcode) impute(stag) trend(-3, method(ols) saveoverlay) 
xteventplot 
xteventplot, overlay(trend) 

xteventtest, coefs(1 2)
xteventtest, allpre //-6 should not be considered 
xteventtest, allpost // 10 should not be considered
xteventtest, constanteff // 10 should not be considered
xteventtest, overid // -6 and 10 should not be considered
xteventtest, overidpre(2) // -6 should not be considered
xteventtest, overidpost(2) // 10 should not be considered

******* Adjust the pre-trend by estimating a linear trend by GMM & window option
qui xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(-5 9) cluster(idcode) impute(stag) trend(-3, method(gmm) saveoverlay) 
xteventplot 

xteventtest, coefs(1 2)
xteventtest, allpre  
xteventtest, allpost 
xteventtest, constanteff 
xteventtest, overid 
xteventtest, overidpre(2) 
xteventtest, overidpost(2) 

************ pre,post, overidpre, overidpost 
qui xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) overidpre(5) pre(0) post(8) overidpost(2) cluster(idcode) impute(stag) trend(-3, method(ols) saveoverlay) 

xteventtest, coefs(1 2)
xteventtest, allpre  
xteventtest, allpost 
xteventtest, constanteff 
xteventtest, overid // since overidpre(5) it will try to test the first 5 coefficients for the pre-trend test. It  inherits from xtevent the value for overidpre
xteventtest, overidpre(2) 
xteventtest, overidpost(2) 
cap noisily xteventtest, overidpre(4) 

************ pre,post, overidpre, overidpost (xteventtest's expected error)
qui xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) overidpre(5) pre(0) post(8) overidpost(2) cluster(idcode) impute(stag) trend(-5, method(ols) saveoverlay) 
*expected error
cap noisily xteventtest, overid

****** savek 
cap drop myvars*
qui xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(-5 9) cluster(idcode) impute(stag) trend(-3, method(ols) saveoverlay) savek(myvars)

xteventtest, coefs(1 2)
xteventtest, allpre  
xteventtest, allpost 
xteventtest, constanteff 
xteventtest, overid 
xteventtest, overidpre(2) 
xteventtest, overidpost(2)

log close 

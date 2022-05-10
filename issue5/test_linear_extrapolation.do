* Test pretrends extrapolation

clear all

cd "\\bmstginveco\J16339\pretrends\libold\test"

/*=========================================================================
                        1: Load data 
===========================================================================*/	
use "example31.dta", clear

keep if inrange(t,6,15)

/*=========================================================================
                        2: Run tests
===========================================================================*/
	
graph drop _all

*------------------------ 2.1: Replicate 2a and test basic funcionality ----------------------------------

/*
egen y2 = std(y)
replace y= y2

egen z2 = std(z)
replace z = z2
*/

glo trend = -3
scalar trend = $trend

xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) impute(nuchange)
* delta : event-time coefficients
* Omega : variance matrix of event-time coefficients
* deltaL: event-time coefficients for k negative
* OmegaL: variace matrix of event-time coefficients for k negative
* psi: 	  other coefficients
* Omegapsi: variance matrix of other coefficients
* Omegadeltapsi: covariance between event-time coefficients and other coefficients
* V: overall coefficients variance matrix

* Get delta_L and omega_L
est sto xtevent
mat delta=e(delta)
loc start = "_k_eq_m`=abs($trend)'"
mat deltaL = delta[1,"`start'".."_k_eq_m2"]
* Get entire coef vector
mat b = e(b)
* Need to add a 0 for the normalized coefficient
mat deltaL = [deltaL,0]
mat deltaL = deltaL'

* If I were to fit a line to the deltas here, phi would be...
svmat deltaL
reg deltaL t if deltaL!=.
* This is an unweighted estimate

est restore xtevent
mat Omega=e(Vdelta)
mat V = e(V)
mat OmegaL = Omega["`start'".."_k_eq_m2","`start'".."_k_eq_m2"]
mat li OmegaL

* Add a row and col of 0s to OmegaL, for the normalized coefficient
mat OmegaL = [OmegaL,J(`=abs($trend)-1',1,0)]
mat li OmegaL
mat OmegaL = (OmegaL\J(1,`=abs($trend)',0))
mat li OmegaL

mat delta = delta'

* Get vector of other coefficients, and their variance

loc deltanames : colnames(e(delta))
loc deltanames1: word 1 of `deltanames'
loc deltanamesw: word count `deltanames'
loc deltanamesl: word `deltanamesw' of `deltanames'
loc Vnames : colnames(e(V))
loc psinames: list Vnames - deltanames
loc psinames1 : word 1 of `psinames'
mat psi = b[1,"`psinames1'"...]
mat Omegapsi = V["`psinames1'"...,"`psinames1'"...]
mat li Omegapsi
mat Omegadeltapsi = V["`deltanames1'".."`deltanamesl'","`psinames1'"...]
mat li Omegadeltapsi


* Proceed in mata
mata
trend = st_numscalar("trend")
deltaL = st_matrix("deltaL")
Omega = st_matrix("Omega")
OmegaL = st_matrix("OmegaL")
delta = st_matrix("delta")
Omegapsi = st_matrix("Omegapsi")
Omegadeltapsi = st_matrix("Omegadeltapsi")

/* HL is trend matrix for pre-event coefficients */

/* Build HL */
/* Linear */
HL = range($trend+1,0,1)
/* Quadratic */
/* HL = range($trend+1,0,1) */
/* HL = (H,H:^2) */
/* Can generalize to any power, as long as it's below number of coefs */
/* W weighting matrix. For efficient GMM, W is inverse of OmegaL */
/* W=I(abs(trend)) */
W= invsym(OmegaL)
/* Solve for phi_hat */
Vphi_hat = invsym(HL'*W*HL)
LambdaL = Vphi_hat*HL'*W
phi_hat = LambdaL*deltaL

/* Get adjusted delta */
/* H is trend matrix for the entire event-time path */
H= (range(-5,-1,1)\range(1,7,1))
/* delta_star adjusted coefficients */
delta_star = delta - H*phi_hat

/* Get variance of the adjusted deltas */

Lambda = (J(rows(phi_hat),1,0),LambdaL,J(rows(phi_hat),rows(delta)-1-cols(LambdaL),0))
Vdelta_star = Omega - H*Lambda*Omega - Omega'*Lambda'*H' + H*Lambda*Omega*Lambda'*H'

/* Get variance of entire adjusted vector. Other coefs do not change but their covariance with delta does */

V_star11 = (I(rows(delta)) - H*Lambda)* Omega * (I(rows(delta)) - Lambda'*H')
V_star12 = (I(rows(delta)) - H*Lambda) * Omegadeltapsi
V_star21 = Omegadeltapsi' * (I(rows(delta)) - Lambda'*H') 
V_star22 = Omegapsi

V_star = (V_star11,V_star12\V_star21,V_star22)
/* Average to kill eps errors */
V_star = 0.5*(V_star + V_star')

/*
phi_hat
Vphi_hat
delta_star
*/

end


xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) trend($trend)
* list phi, variance and adjusted delta
di _b[_ttrend]
di _se[_ttrend]^2
mat delta_star = e(delta)'
mat li delta_star

mata

/* List phi and its variance */
phi_hat
Vphi_hat
delta_star

end

mata 

delta_starreg=st_matrix("delta_star")
delta_starreg = delta_starreg[1+5+trend,1] \ J(abs(trend)-1,1,0) \ delta_starreg[|2,1 \ .,1 |]
delta_star 
delta_starreg
delta_star - delta_starreg
end 

* How to repost the trend adjustment
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5)
mat b= e(b)
mata: st_matrix("delta_star",delta_star')
mata: st_matrix("V_star",V_star)
loc namesdelta : colnames(e(delta))
mat colnames delta_star = `namesdelta'
loc namesb : colnames(b)
mat colnames V_star = `namesb'
mat rownames V_star = `namesb'
mat b_star = b
mat V = e(V)
foreach i in `namesdelta' {
	mat b_star[1,colnumb("b","`i'")]= delta_star[1,"`i'"]	
}
/*
foreach i in `names' {
	foreach j in `names' {
		mat V_star [rownumb("V_star","`j'"),colnumb("V_star","`i'")]= Vdelta_star["`j'","`i'"]	
	}
}
*/

/*
b=st_matrix("b")
b_star = (delta_star' , b[|1,rows(delta_star)+1 \ 1,.|])
st_matrix("b_star",b_star)
*/


cap program drop repostdelta
program define repostdelta, eclass
	ereturn repost b=b_star V=V_star
end
repostdelta
est store xteventadj
xtevent y , panelvar(i) timevar(t) policyvar(z) window(5) trend($trend) impute(nuchange)
est store xteventlintrend

est tab xtevent xteventadj xteventlintrend, se



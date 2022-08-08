/*===========================================================================
project:      pretrends
Author:       Jorge Perez
Program Name: Example31SimulateData.do
Dependencies: Banxico
---------------------------------------------------------------------------
Creation Date:      May 3rd, 2019
Modification Date:    
version:            1  
References:     
---------------------------------------------------------------------------
Simulates data for example 31 in FHS
Inputs: Simulation parameters seed,N,T,rho,lambda,beta,eta_star,var_zeta,sd_zeta,var_u,sd_u,
Outputs: Dataset 


---------------------------------------------------------------------------
Change log:
				
	
===========================================================================*/


/*=========================================================================
                        Project calls
===========================================================================*/

version 15.1
cap project, doinfo
if _rc==198 {
	loc pr=0
	loc master "T:\pretrends"
}
else {
	loc master "`r(pdir)'"
	loc doname "`r(dofile)'"
	loc pr=1	
}	

loc pr=0
*loc master "T:\pretrends" //original directory
loc master "C:/Users/tino_/Dropbox/PC/Documents/xtevent/issues/59/5_august"

/*=========================================================================
                        1: Simulate data
===========================================================================*/


clear all

set seed 94564510

*original:
*glo N = 1000 // Number of cross-sectional units
*changed to:
glo N = 30000 // Number of cross-sectional units
glo T =  20 // Number of time periods

* Coefficients

glo rho = 1
glo lambda = 1
glo beta = 1
glo eta_star = 4

* Variances
glo var_zeta = 1
glo sd_zeta = sqrt(${var_zeta})
glo var_u = 4
glo sd_u = sqrt(${var_u})

set obs $N
gen i=_n
* Fixed effects
gen alpha = rnormal(0,1)
expand $T
bys i: gen t=_n
xtset i t
sort i t

* Variables
glo var_zeta = 1
gen zeta = rnormal(0,${sd_zeta})

gen eta = 0
replace eta = ${rho}*l.eta + zeta if t>=2

gen u = rnormal(0,${sd_u})

gen x = ${lambda}*eta + u

gen z = (eta > ${eta_star})
bys i: replace z = sum(z)
replace z = (z>0)

gen e = rnormal(0,1)

gen y = ${beta}*z + 0.25*eta + 0.2*t + alpha + e

/*=========================================================================
                        2: Save dataset
===========================================================================*/
cap mkdir "`master'/lib/test"
save "`master'/lib/test/example31_large.dta", replace

/*=========================================================================
                        3: Project calls
===========================================================================*/

if `pr' project, creates("`master'/lib/test/example31_large.dta")


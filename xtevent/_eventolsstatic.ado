* _eventolsstatic.ado 1.00 Aug 24 2021

version 11.2

cap program drop _eventolsstatic
program define _eventolsstatic, rclass

	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Proxy for eta and covariates go in varlist. Can add fv ts later */
	panelvar(varname) /* Panel variable */
	timevar(varname) /* Time variable */
	policyvar(varname) /* Policy variable */	
	[
	nofe /* No fixed effects */
	note /* No time effects */	
	reghdfe /* Use reghdfe for estimation */
	absorb(string) /* Absorb additional variables in reghdfe */ 
	impute(string) /*impute policyvar */
	STatic /* Estimate static model */
	*
	]
	;
	#d cr
	
	marksample touse
	
	tempname delta Vdelta bb VV bb2 VV2 delta2 Vdelta2
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"
	
	*call _eventgenvars to impute z
	if "`impute'"!="" {
	_eventgenvars if `touse', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') impute(`impute') `static'
	loc z="`policyvar'_imputed"
	}
	
	* Main regression
	
	if "`te'" == "note" loc te ""
	else loc te "i.`t'"
	
	if "`reghdfe'"=="" {
		if "`fe'" == "nofe" {
		loc absorb ""
		loc cmd "reg"
		}
		else {
			loc absorb "absorb(`i')"
			loc cmd "areg"
		}
		`cmd' `varlist' `z' `te' [`weight'`exp'] if `touse', `absorb' `options'
	}
	else {
		loc noabsorb ""
		*absorb nothing
		if "`fe'" == "nofe" & "`te'"=="" & "`absorb'"=="" {
			loc noabsorb "noabsorb"
			loc abs ""
		}
		*absorb only one
		else if "`fe'" == "nofe" & "`te'"=="" & "`absorb'"!="" {
			loc abs "absorb(`absorb')"
		}
		else if "`fe'" == "nofe" & "`te'"!="" & "`absorb'"=="" {						
			loc abs "absorb(`t')"
		}
		else if "`fe'" != "nofe" & "`te'"=="" & "`absorb'"=="" {						
			loc abs "absorb(`i')"
		}
		*absorb two
		else if "`fe'" == "nofe" & "`te'"!="" & "`absorb'"!="" {						
			loc abs "absorb(`t' `absorb')"
		}
		else if "`fe'" != "nofe" & "`te'"=="" & "`absorb'"!="" {						
			loc abs "absorb(`i' `absorb')"
		}
		else if "`fe'" != "nofe" & "`te'"!="" & "`absorb'"=="" {						
			loc abs "absorb(`i' `t')"
		}
		*absorb three
		else if "`fe'" != "nofe" & "`te'"!="" & "`absorb'"!="" {						
			loc abs "absorb(`i' `t' `absorb')"
		}
		*
		else {
			loc abs "absorb(`i' `t' `absorb')"	
		}
		reghdfe `varlist' `z' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
	}
	
	mat `bb' = e(b)
	mat `VV' = e(V)
	mat `delta'=e(b)
	mat `Vdelta'=e(V)
	
	tokenize `varlist'
	loc depvar "`1'"
	
	return matrix b = `bb'
	return matrix V = `VV'
	return matrix delta=`delta'
	return matrix Vdelta = `Vdelta'
	return local cmd = "`cmd'"
	return local depvar = "`depvar'"
	
end


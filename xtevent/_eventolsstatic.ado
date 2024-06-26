version 13

program define _eventolsstatic, rclass

	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Proxy for eta and covariates go in varlist. Can add fv ts later */
	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */
	POLicyvar(varname) /* Policy variable */	
	[
	nofe /* No fixed effects */
	note /* No time effects */	
	reghdfe /* Use reghdfe for estimation */
	addabsorb(string) /* Absorb additional variables in reghdfe */ 
	IMPute(string) /*impute policyvar */
	STatic /* Estimate static model */
	REPeatedcs /*data is repeated cross-sectional*/
	*
	]
	;
	#d cr
	
	marksample touse
	
	tempvar mkvarlist
	qui gen byte `mkvarlist' = `touse'
	
	tempname delta Vdelta bb VV bb2 VV2 delta2 Vdelta2 tousegen
	
	* For eventgenvars, ignore missings in varlist
	mark `tousegen' `if' `in'	
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"
	
	*call _eventgenvars to impute z
	if "`impute'"!="" {
		*tempvar to be imputed
		tempvar rr
		qui gen double `rr'=.

	_eventgenvars if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') impute(`impute') `repeatedcs' `static' rr(`rr') mkvarlist(`mkvarlist')
	
		loc impute=r(impute)
		if "`impute'"=="." loc impute = ""
		loc saveimp=r(saveimp)
		if "`saveimp'"=="." loc saveimp = ""
		*if imputation succeeded:
		if "`impute'"!="" {
			if "`saveimp'"=="" {
				cap confirm variable `policyvar'_imputed
				if !_rc {
					di as err _n "`policyvar'_imputed already exists. Please rename it or delete it before proceeding."
					exit 110
				}
				gen `policyvar'_imputed = `rr'			
			}			
			loc z = "`policyvar'_imputed"			
			else 
		}
		else loc z = "`policyvar'"
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
		if "`fe'" == "nofe" & "`te'"=="" & "`addabsorb'"=="" {
			loc noabsorb "noabsorb"
			loc abs ""
		}
		*absorb only one
		else if "`fe'" == "nofe" & "`te'"=="" & "`addabsorb'"!="" {
			loc abs "absorb(`addabsorb')"
		}
		else if "`fe'" == "nofe" & "`te'"!="" & "`addabsorb'"=="" {						
			loc abs "absorb(`t')"
		}
		else if "`fe'" != "nofe" & "`te'"=="" & "`addabsorb'"=="" {						
			loc abs "absorb(`i')"
		}
		*absorb two
		else if "`fe'" == "nofe" & "`te'"!="" & "`addabsorb'"!="" {						
			loc abs "absorb(`t' `addabsorb')"
		}
		else if "`fe'" != "nofe" & "`te'"=="" & "`addabsorb'"!="" {						
			loc abs "absorb(`i' `addabsorb')"
		}
		else if "`fe'" != "nofe" & "`te'"!="" & "`addabsorb'"=="" {						
			loc abs "absorb(`i' `t')"
		}
		*absorb three
		else if "`fe'" != "nofe" & "`te'"!="" & "`addabsorb'"!="" {						
			loc abs "absorb(`i' `t' `addabsorb')"
		}
		*
		else {
			loc abs "absorb(`i' `t' `addabsorb')"	
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
	
	if "`impute'"!="" & "`saveimp'"=="" drop `policyvar'_imputed
	
end


* _eventivstatic.ado 1.00 Aug 24 2021

version 11.2

cap program drop _eventivstatic
program define _eventivstatic, rclass
	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Covariates go in varlist. Can add fv ts later */
	panelvar(varname) /* Panel variable */
	timevar(varname) /* Time variable */
	policyvar(varname) /* Policy variable */	
	proxy (varlist numeric) /* Proxy variable(s) */
	[
	proxyiv(string) /* Instruments. Either numlist with lags or varlist with names of instrumental variables */
	nofe /* No fixed effects */
	note /* No time effects */	
	reghdfe /* Use reghdfe for estimation */
	absorb(string) /* Absorb additional variables in reghdfe */ 
	impute(string)
	STatic
	*
	]
	;
	#d cr
	
	marksample touse
	
	tempvar kg
	* kg grouped event time, grouping outside window
	
	tempname delta Vdelta bb VV bb2 VV2 delta2 Vdelta2 deltay Vdeltay deltax Vdeltax deltaxsc bby bbx VVy VVx 
	* bb delta coefficients
	* VV variance of delta coefficients
	* bb2 delta coefficients for overlay plot
	* VV2 variance of delta coefficients for overlay plot
	* delta2 included cefficientes in overlaty plot
	* VVdelta2 variance of included delta coefficients in overlay plot
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"
	
	loc leads : word count `proxy'
	if "`proxyiv'"=="" & `leads'==1 loc proxyiv "select"
	
	* If proxy specified but no proxyiv, assume numlist for leads of policyvar
	if "`proxyiv'"=="" {
		di _n "No proxy instruments specified. Using leads of policy variables as instruments."
		loc leads : word count `proxy'		
		forv j=1(1)`leads' {
			loc proxyiv "`proxyiv' `j'"
		}
	}
	
	* IV selection if proxyiv = selection
	else if "`proxyiv'"=="select" {
		* Only for one proxy case 		
		if `leads'>1 {
			di as err "Proxy instrument selection only available for the one proxy - one instrument case"
			exit 301
		}
		else {
			di as text _n "proxyiv=select. Selecting lead order of differenced policy variable to use as instrument."
			loc Fstart = 0
			* Here I test up to 5
			forv v=1(1)5 {
				tempvar _fd`v'`z'
				qui gen `_fd`v'`z'' = f`v'.d.`z' if `touse'
				cap qui reg `proxy' `_fd`v'`z'' [`weight'`exp'] if `touse'
				if !_rc loc Floop = e(F)
				if `Floop' > `Fstart' {
					loc Fstart = `Floop'
					loc proxyiv "`v'"				
				}			
			}
			di as text _n "Lead `proxyiv' selected."
		}
		
	}
	
	* Parse proxyiv and generate leads if neccesary
	loc rc=0
	foreach v in `proxyiv' {
		cap confirm integer number `v'
		loc rc = `rc' + _rc
	}
	* If numlist take as leads of z
	if `rc' == 0 {
		loc insvars ""
		foreach v in `proxyiv' {
			qui gen _f`v'`z' = f`v'.`z' if `touse'
			loc insvars "`insvars' _f`v'z"
		}
		loc instype = "numlist"
	}
	else {
		foreach v in `proxyiv' {
			confirm numeric variable `v'
		}
		loc insvars = "`proxyiv'"
	}
	
	*call _eventgenvars to impute z
	_eventgenvars if `touse', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') impute(`impute') `static'
	
		
	* Main regression
	
	if "`impute'"!="" {
		loc zreg="`policyvar'_imputed"
	}
	else {
		loc zreg="`z'"
	}
	
	if "`reghdfe'"=="" {
		if "`fe'" == "nofe" {
		loc cmd "ivregress 2sls"
		loc ffe ""
		}
		else {
			loc cmd "xtivreg"
			loc ffe "fe"
		}
		`cmd' `varlist' (`proxy' = `insvars') `zreg' `tte' [`weight'`exp'] if `touse' , `ffe' `options'
	}
	else {
		loc cmd "reghdfe"
		if "`fe'" == "nofe" & "`te'"=="" & "`absorb'"=="" {						
			loc noabsorb "noabsorb"
			loc abs ""
		}
		else if "`fe'" == "nofe" & "`te'"=="" & "`absorb'"!="" {						
			loc noabsorb "noabsorb"
			loc abs "absorb(`absorb')"
		}
		else if "`fe'" == "nofe" & "`te'"!=""{
			loc abs "absorb(`te' `absorb')"	
			loc noabsorb ""
		}
		else if "`fe'" != "nofe" & "`te'"==""{
			loc abs "absorb(`i' `absorb')"	
			loc noabsorb ""
		}
		else {
			loc abs "absorb(`i' `te' `absorb')"	
			loc noabsorb ""
		}
		ivreghdfe `varlist' (`proxy' = `insvars') `zreg' [`weight'`exp'] if `touse', `absorb' `noabsorb' `options'
	}
	
	
	
	
	if "`te'" == "note" loc tte ""
	else loc tte "i.`t'"
	
	mat `bb' = e(b)
	mat `VV' = e(V)
	mat `delta'=e(b)
	mat `Vdelta'=e(V)	
	
	* Drop variables
	
	if "`instype'"=="numlist" {
		foreach v in `proxyiv' {
			drop _f`v'`z' 
		}
	}
	
	tokenize `varlist'
	loc depvar "`1'"
	
	return matrix b = `bb'
	return matrix V = `VV'
	return matrix delta = `delta'
	return matrix Vdelta = `Vdelta'
	loc names: subinstr global names ".." " ", all
	loc names: subinstr local names `"""' "", all
	return local names = "`names'"	
	return local cmd = "`cmd'"
	return local depvar = "`depvar'"
		
end

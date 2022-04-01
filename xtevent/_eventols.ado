* _eventols.ado 1.00 Aug 24 2021

version 11.2

cap program drop _eventols
program define _eventols, rclass
	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Proxy for eta and covariates go in varlist. Can add fv ts later */
	panelvar(varname) /* Panel variable */
	timevar(varname) /* Time variable */
	policyvar(varname) /* Policy variable */
	lwindow(integer) /* Estimation window. Need to set a default, but it has to be based on the dataset */
	rwindow(integer) /* Estimation window. Need to set a default, but it has to be based on the dataset */
	[
	nofe /* No fixed effects */
	note /* No time effects */
	trend(numlist integer ascending min=1 max=1) /* trend(a b) Include a linear trend from time a to time b*/
	gmmtrend(numlist integer ascending min=1 max=1) /* Trend estimated by GMM */
	savek(string) /* Generate the time-to-event dummies, trend and keep them in the dataset */					
	nogen /* Do not generate k variables */
	kvars(string) /* Stub for event dummies to include, if they have been generated already */				
	nodrop /* Do not drop _k variables */
	norm(integer -1) /* Coefficiente to normalize */
	reghdfe /* Use reghdfe for estimation */	
	*nostaggered /* Calculate endpoints without absorbing policy assumption, requires z */
	stag /* impute outer missing values in policyvar if staggered assumptions hold */
	nuchange /* Impute outside missing values in policyvar */ 
	instag 
	absorb(string) /* Absorb additional variables in reghdfe */ 
	*
	]
	;
	#d cr
	
	marksample touse
		
	tempname delta Vdelta bb VV
	* delta - event coefficients
	* bb - regression coefficients
	tempvar esample
	
	
	
	if "`trend'"!="" {
		tempvar ktrend trendy trendx
		
		if `trend'>=0 {
			di as err "trend must be smaller than 0"
			exit 301
		}
		
		if `trend'==-1 {
			di as err "Trend extrapolation requires at least two pre-treatment points."
			exit 301
		}
				
		loc ttrend "_ttrend"				
	}
	
	if ("`gen'"!="" & "`kvars'"=="") |  ("`gen'"=="" & "`kvars'"!="") {
		di as err _n "Options -nogen- and -kvars- must be specified together"
		exit 301
	}
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"
	
	if "`gen'" != "nogen" {
		_eventgenvars if `touse', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') trend(`trend') norm(`norm') `stag' `nuchange' `instag'
		loc included=r(included)
		loc names=r(names)
		loc komittrend=r(komittrend)
		loc bin = r(bin)
		if "`komittrend'"=="." loc komittrend = ""
	}
	else {
		loc kvstub "`kvars'"		
		loc j=1
		loc names ""
		loc included ""
		foreach var of varlist `kvstub'* {	
			if `norm' < 0 loc kvomit = "m`=abs(`norm')'"
			else loc kvomit "p`=abs(`norm')'"
			if "`var'"=="`kvstub'_evtime" | "`var'" == "`kvstub'_eq_`kvomit'" continue	
			if "`kvstub'"!="_k" {
				loc sub : subinstr local var "`kvstub'" "_k", all
				qui clonevar `sub' = `var'
			}
			else {
				loc sub = "`var'"
			}
			if `j'==1 loc names `""`sub'""'
			else loc names `"`names'.."`sub'""'
			* "
			loc included "`included' `sub'"
			loc ++ j			
		}		
	}	
	loc komit "`norm'`komittrend'"
	loc komit = strtrim("`komit'")
	
	
	* Main regression
	
	
	if "`te'" == "note" loc te ""
	else loc te "i.`t'"
	
	* If gmm trend run regression before adjustment quietly
	if "`gmmtrend'"!="" loc q "quietly" 
	else loc q ""
		
	if "`reghdfe'"=="" {
		if "`fe'" == "nofe" {
			loc abs ""
			loc cmd "regress"
		}
		else {
			loc abs "absorb(`i')"
			loc cmd "areg"
		}
		`q' `cmd' `varlist' `included' `te' `ttrend' [`weight'`exp'] if `touse', `abs' `options'
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
		`q' reghdfe `varlist' `included' `ttrend' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
	}
	
	* Return coefficients and variance matrix of the delta k estimates separately
	mat `bb'=e(b)
	mat `VV'=e(V)
	mat `delta' = `bb'[1,`names']
	mat `Vdelta' = `VV'[`names',`names']	
	
	loc df = e(df_r)
	
	gen byte `esample' = e(sample)
	
	* Trend adjustment by GMM
	
	if "`gmmtrend'"!="" {
		
		tempname deltatoadj Vtoadj deltaadj Vadj bbadj VVadj
		
		loc gmmtrendsc = `gmmtrend'
		loc start = "_k_eq_m`=abs(`gmmtrend')'"
		* Notice that here I am requiring normalization in -1
		mat `deltatoadj' = `delta'[1,"`start'".."_k_eq_m2"]
		mat `deltatoadj' = [`deltatoadj',0]
		mat `deltatoadj' = `deltatoadj''
		mat `Vtoadj' = `Vdelta'["`start'".."_k_eq_m2","`start'".."_k_eq_m2"]
		mat `Vtoadj' = [`Vtoadj',J(`=abs(`gmmtrend')-1',1,0)]
		mat `Vtoadj' = (`Vtoadj'\J(1,`=abs(`gmmtrend')',0))
		
		mat li `deltatoadj'
		mat li `Vtoadj'
		mat li `delta'
		mat li `Vdelta'
		
		mata: adjdelta(`gmmtrendsc',`lwindow',`rwindow',"`deltatoadj'","`Vdelta'","`Vtoadj'","`delta'","`deltaadj'","`Vadj'")
		
		* Post the new results
		loc dnames : colnames(`delta')
		
		mat colnames `deltaadj' = `dnames'
		mat colnames `Vadj' = `dnames'
		mat rownames `Vadj' = `dnames'
		mat `bbadj' = `bb'
		mat `VVadj' = `VV'
		foreach i in `dnames' {
			mat `bbadj'[1,colnumb("`bb'","`i'")]= `deltaadj'[1,"`i'"]
			foreach j in `dnames' {
				mat `VVadj'[rownumb("`VVadj'","`j'"),colnumb("`VVadj'","`i'")]= `Vadj'["`j'","`i'"]	
			}
		}
		
		repostdelta `bbadj' `VVadj'
		
		`cmd'
	}
	
	
	* Calculate mean before change in policy for 2nd axis in plot
	* This needs to be relative to normalization
	loc absnorm=abs(`norm')
	
	tokenize `varlist'
	loc depvar "`1'"
	qui su `1' if f`absnorm'.d.`policyvar'!=0 & f`absnorm'.d.`policyvar'!=. & `esample', meanonly
	loc y1 = r(mean)	
	
	
	* Variables for overlay plot if trend
	
	if "`trend'"!="" {
		_estimates hold mainols
		unab included2 : _k*
		loc toexc "_k_eq_m1"
		loc included2: list local included2 - toexc
		if "`reghdfe'"== "" {
			qui _regress `varlist' `included2' `te' [`weight'`exp'] if `touse', `abs' `options'
		}
		else {
			qui reghdfe `varlist' `included2' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
		}
		loc j=1
		loc names2 ""
		foreach var in `included2' {
			if `j'==1 loc names2 `""`var'""'
			else loc names2 `"`names2'.."`var'""'
			* "
			loc ++ j
		}
		* Generate the trend to plot
		qui gen double `trendy'=.
		qui gen int `trendx'=.
		loc j=1
		forv c=`trend'(1)-1 {
			loc absc = abs(`c')
			if `c'!=-1 qui replace `trendy'=_b[_k_eq_m`absc'] in `j'
			else if `c'==-1 qui replace `trendy'=0 in `j'
			qui replace `trendx'=`c' in `j'
			loc ++ j
		}		
		tempname bbov VVov deltaov Vdeltaov mattrendy mattrendx 
		mat `bbov'=e(b)
		mat `VVov'=e(V)
		mat `deltaov' = `bbov'[1,`names2']
		mat `Vdeltaov' = `VVov'[`names2',`names2']
		mkmat `trendy', matrix(`mattrendy') nomiss
		mkmat `trendx', matrix(`mattrendx') nomiss 		
		_estimates unhold mainols
	}
	
	
	* Drop variables
	if "`savek'" == "" & "`drop'"!="nodrop" {
		cap confirm var _k_eq_p0
		if !_rc drop _k_eq*		
		cap confirm var __k
		if !_rc qui drop __k
		if "`trend'"!="" qui drop _ttrend
	}
	else if "`savek'" != "" & "`drop'"!="nodrop"  {
		ren __k `savek'_evtime
		ren _k_eq* `savek'_eq*
		if "`trend'"!="" ren _ttrend `savek'_trend	
	}	
	
	* Returns
	
	return matrix b = `bb'
	return matrix V = `VV'
	return matrix delta=`delta'
	return matrix Vdelta = `Vdelta'	
	loc names: subinstr local names ".." " ", all
	loc names: subinstr local names `"""' "", all
	return local names = "`names'"
	return local cmd "`cmd'"
	return local df =  `df'
	return local komit = "`komit'"
	return local kmiss = "`kmiss'"
	return local y1 = `y1'
	return local depvar = "`depvar'"
	if "`trend'"!="" {
		return matrix deltaov = `deltaov'
		return matrix Vdeltaov = `Vdeltaov'
		return matrix mattrendy = `mattrendy'
		return matrix mattrendx = `mattrendx'
		return local trend = "trend"
	}
	return local method = "ols"
end


mata

	void adjdelta( real scalar trend,
					real scalar lwindow,
					real scalar rwindow,
					string scalar getDeltaL,
					string scalar getOmega,
					string scalar getOmegaL,
					string scalar getdelta,
					string scalar deltaadj,
					string scalar Vadj)
	{
	
	real matrix deltaL, Omega, OmegaL, delta, HL, W, Vphi_hat, LambdaL, phi_hat, H, delta_star, Lambda, Vdelta_star
	
	deltaL = st_matrix(getDeltaL)
	Omega = st_matrix(getOmega)
	OmegaL = st_matrix(getOmegaL)
	delta = st_matrix(getdelta)
	delta = delta'
	
	/* Build H_L */
	HL = range(trend+1,0,1)
		
	W= invsym(OmegaL)
	/* Solve for phi_hat */
	
	Vphi_hat = invsym(HL'*W*HL)
	
	LambdaL = Vphi_hat*HL'*W
	
	phi_hat = LambdaL*deltaL
	
	
	/* Get adjusted delta */
	H= (range(lwindow,-1,1)\range(1,rwindow+2,1))
	st_matrix("H",H)
	st_matrix("phi_hat",phi_hat)
	delta_star = delta - H*phi_hat
	
	/* Get variance of the adjusted deltas */

	Lambda = (J(rows(phi_hat),1,0),LambdaL,J(rows(phi_hat),rows(delta)-1-cols(LambdaL),0))
	Vdelta_star = Omega - H*Lambda*Omega - Omega'*Lambda'*H' + H*Lambda*Omega*Lambda'*H'
	
	st_matrix(deltaadj,delta_star')
	st_matrix(Vadj,Vdelta_star)
	
	}
	
end

cap program drop repostdelta
program define repostdelta, eclass
	ereturn repost b=`1' V=`2'
end



version 11.2

cap program drop _eventols
program define _eventols, rclass
	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Proxy for eta and covariates go in varlist. Can add fv ts later */
	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */
	POLicyvar(varname) /* Policy variable */
	LWindow(integer) /* Estimation window. Need to set a default, but it has to be based on the dataset */
	RWindow(integer) /* Estimation window. Need to set a default, but it has to be based on the dataset */
	[
	nofe /* No fixed effects */
	note /* No time effects */
	TRend(string) /* trend(a -1) Include a linear trend from time a to -1. Method can be either GMM or OLS*/
	SAVek(string) /* Generate the time-to-event dummies, trend and keep them in the dataset */					
	nogen /* Do not generate k variables */
	kvars(string) /* Stub for event dummies to include, if they have been generated already */				
	nodrop /* Do not drop _k variables */
	norm(integer -1) /* Coefficiente to normalize */
	reghdfe /* Use reghdfe for estimation */	
	impute(string) /*imputation on policyvar*/
	addabsorb(string) /* Absorb additional variables in reghdfe */
	DIFFavg /* Obtain regular DiD estimate implied by the model */
	cohort(varname) /* categorical variable indicating cohort */
	control_cohort(varname) /* dummy variable indicating the control cohort */
  REPeatedcs /*indicate that the input data is a repeated cross-sectional dataset*/

	*
	]
	;
	#d cr
	
	marksample touse
	
		
	tempname delta Vdelta bb VV
	* delta - event coefficients
	* bb - regression coefficients
	tempvar esample	tousegen
	
	* For eventgenvars, ignore missings in varlist
	mark `tousegen' `if' `in'
	

	**** parsers
	*parse savek 
	if "`savek'"!="" parsesavek `savek'
	foreach ll in savek noestimate saveint{
		loc `ll' = r(`ll'l)
		if "``ll''"=="." loc `ll' ""
		return loc `ll' = "``ll''"
	}
	
	*error messages for incorrect specification of noestimate 
	if "`noestimate'"!="" & "`diffavg'"!="" {
		di as err _n "{bf:noestimate} and {bf: diffavg} not allowed simultaneously"
		exit 301
	}
	if "`noestimate'"!="" & "`trend'"!="" {
		di as err _n "{bf:noestimate} and {bf:trend} not allowed simultaneously"
		exit 301
	}


	*parse trend
	if "`trend'"!="" parsetrend `trend'
	loc trcoef = r(trcoef)
	loc methodt = r(methodt)
	loc saveov = r(saveoverlay)
	if "`saveov'"=="." loc saveov ""
	return loc saveov = "`saveov'"
	
	*error messages for incorrect specification of the trend option
	if "`trend'"!="" {
		tempvar ktrend trendy trendx
		if `trcoef'<`lwindow'-1 | `trcoef'>`rwindow'+1 {
			di as err "{bf:trend} is outside estimation window."
			exit 301
		}
		
		if `trcoef'>=0 {
			di as err "trend coefficient must be smaller than 0"
			exit 301
		}
		if `trcoef'==-1 {
			di as err "Trend extrapolation requires at least two pre-treatment points."
			exit 301
		}			
		if !inlist("`methodt'","ols","gmm"){
			di as err "{bf:method(`methodt')} is not a valid suboption."		
			exit 301
		}
		if "`methodt'"=="ols" {
			loc ttrend "_ttrend"
		}
		else loc ttrend ""
	}
	
	* error messages for sun_abraham
	loc sun_abraham ""
	if "`cohort'"!="" & "`control_cohort'"!="" {
		di as text _n "You have specified {bf:cohort} and {bf:control_cohort} options.
		di as text _n "Event-time coefficients will be estimated with"
		di as text _n "the Interaction Weighted Estimator of Sun and Abraham (2021)."
		loc sun_abraham "sun_abraham"
	}
	if "`saveint'"!="" & "`sun_abraham'"==""{
		di as err _n "Suboption {bf:saveint} can only be specified if options {bf:cohort} and {bf:control_cohort} have been specified as well."
		exit 301
	}
	* Check for vars named _interact
	if "`saveint'"!=""{
		cap unab old_interact_vars : `savek'_interact*
		if !_rc {
			di as err _n "You have variable names with the {bf:`savek'_interact} prefix."
			di as err _n "{bf:`savek'_interact} is reserved for the interaction variables in Sun-and-Abraham estimation."
			di as err _n "Please rename or drop these variables before proceeding."
			exit 110
		}
	}
	*gen & kvars
	if ("`gen'"!="" & "`kvars'"=="") |  ("`gen'"=="" & "`kvars'"!="") {
		di as err _n "Options -nogen- and -kvars- must be specified together"
		exit 301
	}
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"
	
	if "`gen'" != "nogen" {
		if "`impute'"!=""{
			tempvar rr
			qui gen double `rr'=.
		}
	
		_eventgenvars if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') trcoef(`trcoef') methodt(`methodt') norm(`norm') impute(`impute') rr(`rr') `repeatedcs'
		loc included=r(included)
		loc names=r(names)
		loc komittrend=r(komittrend)
		loc bin = r(bin)
		if "`komittrend'"=="." loc komittrend = ""

		*bring the imputed policyvar
		loc impute=r(impute)
		if "`impute'"=="." loc impute = ""
		*if imputation succeeded:
		if "`impute'"!="" {
			tempvar zimp
			qui gen double `zimp'=`rr'
			loc z="`zimp'"
		}
		else loc z = "`policyvar'"
		
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
	
	*split varlist (depvar and independentvars): change variables' order in the regression. Necessary for GMM matrix operations
	loc nvars: word count(`varlist')
	tokenize `varlist'
	loc depenvar `1'
	if `nvars'>1 {
		forval k=2(1)`nvars'{
			loc indepvars "`indepvars' ``k''"
		}
	}
	else loc indepvars ""
		
	******** SA *******
	if "`sun_abraham'"!=""{
		* Parse the dependent variable
		local lhs = "`depenvar'"
		local rel_time_list = "`included'"
		
		* Convert the varlist of relative time indicators to nvarlist 
		local nvarlist "" // copies of relative time indicators with control cohort set to zero
		local dvarlist "" // for display
		foreach l of varlist `rel_time_list' {
			local dvarlist "`dvarlist' `l'"
			tempname n`l'
			qui gen `n`l'' = `l'
			qui replace `n`l'' = 0 if  `control_cohort' == 1 
			local nvarlist "`nvarlist' `n`l''" 
		}	

		* Get cohort count  and count of relative time
		qui levelsof `cohort' if  `control_cohort' == 0, local(cohort_list) 
		local nrel_times: word count `nvarlist' 
		local ncohort: word count `cohort_list'  
		
		**** step 2 
		* Initiate empty matrix for weights 
		tempname bb ff_w
		
		* Loop over cohort and get cohort shares for relative times
		local nresidlist ""
		foreach yy of local cohort_list {
			tempvar cohort_ind resid`yy'
			qui gen `cohort_ind'  = (`cohort' == `yy') 
			qui _regress `cohort_ind' `nvarlist'  if `touse' & `control_cohort' == 0 [`weight'`exp']  , nocons
			mat `bb' = e(b) 
			matrix `ff_w'  = nullmat(`ff_w') \ `bb' 
			*di "`yy'"
			*mat li `ff_w'
			qui predict double `resid`yy'', resid 
			local nresidlist "`nresidlist' `resid`yy''" //list of variables of residuals 
		}
		
		* Get VCV estimate for the cohort shares using avar
		* In case users have not set relative time indicators to zero for control cohort
		* Manually restrict the sample to non-control cohort
		tempname XX Sxx Sxxi S KSxxi Sigma_ff
		qui mat accum `XX' = `nvarlist' if  `touse' & `control_cohort' == 0 [`weight'`exp'], nocons
		mat `Sxx' = `XX'*1/r(N) 
		mat `Sxxi' = syminv(`Sxx') 
		qui avar (`nresidlist') (`nvarlist')  if `touse' & `control_cohort' == 0 [`weight'`exp'], nocons robust
		mat `S' = r(S) 
		mat `KSxxi' = I(`ncohort')#`Sxxi' 
		mat `Sigma_ff' = `KSxxi'*`S'*`KSxxi'*1/r(N) 
		// Note that the normalization is slightly different from the paper
		// The scaling factor is 1/N for N the obs of cross-sectional units
		// But here estimates are on the panel, which is why it is 1/NT instead
		// Should cancel out for balanced panel, but unbalanced panel is a TODO
		// as of Jan 23, 2023, Sun and Abraham have not updated this code section.
		//According to the expression for the asymptotic variance in the proof of proposition 6 (https://arxiv.org/pdf/1804.05785v2.pdf#page=50), the scaling factor is 1/N.
		
		**** step 1 
		* Prepare interaction terms for the interacted regression
		local cohort_rel_varlist "" // hold the temp varnames	
		foreach l of varlist `rel_time_list' { 
			foreach yy of local cohort_list {  
				tempvar n`n`l''_`yy'
				qui gen `n`n`l''_`yy''  = (`cohort' == `yy') * `n`l' '
				// TODO: might be more efficient to use the c. operator if format w/o missing
				local cohort_rel_varlist "`cohort_rel_varlist' `n`n`l''_`yy''"
				if "`saveint'"!=""{
					loc lnumber=substr("`l'",7,2)
					qui gen _interact_`lnumber'_c`yy' = `n`n`l''_`yy''
				}
			}
		}
		local bcohort_rel_varlist "" // hold the interaction varnames
		foreach l of varlist `rel_time_list'  { 
			foreach yy of local cohort_list {
					local bcohort_rel_varlist "`bcohort_rel_varlist' `l'_x_`yy'" 
			}
		}
		* Estimate the interacted regression as an xtevent regression:
	}
	
	
	***** Main regression
	tempname reg_base
	
	if "`noestimate'"==""{ 
		
		if "`te'" == "note" loc te ""
		else loc te "i.`t'"
		
		* If gmm trend run regression before adjustment quietly
		if ("`methodt'"=="gmm" | "`sun_abraham'"!="") loc q "quietly" 
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
		
			`q' `cmd' `depenvar' `included' `indepvars' `te' `ttrend' [`weight'`exp'] if `touse', `abs' `options'
			_estimates hold `reg_base', copy
			if "`sun_abraham'"!=""{
				qui `cmd' `depenvar' `cohort_rel_varlist' `indepvars' `te' `ttrend' [`weight'`exp'] if `touse', `abs' `options'
			}			
		}
		else {
			loc cmd "reghdfe"
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
			`q' reghdfe `depenvar' `included' `indepvars' `ttrend' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
			_estimates hold `reg_base', copy
			if "`sun_abraham'"!=""{
				qui reghdfe `depenvar' `cohort_rel_varlist' `indepvars' `ttrend' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
			}
		}
		
	*** SA: combine cohort shares and output from the interacted regression 	
	if "`sun_abraham'"!=""{	
		tempname evt_bb b evt_VV V
		local bcohort_rel_varlist "`bcohort_rel_varlist' `covariates'" // TODO: does not catch the constant term if reghdfe includes a constant. 
		mat `b' = e(b) 
		mata st_matrix("`V'",diagonal(st_matrix("e(V)"))') 
		* Convert the delta estimate vector to a matrix where each column is a relative time
		local end = 0
		forval i = 1/`nrel_times' { 
			local start = `end'+1 
			local end = `start'+`ncohort'-1
			mat `b'`i' = `b'[.,`start'..`end']  
			mat `evt_bb'  = nullmat(`evt_bb') \ `b'`i' 
			mat `V'`i' = `V'[.,`start'..`end'] 
			mat `evt_VV'  = nullmat(`evt_VV') \ `V'`i'

		}
		mat `evt_bb' = `evt_bb'' 
		mat `evt_VV' = `evt_VV''

		* Take weighted average for IW estimators
		tempname w delta b_iw nc nr
		mata: `w' = st_matrix("`ff_w'") 
		mata: `delta' = st_matrix("`evt_bb'") 
		mata: `b_iw' = colsum(`w':* `delta') 
		mata: st_matrix("`b_iw'", `b_iw')
		mata: `nc' = rows(`w') 
		mata: `nr' = cols(`w') 

		* Ptwise variance from cohort share estimation and interacted regression
		tempname VV  wlong V_iw V_iw_diag 
		
		* VCV from the interacted regression
		mata: `VV' = st_matrix("e(V)")
		mata: `VV' = `VV'[1..`nr'*`nc',1..`nr'*`nc'] // in case reghdfe reports _cons
		mata: `wlong' = `w'':*J(1,`nc',e(1,`nr')') // create a "Toeplitz" matrix convolution
		forval i=2/`nrel_times' {
			mata: `wlong' = (`wlong', `w'':*J(1,`nc',e(`i',`nr')'))
		}
		mata: `V_iw' = `wlong'*`VV'*`wlong''
		* VCV from cohort share estimation
		tempname Vshare Vshare_evt share_idx Sigma_l
		mata: `Vshare' = st_matrix("`Sigma_ff'")
		mata: `Sigma_l' = J(0,0,.)
		mata: `share_idx' = range(0,(`nc'-1)*`nr',`nr')
		forval i=1/`nrel_times' {
			forval j=1/`i' {
				mata: `Vshare_evt' = `Vshare'[`share_idx':+`i', `share_idx':+`j']
				mata: `V_iw'[`i',`j'] = `V_iw'[`i',`j'] + (`delta'[,`i'])'*`Vshare_evt'*(`delta'[,`j'])
	// 			mata: `Sigma_l' = blockdiag(`Sigma_l',`Vshare_evt')
			}
		}
		mata: `V_iw' = makesymmetric(`V_iw')
	// 	mata: `V_iw' = `V_iw''
	// 	mata: st_matrix("`Sigma_l'", `Sigma_l')
		mata: st_matrix("`V_iw'", `V_iw')
		
		mata: `V_iw_diag' = diag(`V_iw')
		mata: st_matrix("`V_iw_diag'", `V_iw_diag')
		mata: mata drop `b_iw' `VV' `nc' `nr' `w' `wlong' `Vshare' `share_idx' `delta' `Vshare_evt' `Sigma_l' `V_iw' `V_iw_diag' 
		
		matrix colnames `b_iw' =  `dvarlist'
		matrix colnames `V_iw' =  `dvarlist'
		matrix rownames `V_iw' =  `dvarlist'
		
		matrix rownames `ff_w' =  `cohort_list'
		matrix colnames `ff_w' =  `dvarlist'
		matrix rownames `Sigma_ff' =  `cohort_list'
		matrix colnames `Sigma_ff' =  `cohort_list'

		matrix colnames `evt_bb' =  `dvarlist'
		matrix rownames `evt_bb' =  `cohort_list'
		matrix colnames `evt_VV' =  `dvarlist'
		matrix rownames `evt_VV' =  `cohort_list'

		*insert SA's estimations into base regresion
		tempname b_sa_adj v_sa_adj est_sun_abraham
		_estimates unhold `reg_base'
		mat `b_sa_adj'=e(b)
		mat `v_sa_adj'=e(V)

		loc deltanames : colnames(`b_iw')
		foreach i in `deltanames' {
			mat `b_sa_adj'[1,colnumb("`b_sa_adj'","`i'")]=`b_iw'[1,"`i'"]
			foreach j in `deltanames' {
			mat `v_sa_adj'[rownumb("`v_sa_adj'","`j'"),colnumb("`v_sa_adj'","`i'")]= `V_iw'["`j'","`i'"]	
			}
		}

		repostdelta `b_sa_adj' `v_sa_adj'
		* Display results	
		if "`methodt'"=="gmm" loc qq "quietly" 
		`qq' _coef_table_header
		`qq' _coef_table , bmatrix(e(b)) vmatrix(e(V))
		_estimates hold `est_sun_abraham', copy 
}
		
		* Return coefficients and variance matrix of the delta k estimates separately
		mat `bb'=e(b)
		mat `VV'=e(V)
		mat `delta' = `bb'[1,`names']
		mat `Vdelta' = `VV'[`names',`names']
		loc df = e(df_r)
		
		gen byte `esample' = e(sample)
	}
	
	* DiD estimate 
	
	if "`diffavg'"!=""{
		unab pre : _k_eq_m*
		unab post_p : _k_eq_p*
		loc norma = abs(`norm')
		if `norm' < 0{
			loc pre : subinstr local pre "_k_eq_m`norma'" "", all
			loc pre_plus : subinstr local pre " " " + ", all
			loc reverse = ustrreverse("`pre_plus'")
			loc reverse = subinstr("`reverse'", " + ", "", 1)
			loc pre_plus = ustrreverse("`reverse'")
		}
		if `norm' >= 0{
			loc post_p : subinstr local post_p "_k_eq_p`norma' " "", all
			loc pre_plus : subinstr local pre " " " + ", all
		}
		loc post_plus : subinstr local post_p " " " + ", all
		loc lwindow = abs(`lwindow')
		loc rwindow = `rwindow'
		di as text _n "Difference in pre and post-period averages from lincom:"
		lincom ((`post_plus') / (`rwindow' + 2)) - ((`pre_plus') / (`lwindow' + 1)), cformat(%9.4g)
	}
	
	* Trend adjustment by GMM
	
	if "`methodt'"=="gmm" {
		
		tempname deltatoadj Vtoadj deltaadj Vadj bbadj VVadj
		
		loc gmmtrendsc = `trcoef'
		loc start = "_k_eq_m`=abs(`trcoef')'"
		* Notice that here I am requiring normalization in -1
		mat `deltatoadj' = `delta'[1,"`start'".."_k_eq_m2"]
		mat `deltatoadj' = [`deltatoadj',0]
		mat `deltatoadj' = `deltatoadj''
		mat `Vtoadj' = `Vdelta'["`start'".."_k_eq_m2","`start'".."_k_eq_m2"]
		mat `Vtoadj' = [`Vtoadj',J(`=abs(`trcoef')-1',1,0)]
		mat `Vtoadj' = (`Vtoadj'\J(1,`=abs(`trcoef')',0))

		* Get vector of other coefficients, and their variance
		tempname Omegapsi_st Omegadeltapsi_st Valladj gmm_trcoefs
		loc deltanames : colnames(`delta')
		loc deltanames1: word 1 of `deltanames'
		loc deltanamesw: word count `deltanames'
		loc deltanamesl: word `deltanamesw' of `deltanames'
		loc Vnames : colnames(`VV')
		loc psinames: list Vnames - deltanames
		loc psinames1 : word 1 of `psinames'
		mat psi = `bb'[1,"`psinames1'"...]
		mat `Omegapsi_st' = `VV'["`psinames1'"...,"`psinames1'"...]
		mat `Omegadeltapsi_st' = `VV'["`deltanames1'".."`deltanamesl'","`psinames1'"...]
		
		mata: adjdelta(`gmmtrendsc',`lwindow',`rwindow',"`deltatoadj'","`Vdelta'","`Vtoadj'","`delta'","`Omegapsi_st'","`Omegadeltapsi_st'","`gmm_trcoefs'","`deltaadj'","`Vadj'","`Valladj'")

		* Post the new results 
		loc dnames : colnames(`delta')
		*change column an row names 
		mat colnames `deltaadj' = `dnames'
		mat colnames `gmm_trcoefs' = `dnames'
		mat colnames `Vadj' = `dnames'
		mat rownames `Vadj' = `dnames'
		mat `bbadj' = `bb'
		mat `VVadj' = `VV'
		*insert adjusted values
		foreach i in `dnames' {
			mat `bbadj'[1,colnumb("`bb'","`i'")]= `deltaadj'[1,"`i'"]
			foreach j in `dnames' {
				mat `VVadj'[rownumb("`VVadj'","`j'"),colnumb("`VVadj'","`i'")]= `Vadj'["`j'","`i'"]	
			}
		}
		
		* Post the new results (V matrix for all coeffs)
		tempname VValladj
		loc allnames : colnames(`bb')
		mat colnames `Valladj' = `allnames'
		mat rownames `Valladj' = `allnames'
		mat `VValladj' = `VV'
		foreach i in `allnames' {
			foreach j in `allnames' {
				mat `VValladj'[rownumb("`VValladj'","`j'"),colnumb("`VValladj'","`i'")]= `Valladj'["`j'","`i'"]	
			}
		}
		
		*reset delta & Vdelta so xteventplot will plot the right coefficients 
		mat `delta' = `bbadj'[1,`names']
		mat `Vdelta' = `VVadj'[`names',`names']
		
		*reset b and V so the returned matrices are the adjusted ones 
		mat `bb'=`bbadj'
		mat `VV'=`VValladj'
		
		*repostdelta `bbadj' `VVadj'
		repostdelta `bbadj' `VValladj'
		
		`cmd'
		
	}
	
	* Variables for overlay plot if trend
	
	if "`saveov'"!="" {
		_estimates hold mainols 
		unab included2 : _k*
		loc toexc "_k_eq_m1"
		loc included2: list local included2 - toexc
		*estimate the contrafactual: no adjusting by trend. only exclude event-time dummy -1
		*trend excludes from trend (e.g. -3) to -1
		if "`sun_abraham'"!="" _estimates unhold `est_sun_abraham' //call the SA estimations that have not been corrected by trend
		else {
			if "`reghdfe'"== "" {
				qui _regress `varlist' `included2' `te' [`weight'`exp'] if `touse', `abs' `options'
			}
			else {
				qui reghdfe `varlist' `included2' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
			}
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
		forv c=`trcoef'(1)-1 {
			loc absc = abs(`c')
			if "`methodt'"=="ols"{
				if `c'!=-1 qui replace `trendy'=_b[_k_eq_m`absc'] in `j' 
				else if `c'==-1 qui replace `trendy'=0 in `j'
			}
			else if "`methodt'"=="gmm"{
				if `c'!=-1 qui replace `trendy'=`gmm_trcoefs'[1,"_k_eq_m`absc'"] in `j'
				else if `c'==-1 qui replace `trendy'=0 in `j'
			}
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
	
	*save a temporary copy of the event-time dummy corresponding to the normalized period before dropping that dummy variable
	tempvar temp_k
	loc absnorm=abs(`norm')
	qui gen `temp_k'=_k_eq_m`absnorm' 
	
	* Drop variables
	if "`savek'" == "" & "`drop'"!="nodrop" {
		cap confirm var _k_eq_p0
		if !_rc drop _k_eq*		
		cap confirm var __k
		if !_rc qui drop __k
		if "`methodt'"=="ols" qui drop _ttrend
		if "`saveint'"!="" qui drop _interact*
	}
	else if "`savek'" != "" & "`drop'"!="nodrop"  {
		ren __k `savek'_evtime
		ren _k_eq* `savek'_eq*

		if "`methodt'"=="ols" ren _ttrend `savek'_trend
		if "`saveint'"!="" ren _interact* `savek'_interact*
	}
	
	*skip the rest of the program if the user indicated not to estimate
	return local noestimate "`noestimate'"
	if "`noestimate'"!="" exit 
	
	* Calculate mean before change in policy for 2nd axis in plot
	* This needs to be relative to normalization

	tokenize `varlist'
	loc depvar "`1'"
	qui su `1' if `temp_k'!=0 & `temp_k'!=. & `esample', meanonly 
	loc y1 = r(mean)

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
	if "`sun_abraham'"!=""{
		return matrix b_interact `evt_bb' //interactions: cohort-relative time effects
		return matrix V_interact `evt_VV' // variance of the interactions
		return matrix ff_w `ff_w' //cohort shares
		return matrix Sigma_ff `Sigma_ff' //variance estimate of the cohort share estimators
		return loc sun_abraham = "sun_abraham"
	}
	if "`saveov'"!="" {
		return matrix deltaov = `deltaov' //user:delta coefs from unadjusted regression. excludes only norm=-1
		return matrix Vdeltaov = `Vdeltaov'
		return matrix mattrendy = `mattrendy'
		return matrix mattrendx = `mattrendx'
		return local trendsaveov = "trendsaveov"
	}
	if "`trend'"!="" return local trend = "trend" 
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
					string scalar getOmegapsi,
					string scalar getOmegadeltapsi,
					string scalar gmm_trcoefs,
					string scalar deltaadj,
					string scalar Vadj,
					string scalar Valladj)
	{
	
	real matrix deltaL, Omega, OmegaL, delta, Omegapsi, Omegadeltapsi, HL, W, Vphi_hat, LambdaL, phi_hat, H, delta_star, Lambda, Vdelta_star, V_star11, V_star12, V_star21, V_star22, V_star, H_phi_hat
	
	deltaL = st_matrix(getDeltaL)
	Omega = st_matrix(getOmega)
	OmegaL = st_matrix(getOmegaL)
	delta = st_matrix(getdelta)
	delta = delta'
	
	Omegapsi=st_matrix(getOmegapsi)
	Omegadeltapsi=st_matrix(getOmegadeltapsi)
	/*
	deltaL
	Omega
	OmegaL
	delta
	
	Omegapsi
	Omegadeltapsi
	*/
	
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
	
	/* Get variance of entire adjusted vector. Other coefs do not change but their covariance with delta does */
	V_star11 = (I(rows(delta)) - H*Lambda)* Omega * (I(rows(delta)) - Lambda'*H')
	V_star12 = (I(rows(delta)) - H*Lambda) * Omegadeltapsi
	V_star21 = Omegadeltapsi' * (I(rows(delta)) - Lambda'*H') 
	V_star22 = Omegapsi
	V_star = (V_star11,V_star12\V_star21,V_star22)
	/* Average to kill eps errors */
	V_star = 0.5*(V_star + V_star') 
	
	/* values of the trend for overlay plot */
	H_phi_hat=H*phi_hat
	
	/* return trend coeffcients*/
	st_matrix(gmm_trcoefs,H_phi_hat')
	
	/*return adjusted matrices*/
	st_matrix(deltaadj,delta_star')
	st_matrix(Vadj,Vdelta_star)
	st_matrix(Valladj,V_star)
	
	
	}
	
end

cap program drop repostdelta
program define repostdelta, eclass
	ereturn repost b=`1' V=`2'
end

* Program to parse trend
cap program drop parsetrend
program define parsetrend, rclass

	syntax [anything] , [method(string) SAVEOVerlay]
		
	return local trcoef "`anything'"
	if "`method'"=="" loc method "gmm"
	return local methodt "`method'"
	return local saveoverlay "`saveoverlay'"
end	

*program to parse savek
cap program drop parsesavek
program define parsesavek, rclass

	syntax [anything] , [NOEstimate SAVEINTeract]
		
	return local savekl "`anything'"
	return local noestimatel "`noestimate'"
	return local saveintl "`saveinteract'"
end	


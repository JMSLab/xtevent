version 13

program define _eventols, rclass
	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Proxy for eta and covariates go in varlist. Can add fv ts later */
	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */
	POLicyvar(varname) /* Policy variable */
	LWindow(string) /* Left window. */
	RWindow(string) /* Right window. */
	[
	w_type(string) /* Window defined by the user (numeric) or define window based on the data time limits (string: max or balanced) */
	nofe /* No fixed effects */
	note /* No time effects */
	TRend(string) /* trend(a -1) Include a linear trend from time a to -1. Method can be either GMM or OLS*/
	SAVek(string) /* Generate the time-to-event dummies, trend and keep them in the dataset */					
	nogen /* Do not generate k variables */
	kvars(string) /* Stub for event dummies to include, if they have been generated already */				
	nodrop /* Do not drop _k variables */
	norm(numlist integer max=1) /* Coefficiente to normalize */
	reghdfe /* Use reghdfe for estimation */	
	IMPute(string) /*imputation on policyvar*/
	addabsorb(string) /* Absorb additional variables in reghdfe */
	DIFFavg /* Obtain regular DiD estimate implied by the model */
	cohort(string) /* create or variable varname, where varname is categorical variable indicating cohort */
	control_cohort(string) /* dummy variable indicating the control cohort */
  REPeatedcs /*indicate that the input data is a repeated cross-sectional dataset*/

	*
	]
	;
	#d cr
	
	marksample touse
	
	tempvar mkvarlist
	qui gen byte `mkvarlist' = `touse'
		
	tempname delta Vdelta bb VV
	* delta - event coefficients
	* bb - regression coefficients
	tempvar esample	tousegen
	
	* For eventgenvars and for cohort generation, ignore missings in varlist
	mark `tousegen' `if' `in'
	

	**** parsers
	
	*parse savek 
	if "`savek'"!="" parsesavek `savek'
	foreach l in savek noestimate saveint kreplace {
		loc `l' = r(`l')
		if "``l''"=="." loc `l' ""
		return loc `l' = "``l''"
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

		if "`w_type'"=="numeric" {
			if  `trcoef'<`lwindow'-1 | `trcoef'>`rwindow'+1 {
				di as err "{bf:trend} is outside estimation window."
				exit 301
			}
		}
	
		if `trcoef'>=0 {
			di as err "trend coefficient must be smaller than 0"
			exit 301
		}
		if `trcoef'==-1 {
			di as err "Trend extrapolation requires at least two pre-treatment points"
			exit 301
		}			
		if !inlist("`methodt'","ols","gmm"){
			di as err "{bf:method(`methodt')} is not a valid suboption"		
			exit 301
		}
		if "`methodt'"=="ols" {
			loc ttrend "_ttrend"
		}
		else loc ttrend ""
	}
	
	* error messages for sun_abraham
	loc sun_abraham ""
	if "`cohort'"!="" {
		di as text _n "You have specified the {bf:cohort} or the {bf:sunabraham} option"
		di as text "Event-time coefficients will be estimated with the Interaction Weighted Estimator of Sun and Abraham (2021)"
		loc sun_abraham "sun_abraham"
	}
	if "`saveint'"!="" & "`sun_abraham'"==""{
		di as err _n "Suboption {bf:saveint} can only be specified with {bf:cohort}"
		exit 301
	}

	*gen & kvars
	if ("`gen'"!="" & "`kvars'"=="") |  ("`gen'"=="" & "`kvars'"!="") {
		di as err _n "Options -nogen- and -kvars- must be specified together"
		exit 301
	}

	* Parse cohort and control_cohort

	if "`cohort'"!="" {

		* Parse to distinguish if cohort variable is given or should be created
		parsecohort `cohort'	
		loc cohortvar = r(cohortvar)
		loc cohortforce = r(force)
		loc cohorttype = r(cohorttype)
		loc cohortsave = r(save)
		loc cohortreplace = r(replace)

		* Parse control_cohort

		if "`control_cohort'" == "" {
			loc control_cohorttype "create"
			loc control_cohortvar = "."
		}
		else {
			parsecontrol_cohort `control_cohort'
			loc control_cohortvar = r(control_cohortvar)
			loc control_cohorttype = r(control_cohorttype)
			loc control_cohortsave = r(save)
			loc control_cohortreplace = r(replace)
		}

		* Check consistency: if cohort and control_cohort are both given, the cohort variable should be missing if control_cohort is 1 unless force

		if "`cohorttype'"=="variable" & "`cohortforce'"=="." & "`control_cohorttype'"=="variable" {
			cap assert `cohortvar'==. if `control_cohortvar' == 1 & `touse'
			if _rc {
				di as err _n "Cohort variable `cohortvar' is not missing for the control cohort selected by `control_cohort'"
				exit 301
			}
			cap assert `control_cohortvar'==0 | `control_cohortvar'==1 if `touse'
			if _rc {
				di as err _n "Control cohort indicator variable `control_cohortvar' is not binary"
				exit 301 
			}
			cap assert `control_cohortvar'==0 if `cohortvar'!=. & `touse'
			if _rc {
				di as err _n "Control cohort variable `control_cohortvar' is not zero for treated cohorts defined by `cohortvar'"
				exit 301
			}			
		}
		else if "`cohortvar'"!="" & "`cohortforce'"=="force" & "`cohorttype'"=="variable" {
			di as text _n "Treatment cohort variable `cohortvar' was not checked for consistency with the policy"
			di as text "variable `policyvar' or the control cohort variable `control_cohortvar'"
		}	



	}



	***
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"

	* Set norm to -1 if missing

	if "`norm'"=="" loc norm = -1
	
	if "`gen'" != "nogen" {
		if "`impute'"!=""{
			tempvar rr
			qui gen double `rr'=.
		}
	
		_eventgenvars if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') w_type(`w_type') trcoef(`trcoef') methodt(`methodt') norm(`norm') impute(`impute') rr(`rr') mkvarlist(`mkvarlist') `repeatedcs'

		loc included=r(included)
		loc names=r(names)
		loc komittrend=r(komittrend)
		loc binnorev = r(binnorev)
		loc ambiguous = r(ambiguous)
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
		*if window was max or balanced, use calculated left and right window limits 
		if "`w_type'"=="string" {
			loc lwindow = r(lwindow)
			loc rwindow = r(rwindow)
		}
		
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

		* Another consistency check: obs with cohort should have some treated values, obs with control_cohort should have some untreated values
		* Not checking that all cohorts have treated values, not checking that z is always zero for never treat, so these are minimal checks

		if "`cohorttype'"=="" {
			qui levelsof z if `cohortvar'!=. & `tousegen|'
			if r(levels)=="0" {
				di as err _n "Treated observations according to cohort variable `cohortvar' are inconsistent"
				di as err "with values of the policy variable `z'"
				exit 301
			}

			if "`control_cohorttype'"=="variable" {
				qui count if `z'==0 & `control_cohortvar' & `tousegen'
				if r(N)==0 {
					di as err _n "Untreated observations according to control cohort variable `control_cohortvar'"
					di as err "are inconsistent with values of the policy variable `z'"
				}
			}
		}

		* Create the cohort variable if requested
		if "`cohorttype'"=="create" {
			cap assert `binnorev'==1
			if _rc {
				di as err _n "The policy variable is not binary or treatment reverts"
				di as err "Cannot create treatment cohort variables"
				exit 301
			}

			tempvar timet 
			qui gen `timet'=`timevar' if `policyvar'==1 & `tousegen'

			cap confirm var _cohort 
			if !_rc {
				di as err _n "You have a variable named _cohort. _cohort is reserved for internal -xtevent- variables."
				di as err _n "Please rename this variable before proceeding."
				exit 110
			}
			
			qui bys `panelvar' : egen _cohort = min(`timet') if `tousegen'
			loc cohortvar "_cohort"			
		}

		* If control_cohort is missing, take the values with cohort = .
		if "`cohortvar'"!="" & "`control_cohorttype'"=="create" {
			if "`control_cohort'"=="" di as txt _n "Control cohort not specified. Using values with cohort variable == . as the control cohort"
			else di as txt _n "Using values with cohort variable == . as the control cohort"

			cap confirm var _control_cohort 
			if !_rc {
				di as err _n "You have a variable named _control_cohort. _control_cohort is reserved for internal -xtevent- variables."
				di as err _n "Please rename this variable before proceeding."
				exit 110
			}

			gen _control_cohort = (`cohortvar' == .)
			loc control_cohortvar "_control_cohort"
		}

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
			qui replace `n`l'' = 0 if  `control_cohortvar' == 1 
			local nvarlist "`nvarlist' `n`l''" 
		}	

		* Get cohort count  and count of relative time
		qui levelsof `cohortvar' if  `control_cohortvar' == 0, local(cohort_list) 
		local nrel_times: word count `nvarlist' 
		local ncohort: word count `cohort_list'  
		
		**** step 2 
		* Initiate empty matrix for weights 
		tempname bb ff_w
		
		* Loop over cohort and get cohort shares for relative times
		local nresidlist ""
		foreach yy of local cohort_list {
			tempvar cohort_ind resid`yy'
			qui gen `cohort_ind'  = (`cohortvar' == `yy') 
			qui _regress `cohort_ind' `nvarlist'  if `touse' & `control_cohortvar' == 0 [`weight'`exp']  , nocons
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
		qui mat accum `XX' = `nvarlist' if  `touse' & `control_cohortvar' == 0 [`weight'`exp'], nocons
		mat `Sxx' = `XX'*1/r(N) 
		mat `Sxxi' = syminv(`Sxx') 
		qui avar (`nresidlist') (`nvarlist')  if `touse' & `control_cohortvar' == 0 [`weight'`exp'], nocons robust
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
		local interact_varlist "" // fill in with name of interaction variables
		foreach l of varlist `rel_time_list' { 
			foreach yy of local cohort_list {  
				tempvar n`n`l''_`yy'
				qui gen `n`n`l''_`yy''  = (`cohortvar' == `yy') * `n`l' '
				// TODO: might be more efficient to use the c. operator if format w/o missing
				local cohort_rel_varlist "`cohort_rel_varlist' `n`n`l''_`yy''"
				if "`saveint'"!=""{
					loc lnumber : subinstr local l "_k_eq_" ""					
					qui gen _interact_`lnumber'_c`yy' = `n`n`l''_`yy''
					loc interact_varlist "`interact_varlist' _interact_`lnumber'_c`yy'"
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
	
	* DiD estimate 
	
	if "`diffavg'"!=""{
		*list of omitted coefficients
		loc komit_comma : subinstr local komit " " ",", all
		* fill in lists of pre and post coefficients 
		loc pre_plus ""
		loc post_plus ""
		if "`trend'"!="" {
			di as txt _n "When trend is included, the endpoints are excluded from the calculation of the difference"
			di as txt "in average coefficients between the pre and post periods."
			loc llimit = `lwindow'
			loc rlimit = `rwindow'
			loc postden = `rwindow'+1
			loc preden = -`lwindow'
		}
		else {
			loc llimit = `lwindow'-1
			loc rlimit = `rwindow'+1
			loc postden = `rwindow'+2
			loc preden = -`lwindow'+1
		}
		forvalues v = `llimit'/`rlimit' {
			if inlist(`v', `komit_comma') continue 
			if `v'<0 {
				loc pre_plus "`pre_plus' _k_eq_m`=-`v''"
			}
			else {
				loc post_plus "`post_plus' _k_eq_p`=`v''"
			}
		}
		loc pre_plus = strtrim("`pre_plus'")
		if "`pre_plus'"=="" {
			di as err "No pre-event coefficients to calulate the difference in averages"
			exit 301
		}
		loc post_plus = strtrim("`post_plus'")
		if "`post_plus'"=="" {
			di as err "No post-event coefficients to calulate the difference in averages"
			exit 301
		}
		loc pre_plus : subinstr local pre_plus " " " + ", all
		loc post_plus : subinstr local post_plus " " " + ", all
		di as text _n "Difference in pre and post-period averages from lincom:"
		lincom ((`post_plus') / (`postden')) - ((`pre_plus') / (`preden')), cformat(%9.4g)
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
	
	if "`sun_abraham'"!="" {
		if "`control_cohorttype'"=="create" {
			if "`control_cohortsave'"=="save" {
				cap confirm variable `policyvar'_control_cohort
				if !_rc {
					if "`control_cohortreplace'"=="replace" {
						drop `policyvar'_control_cohort
						ren _control_cohort `policyvar'_control_cohort
					}
					else {
						di as err _n "variable `policyvar'_control_cohort already exists"
						drop _control_cohort
						exit 301
					}
				}
				else {
					ren _control_cohort `policyvar'_control_cohort
				}
			}
			else drop _control_cohort	
		}
		if "`cohorttype'"=="create"	{	
			if "`cohortsave'"=="save" {
				cap confirm variable `policyvar'_cohort
				if !_rc {
					if "`cohortreplace'"=="replace" {
						drop `policyvar'_cohort
						ren _cohort `policyvar'_cohort
					}
					else {
						di as err _n "variable `policyvar'_cohort already exists"
						drop _cohort
						exit 301
					}
				}
				else {
					ren _cohort `policyvar'_cohort
				}
			}
			else drop _cohort	
		}	
	}
	

	*save a temporary copy of the event-time dummy corresponding to the normalized period before dropping that dummy variable
	tempvar temp_k
	if `norm' < 0 loc kvomit = "m`=abs(`norm')'"
	else loc kvomit "p`=abs(`norm')'"
	qui gen `temp_k'=_k_eq_`kvomit' 
	
	
	*recover omitted k vars 
	loc kvars_omit ""
	if "`komit'"!=""{
		foreach k in `komit' {
			if `k'<0 loc kvars_omit "`kvars_omit' _k_eq_m`=abs(`k')'"
			else loc kvars_omit "`kvars_omit' _k_eq_p`=abs(`k')'"
		}
	}
	*full list of event-time dummies (included + omitted)
	loc eventtd = "`included' `kvars_omit'"
	
	* Drop variables
	if "`savek'" == "" & "`drop'"!="nodrop" {
		cap confirm var `eventtd', exact 
		if !_rc drop `eventtd'		
		cap confirm var __k, exact
		if !_rc qui drop __k
		if "`methodt'"=="ols" {
			cap confirm var _ttrend, exact
			if !_rc qui drop _ttrend
		} 
		if "`saveint'"!="" {
			cap confirm var `interact_varlist', exact
			if !_rc qui drop `interact_varlist'
		}
	}

	else if "`savek'" != "" & "`drop'"!="nodrop"  {
	
		*change prefix
		loc eventtd_savek : subinstr local eventtd "_k" "`savek'", all
	
		*If replace suboption, drop the existing variables before renaming the recently created ones 
		if "`kreplace'"!="" {
			*event-time dummies 
			foreach v in `eventtd_savek' {
				cap confirm variable `v', exact 
				if !_rc drop `v'
			}
			*event-time variable 
			cap confirm variable `savek'_evtime, exact
			if !_rc drop `savek'_evtime
			*trend 
			cap confirm variable `savek'_trend, exact 
			if !_rc drop `savek'_trend
			*interaction variables
			foreach v in `interact_varlist' {
				cap confirm variable `savek'`v', exact 
				if !_rc drop `savek'`v'
			}
		}
		
		*Check that variables don't exist 
		cap confirm variable `eventtd_savek', exact
		if !_rc {
			di as err _n "You specified to save the event-time dummy variables using the prefix {bf:`savek'}, but you already have event-time dummy variables saved with that prefix."
			di as err _n "Use the {bf:replace} suboption to replace the existing variables."
			exit 110
		}
		cap confirm variable `savek'_evtime, exact
		if !_rc {
			di as err _n "You specified to save the event-time variable using the prefix {bf:`savek'}, but you already have an event-time variable saved with that prefix."
			di as err _n "Use the {bf:replace} suboption to replace the existing variable."
			exit 110
		}
		if "`trend'"!=""{
			cap confirm variable `savek'_trend, exact
			if !_rc {
				di as err _n "You specified to save the trend variable using the prefix {bf:`savek'}, but you already have a trend variable saved with that prefix."
				di as err _n "Use the {bf:replace} suboption to replace the existing variable."
				exit 110
			}
		}
		if "`sun_abraham'"!="" {
			foreach v in `interact_varlist' {
			cap confirm variable `savek'`v', exact 
				if !_rc {
					di as err _n "You have variable names with the {bf:`savek'_interact} prefix"
					di as err _n "{bf:`savek'_interact} is reserved for the interaction variables in Sun-and-Abraham estimation"
					di as err _n "Use the {bf:replace} suboption to replace the existing variables."
					exit 110
				}
			}
		}
		
		ren __k `savek'_evtime
		ren (`eventtd') (`eventtd_savek')

		if "`methodt'"=="ols" ren _ttrend `savek'_trend
		loc interact_varlist_savek : subinstr local interact_varlist "_interact" "`savek'_interact", all
		if "`saveint'"!="" ren (`interact_varlist') (`interact_varlist_savek')
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
	if "`w_type'"=="string" {
		return local lwindow = `lwindow'
		return local rwindow = `rwindow' 
	}
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
	return local ambiguous = "`ambiguous'"
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
	if "`trend'"!="" {
		return local trend = "trend" 
		return local trendmethod = "`methodt'" 
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

program define repostdelta, eclass
	ereturn repost b=`1' V=`2'
end

* Program to parse trend
program define parsetrend, rclass

	syntax [anything] , [method(string) SAVEOVerlay]
		
	return local trcoef "`anything'"
	if "`method'"=="" loc method "gmm"
	return local methodt "`method'"
	return local saveoverlay "`saveoverlay'"
end	

*program to parse savek
program define parsesavek, rclass

	syntax [anything] , [NOEstimate SAVEINTeract replace]
		
	return local savek "`anything'"
	return local noestimate "`noestimate'"
	return local saveint "`saveinteract'"
	return local kreplace "`replace'"
end

* program to parse cohort
program define parsecohort, rclass

	syntax namelist(min=1 max=2), [force] [save] [replace]

	loc words=wordcount("`namelist'")

	if `words' == 1 {
		if "`namelist'"=="create" {
			loc cohortvar = ""
			loc cohorttype = "create"
		}
		else {
			confirm variable `namelist'		
			di as text _n "Warning: Using old syntax for cohort. New syntax for using a cohort variable is cohort(variable varname)"
			di as text "The old syntax will be deprecated in the next version of {cmd:xtevent}"
			loc cohortvar "`namelist'"
			loc cohorttype "variable"
		}
	}
	else if `words'==2 {
		loc first: word 1 of `namelist'
		if ("`first'" != "variable")  {
			di as err _n "Invalid syntax for cohort"
			exit 301
		}
		loc second : word 2 of `namelist'
		loc cohortvar "`second'"
		loc cohorttype "variable"		
	}

	if "`cohorttype'"=="create" & "`force'"!="" {
		di _n "cohort variable created, force option ignored"
	}

	if ("`save'"!="" | "`replace'"!="") & "`cohorttype'"=="variable" {
		di as err _n "cohort variable can only be saved/replaced if created"
		exit 301
	}

	if "`replace'"!="" & "`save'"=="" {
		di as err _n "cohort variable replace only allowed with save"
		exit 301
	}

	return local cohortvar = "`cohortvar'"
	return local cohorttype = "`cohorttype'"
	return local force = "`force'"
	return local save = "`save'"
	return local replace = "`replace'"
end

* program to parse control_cohort
program define parsecontrol_cohort, rclass

	syntax namelist(min=1 max=2), [save] [replace]

	loc words=wordcount("`namelist'")

	if `words' == 1 {
		if "`namelist'"=="create" {
			loc control_cohortvar = ""
			loc control_cohorttype = "create"
		}
		else {
			confirm variable `namelist'		
			di as text _n "Warning: Using old syntax for control_cohort. New syntax for using a control cohort variable is"
			di as text "control_cohort(variable varname)"
			di as text "The old syntax will be deprecated in the next version of {cmd:xtevent}"
			loc control_cohortvar "`namelist'"
			loc control_cohorttype "variable"
		}
	}
	else if `words'==2 {
		loc first: word 1 of `namelist'
		if ("`first'" != "variable")  {
			di as err _n "Invalid syntax for control_cohort"
			exit 301
		}
		loc second : word 2 of `namelist'
		loc control_cohortvar "`second'"
		loc control_cohorttype "variable"		
	}

	if ("`save'"!="" | "`replace'"!="") & "`control_cohorttype'"=="variable" {
		di as err _n "control cohort variable can only be saved/replaced if created"
		exit 301
	}

	if "`replace'"!="" & "`save'"=="" {
		di as err _n "control cohort variable replace only allowed with save"
		exit 301
	}

	return local control_cohortvar = "`control_cohortvar'"
	return local control_cohorttype = "`control_cohorttype'"	
	return local save = "`save'"
	return local replace = "`replace'"
end


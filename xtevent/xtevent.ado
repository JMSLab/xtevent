*! xtevent.ado 3.0.0 February 23, 2024

version 13

program define xtevent, eclass

	* Replay routine
	if replay() {
		if "`e(cmd2)'"!="xtevent" exit 301
		else {
			loc rep = e(cmd)
			`rep'
		}
		exit
	}

	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in] , /* Proxy for eta and covariates go in varlist. Can add fv ts later */	
	POLicyvar(varname) /* Policy variable */	
	[
	Window(string) /* Estimation window */
	pre(numlist >=0 min=1 max=1 integer) /* Pre-event time periods where anticipation effects are allowed */
	post(numlist >=0 min=1 max=1 integer) /* Post-event time periods where dynamic effects are allowed */
	overidpre(numlist >=0 min=1 max=1 integer) /* Pre-event time periods for overidentification */
	overidpost(numlist >=0 min=1 max=1 integer) /* Post-event time periods for overidentification */
	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */
	proxyiv(string) /* Instruments. For FHS set ins equal to leads of the policy */
	proxy (varlist numeric) /* Proxy variable */		
	TRend(string) /*trend(a -1) Include a linear trend from time a to -1. Method can be either GMM or OLS*/
	SAVek(string) /* Generate the time-to-event dummies, trend, and cohort-relative time interactions and keep them in the dataset */
	STatic /* Estimate static model */			
	reghdfe /* Estimate with reghdfe */
	addabsorb(string) /* Absorb additional variables in reghdfe */
	norm(integer -1) /* Normalization */
	REPeatedcs /*indicate that the input data is a repeated cross-sectional dataset*/
	cohort(string) /* create or variable varname, where varname is categorical variable indicating cohort */
	control_cohort(string) /* dummy variable to indicate cohort to be used as control in SA estimation*/
	SUNABraham /* Alias for cohort(create) */
	plot /* Produce plot */
	*
	/*
	These options passed to subcommands
	
	nofe /* No fixed effects */
	note /* No time effects */
	Kvars(string) /* Use previously generated dummies */
	impute(string) /* impute policyvar */
	*/
	]
	;
	#d cr

	
	
	* Capture errors
	
	if "`addabsorb'"!="" & "`reghdfe'"=="" {
		di as err "option {bf:addabsorb} only allowed with option {bf:reghdfe}"
		exit 198
	}	

	if "`proxy'" == "" & "`proxyiv'" != "" {
		di as err _n "With instruments, you must specify a proxy variable"
		exit 198
	}
	
	* If xtset, don't need panelvar and timevar	
	cap xtset
	if _rc==459 {
		if "`panelvar'"=="" & "`timevar'"!="" | "`panelvar'"!="" & "`timevar'"=="" | "`panelvar'"=="" & "`timevar'"=="" {
			di as err _n "If data have not been xtset, you must specify options {bf:panelvar} and {bf:timevar}"
			exit 198
		}
	}
	else if ("`panelvar'"!="" & "`panelvar'"!=r(panelvar)) | ("`timevar'"!="" & "`timevar'"!=r(timevar)) {
		di as err _n "Data have been xtset, and you specified options {bf:panelvar} or {bf:timevar} with variables different from those previously set. Run {cmd:xtset,clear}  or {cmd:xtset} your data again"
		exit 198
	}
	else if ("`panelvar'"=="" & "`timevar'"=="") | ("`panelvar'"!="" & "`timevar'"=="") | ("`panelvar'"=="" & "`timevar'"!="")  {
		di as txt _n "Using options {bf:panelvar} and {bf:timevar} from {cmd:xtset}"
		loc panelvar=r(panelvar)
		loc timevar=r(timevar)
	}

	if "`trend'"!="" & "`proxy'"!="" {
		di as err _n "options {bf:proxy} and {bf:trend} not allowed simultaneously"
		exit 198
	}
	
	if "`trend'"!="" & "`static'"!="" {
		di as err _n "options {bf:static} and {bf:trend} not allowed simultaneously"
		exit 198
	}
		
	* Always need window unless static is specified
	if "`window'"=="" & ("`static'"=="" & ("`pre'"=="" | "`post'"=="" | "`overidpre'"=="" | "`overidpost'"=="")) {
		di as err _n "option {bf:window} is required unless option {bf:static}, or options {bf:pre},{bf:post},{bf:overidpre}, and {bf:overidpost} are specified"
		exit 198
	}
	if "`window'"!="" & "`static'"!="" {
		di as err _n "option {bf:window} not allowed with option {bf:static}"
		exit 198
	}
	if "`window'"!="" & ("`static'"!="" | ("`pre'"!="" | "`post'"!="" | "`overidpre'"!="" | "`overidpost'"!="")) {
		di as err _n "option {bf:window} not allowed with options {bf:static},{bf:pre},{bf:post},{bf:overidpre}, or {bf:overidpost}"
		exit 198
	}
	if ("`static'"!="" & ("`pre'"!="" | "`post'"!="" | "`overidpre'"!="" | "`overidpost'"!="")) {
		di as err _n "option {bf:static} not allowed with options {bf:pre},{bf:post},{bf:overidpre}, or {bf:overidpost}"
		exit 198
	}
			
	if "`savek'"=="_k" {
		di as err _n "_k reserved for internal variables. Please choose a different stub"
		exit 198
	}
	
	if "`reghdfe'" != "" {
		foreach p in reghdfe ftools {
			cap which `p'
			if _rc {
				di as err _n "option {bf:reghdfe} requires {cmd: `p'} to be installed"
				exit 199
			}
		}
		if "`proxy'"!="" {
			foreach p in ivreghdfe ivreg2 ranktest avar {
				cap which `p'
				if _rc {
					di as err _n "option {bf:reghdfe} and IV estimation requires {cmd: `p'} to be installed"
					exit 199
				}
			}
		}
	}
	
	*inform panel variables in case of data is repeated cross-sectional
	if "`repeatedcs'"!=""{
		di as txt _n "Option {bf:repeatedcs} was specified. Using {bf:`panelvar'} as the panel variable and {bf:`timevar'} as the time variable."
	}
	
	if "`cohort'"!="" {
		cap which avar 
		if _rc {
			di as err _n "Sun-and-Abraham estimation requires {cmd: avar} to be installed"
			exit 199
		}
	}

	if "`control_cohort'"!="" & "`cohort'"=="" {
		di as err _n "{bf:control_cohort} requires {bf:cohort} to be specified"
		exit 198
	}

	if "`sunabraham'"!="" {		
		if "`cohort'"=="" loc cohort "create"		
	}

	* SA estimation not implemented with IV estimation yet
	if ("`cohort'"!="" | "`control_cohort'"!="" | "`sunabraham'"!="") & ("`proxy'"!="" | "`proxyiv'"!="") {
		di as err _n "Sun-and-Abraham estimation not allowed with proxy or instruments"
		exit 198
	}

	* Keep old vars that have reserved names to avoid dropping them if cleanup
	loc oldvars ""
	foreach x in _k_eq* _ttrend* __k* _f* _interact* {
		cap unab oldvarsadd: `x'
		loc oldvars "`oldvars' `oldvarsadd'"
		loc oldvarsadd ""
	}	

	tempvar tousegen
	
	* Do not mark variables, only if in here
	
	mark `tousegen' `if' `in'
	
	loc flagerr=0
	
	
	* first parsing of window 
	if "`window'"!="" {
		parsewindow `window'
		loc swindow = r(window)
		loc w_type = r(w_type)	
	}

	if "`static'"=="" {
		if "`window'"!="" {
			* Parse window
			loc nw : word count `window'
			
			* if window is numeric 
			if "`w_type'"=="numeric"{
				if `nw'==1 {
					loc lwindow = -`window'
					loc rwindow = `window'
				}
				else if `nw'==2 {
					loc lwindow : word 1 of `window'
					loc rwindow : word 2 of `window'
				}
			}
			* if window is string (max or balanced)
			if "`w_type'"=="string"{
				loc lwindow : word 1 of `window'
				loc rwindow : word 1 of `window'
			}
			
			if "`w_type'"=="numeric" {
				if  (-`lwindow'<0 | `rwindow'<0) {
					di as err _n "Window can not be negative"
					exit 198
				}
			}
		}
		else if "`window'"=="" & ("`pre'"!="" & "`post'"!="" & "`overidpre'"!="" & "`overidpost'"!="") {
			loc lwindow = `pre' + `overidpre'
			loc lwindow = -`lwindow'
			loc rwindow = `post' + `overidpost' -1 
			loc w_type = "numeric"
		}
		
		* If allowing for anticipation effects, change the normalization if norm is missing, or warn the user
		if ("`pre'"!="0" & "`pre'"!="") {
			if `norm'==-1 {
				loc norm = -`pre'-1
				di as text _n "You allowed for anticipation effects `pre' periods before the event, so the coefficient at `norm' was selected to be normalized to zero. Use options {bf:norm} and {bf:window} to override this."
			}
		}
		
		* Check that normalization is in window
		if "`w_type'"=="numeric" { 
			if (`norm' < `=`lwindow'-1' | `norm' > `rwindow') {
				di as err _n "The coefficient to be normalized to 0 is outside of the estimation window"
				exit 498
			}
		}
		* Do not allow norm and trend 
		if "`norm'" !="-1" & "`trend'" != "" {
			di as err _n "Option {bf:trend} not allowed with a value for option {bf:norm} different from -1."
			exit 198
		}
		*user			
		*if "`trend'"!="" loc trend "trend(`trend')"
		*else loc trend ""

		* Estimate
	
		if "`proxy'" == "" & "`proxyiv'" == "" {
			di as txt _n "No proxy or instruments provided. Implementing OLS estimator"
			cap noi _eventols `varlist' [`weight'`exp'] if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') w_type(`w_type') trend(`trend') savek(`savek') norm(`norm') `reghdfe' addabsorb(`addabsorb') `repeatedcs' cohort(`cohort') control_cohort(`control_cohort') `options' 
			if _rc {
				errpostest `oldvars'
			}
		}
		else {
			di as txt _n "Proxy for the confound specified. Implementing FHS estimator"
			cap noi _eventiv `varlist' [`weight'`exp'] if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') w_type(`w_type') proxyiv(`proxyiv') proxy (`proxy') savek(`savek')    norm(`norm') `reghdfe' addabsorb(`addabsorb') `repeatedcs' `options' 		
			if _rc {
				errpostest `oldvars'
			}
		}		
		* if window was max or balanced, return the found limits 
		if "`w_type'"=="string" {
			loc lwindow = r(lwindow)
			loc rwindow = r(rwindow)
		}
	}
	else if "`static'"=="static" {
		loc lwindow=.
		loc rwindow=.
		di as txt _n "option {bf:static} specified. Estimating static model"
		di as txt _n "Plotting options ignored"
		if "`proxy'" == "" & "`proxyiv'" == "" {
			di as txt _n "No proxy or instruments provided. Implementing OLS estimator"
			cap noi _eventolsstatic `varlist' [`weight'`exp'] if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') `reghdfe' addabsorb(`addabsorb') `repeatedcs' `options' `static'
			if _rc {
				errpostest `oldvars'
			}
		}
		
		else {
			di as txt _n "Proxy for the confound specified. Implementing FHS estimator"
			
			cap noi _eventivstatic `varlist' [`weight'`exp'] if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') proxyiv(`proxyiv') proxy (`proxy') `reghdfe' addabsorb(`addabsorb') `repeatedcs' `options' `static'
			if _rc {
				errpostest `oldvars'
			}
		}
	}
	
	*don't try returning matrices and macros if noestimate is specified 
	loc noestimate = r(noestimate)
	if "`noestimate'"=="." loc noestimate ""
	if "`noestimate'"!="" exit 
	
	if `=r(flagerr)'!=1  {
	
		loc noestimate=r(noestimate)
		if "`noestimate'"=="." loc noestimate ""
		if "`noestimate'"!="" {
			loc savek = r(savek)
			*clear previous estimates, so it will not mix them with the new ones
			ereturn clear 
		}
		
		ereturn scalar lwindow= `lwindow'
		ereturn scalar rwindow=`rwindow'
		if "`pre'"!="" {
			ereturn scalar pre = `pre'
			ereturn scalar post = `post'
			ereturn scalar overidpre = `overidpre'
			ereturn scalar overidpost = `overidpost'
		}
		ereturn local cmdline `"xtevent `0'"' /*"*/
		ereturn local cmd2 "xtevent"
		ereturn local stub = "`savek'"
		ereturn local noestimate = "`noestimate'"
		ereturn local ambiguous = r(ambiguous)
		*don't return the remaining if the user indicated not to estimate  
		if "`noestimate'"!="" exit
	
		mat delta=r(delta)
		mat Vdelta=r(Vdelta)
		mat b = r(b)
		mat V = r(V)
		ereturn repost b=b V=V, esample(`tousegen')
		ereturn matrix delta = delta
		ereturn matrix Vdelta = Vdelta
		if "`=r(method)'"=="iv" {
			mat deltaxsc = r(deltaxsc)
			mat deltaov = r(deltaov)
			mat Vdeltaov = r(Vdeltaov)
			mat deltax = r(deltax)
			mat Vdeltax = r(Vdeltax)
			ereturn matrix deltaxsc = deltaxsc
			ereturn matrix deltaov = deltaov
			ereturn matrix Vdeltaov = Vdeltaov
			ereturn matrix deltax = deltax
			ereturn matrix Vdeltax = Vdeltax
			if `=r(x1)'!=. ereturn local x1 = r(x1)
			
		}
		loc sun_abraham = r(sun_abraham)
		if "`sun_abraham'"=="." loc sun_abraham ""
		if "`sun_abraham'"!="" {
			mat b_interact = r(b_interact)
			mat V_interact = r(V_interact)
			mat ff_w = r(ff_w)
			mat Sigma_ff = r(Sigma_ff)
			ereturn matrix b_interact = b_interact
			ereturn matrix V_interact = V_interact
			ereturn matrix ff_w = ff_w
			ereturn matrix Sigma_ff = Sigma_ff
		}
		
		loc saveov = r(saveov)
		if "`saveov'"=="." loc saveov ""
		if "`saveov'"!="" {
		
			mat mattrendy = r(mattrendy)
			mat mattrendx = r(mattrendx)
			mat deltaov = r(deltaov)			
			mat Vdeltaov = r(Vdeltaov)
			ereturn matrix mattrendy = mattrendy
			ereturn matrix mattrendx = mattrendx
			ereturn matrix deltaov = deltaov
			ereturn matrix Vdeltaov = Vdeltaov
			ereturn local trendsaveov = r(trendsaveov)
		}
		if "`trend'"!="" {
			ereturn local trendmethod = r(trendmethod)
			ereturn local trend = r(trend)
		}
		
		ereturn local names=r(names)
		loc cmd = r(cmd)
		ereturn local cmd = r(cmd)
		ereturn local df = r(df)
		ereturn local komit = r(komit)
		ereturn local kmiss = r(kmiss)
		ereturn local y1 = r(y1)
		ereturn local method = r(method)
		ereturn local depvar = r(depvar)
	}
	else {
		exit 198
	}
	
	if "`plot'"!="" xteventplot

end

* Program to parse window 
program define parsewindow, rclass

	syntax [anything] 
		
	tokenize "`anything'"
	loc nwwindow = wordcount("`anything'")
	if !inlist(`nwwindow',1,2) {
		di as err _n "{bf:window} can only have one or two elements."
		exit 198
	}
	
	*check that all words are numeric or string 
	loc isnum = 0
	forvalues i=1/`nwwindow'{
		cap confirm number ``i''
		if !_rc loc ++ isnum 
	}
	if `isnum'>0 & `isnum'<`nwwindow'{
		di as err _n "Invalid {bf:window} option."
		exit 198
	}
	
	* tell if all words are numeric or strings 
	if `isnum' == 0 loc w_type ="string"
	if `isnum' == `nwwindow' loc w_type ="numeric"
	
	* if all words are numbers, check that they are integers 
	if "`w_type'"=="numeric" {
		loc isnotint = 0
		forvalues i=1/`nwwindow'{
			cap confirm integer number ``i''
			if _rc!=0 loc ++ isnotint 
		}
		if `isnotint'>0 {
			di as err _n "Number in {bf:window} must be integer."
			exit 126
		}
	}
	
	* if all words are string, check that it is only one word and it is a valid option name 
	if "`w_type'"=="string" {
		
		if `nwwindow'>1 {
			di as err _n "If string, {bf:window} must have only one element."
			exit 198
		}
		
		if `nwwindow'==1 {
			if !inlist("`anything'","max","balanced"){
				di as err _n "{bf:window} must be {bf:max} or {bf:balanced}."
				exit 198
			}
		}
		
	}

	return local swindow "`anything'"
	return local w_type "`w_type'"
end	

program define cleanup

	syntax [anything]

	loc oldvars = "`anything'"

	foreach x in _k_eq* _ttrend* __k* _f* _interact* {
		cap unab todrop: `x'		
		loc todrop: list local todrop - oldvars
		cap drop `todrop'
		loc todrop ""	
		
	}
	cap _estimates clear
end

program define errpostest, rclass
	
	syntax [anything]

	cleanup `anything' _rc	
	return local flagerr=1
end




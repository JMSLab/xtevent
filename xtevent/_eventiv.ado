version 11.2

cap program drop _eventiv
program define _eventiv, rclass
	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in], /* Covariates go in varlist. Can add fv ts later */
	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */
	POLicyvar(varname) /* Policy variable */
	LWindow(integer) /* Estimation window. Need to set a default, but it has to be based on the dataset */
	RWindow(integer)
	proxy (varlist numeric) /* Proxy variable(s) */
	[
	proxyiv(string) /* Instruments. Either numlist with lags or varlist with names of instrumental variables */
	nofe /* No fixed effects */
	note /* No time effects */
	SAVek(string) /* Generate the time-to-event dummies, trend and keep them in the dataset */	
	nogen /* Do not generate k variables */
	kvars(string) /* Stub for event dummies to include, if they have been generated already */		
	norm(integer -1) /* Normalization */	
	reghdfe /* Use reghdfe for estimation */	
	impute(string) /*imputation on policyvar*/
	*static /* in this ado used for calling the part of _eventgenvars that imputes*/
	addabsorb(string) /* Absorb additional variables in reghdfe */ 
	REPeatedcs /*indicate that the input data is a repeated cross-sectional dataset*/
	*
	]
	;
	#d cr
	
	marksample touse
		
	tempname delta Vdelta bb VV bb2 VV2 delta2 Vdelta2 deltaov Vdeltaov deltax Vdeltax deltaxsc bby bbx VVy VVx tousegen
	* bb delta coefficients
	* VV variance of delta coefficients
	* bb2 delta coefficients for overlay plot
	* VV2 variance of delta coefficients for overlay plot
	* delta2 included cefficientes in overlaty plot
	* VVdelta2 variance of included delta coefficients in overlay plot
	
	* For eventgenvars, ignore missings in varlist
	mark `tousegen' `if' `in'
	
	loc i = "`panelvar'"
	loc t = "`timevar'"
	loc z = "`policyvar'"

	*parse savek 
	if "`savek'"!="" parsesavek `savek'
	loc savek = r(savekl)
	if "`savek'"=="." loc savek ""
	return loc savek = "`savek'"
	loc noestimate = r(noestimatel)
	if "`noestimate'"=="." loc noestimate ""
	return loc noestimate = "`noestimate'"
	
	*If imputation is specified, _eventiv will call _eventgenvars twice.
	*The first call only imputes the policyvar, but the second call imputes both the policyvar and the event-time dummies
	*First call: bring the imputed policyvar calling only _eventgenvars' imputation code. This call is neccesary to choose the lead order using the imputed policyvar
	if "`impute'"!=""{
		*rr is the tempvar to be imputed: create it in _eventiv, so after _eventgenvars we can still have access to it.
		tempvar rr
		qui gen double `rr'=.

		*call _eventgenvars
		_eventgenvars if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') impute(`impute') static rr(`rr') `repeatedcs' //with option static, we skip the code that generates the event-time dummies 

		loc impute=r(impute)
		if "`impute'"=="." loc impute = ""
		*if imputation succeeded, use the values brought by rr
		if "`impute'"!="" {
			tempvar zimp
			qui gen double `zimp'=`rr'
			loc z="`zimp'"
		} 
		*otherwise, keep using the original policyvar 
		else loc z = "`policyvar'"
	}
	
	* if dataset is repeated cross-sectional, create leads of policyvar at state level
	if "`repeatedcs'"!=""{
		qui {
			preserve 
			tempfile state_level_leads
		
			keep if `touse'
			keep `panelvar' `timevar' (`z')
			bysort `panelvar' `timevar' (`z'): keep if _n==1
			xtset `panelvar' `timevar'
			forv v=1(1)`=-`lwindow''{
				tempvar _fd`v'`z'
				qui gen double `_fd`v'`z'' = f`v'.d.`z' 
			}
			save `state_level_leads'
		
			restore

		*merge on the policyvar as well, so missing values in policyvar within a cell will not get lead values
			merge m:1 `panelvar' `timevar' `z' using `state_level_leads', update nogen
		}
	}
	
	loc leads : word count `proxy'
	if "`proxyiv'"=="" & `leads'==1 loc proxyiv "select"
	
	* If proxy specified but no proxyiv, assume numlist for leads of policyvar
	if "`proxyiv'"=="" {
		di as text _n "No proxy instruments specified. Using leads of differenced policy variables as instruments."
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
			forv v=1(1)`=-`lwindow'' {
				if "`repeatedcs'"=="" {
					tempvar _fd`v'`z'
					qui gen double `_fd`v'`z'' = f`v'.d.`z' if `touse'
				}
				qui reg `proxy' `_fd`v'`z'' if `touse'
				loc Floop = e(F)
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
	loc ivwords = 0
	foreach v in `proxyiv' {
		cap confirm integer number `v'
		if _rc loc ++rc
		loc ++ivwords
	}
	
	* Three possible types of lists: all numbers for leads, all vars for external instruments, or mixed
	* All numbers
	if `rc' == 0 {
		loc leadivs ""
		foreach v in `proxyiv' {
			if "`repeatedcs'"!=""{
				qui gen double _fd`v'`z' = `_fd`v'`z'' if `touse'
			}
			else{
				qui gen double _fd`v'`z' = f`v'.d.`z' if `touse'
			}
			loc leadivs "`leadivs' _fd`v'`z'"
		}
		loc instype = "numlist"		
		loc varivs = ""
	}
	* All words
	else if `rc'==`ivwords' {
		foreach v in `proxyiv' {
			confirm numeric variable `v'
		}
		loc instype = "varlist"
		loc leadivs = "" 
		loc varivs = "`proxyiv'"
	}
	* Mixed
	else {
		loc leadivs ""
		loc varivs ""
		foreach v in `proxyiv' {
			cap confirm integer number `v'
			if _rc loc varivs "`varivs' `v'"
			else {
				if "`repeatedcs'"!=""{
					qui gen double _fd`v'`z' = `_fd`v'`z'' if `touse'
				}
				else{
					qui gen double _fd`v'`z' = f`v'.d.`z' if `touse'
				}
				loc leadivs "`leadivs' _fd`v'`z'"
			}
		}
		
		loc instype "mixed"
	}	
		
	* Count normalizations and set omitted coefs for plot accordingly
	* Need one more normalization per IV
	loc komit ""
	loc norm0 "`norm'"

	*split proxyiv into two lists: only numbers or only varnames 
	loc proxyiv_numbers ""
	loc proxyiv_vrnames ""
	foreach v in `proxyiv' {
		cap confirm number `v'
		if !_rc loc proxyiv_numbers "`proxyiv_numbers' `v'"
		else loc proxyiv_vrnames "`proxyiv_vrnames' `v'"
	}
	foreach v in `proxyiv_numbers' {
		cap confirm integer number `v'
		if _rc {
			di as err "Lead of policy variable to be used as instrument must be an integer."
			exit 301
		}
	}
	* Set normalizations in case these are numbers, so we are using leads of delta z
	loc ivnorm ""
	if "`instype'"=="numlist" | "`instype'"=="mixed" {
		foreach v in `proxyiv_numbers' {
			if `=-`v''==`norm' {
				loc ivnorm "`ivnorm' `=-`v'-1'"
				di as txt _n "The corresponding coefficient of lead `v' and the normalized coefficient were the same. Lead `=`v'' has been changed to `=`v'+1'."
				loc repeatlead=strmatch("`proxyiv_numbers'","*`=`v'+1'*")
				if "`repeatlead'"=="0"{
					di as txt _n "The coefficient at `norm' is normalized to zero."
					di as txt _n "For estimation with proxy variables, an additional coefficient needs to be normalized to zero." 
					di as txt _n "The coefficient at `=-`v'-1' was selected to be normalized to zero."
				}
			}
			else {
				loc ivnorm "`ivnorm' -`v'"	
				di as txt _n "The coefficient at `norm' is normalized to zero."
				di as txt _n "For estimation with proxy variables, an additional coefficient needs to be normalized to zero." 
				di as txt _n "The coefficient at `=-`v'' was selected to be normalized to zero."
			}
		}
	}
	
	
	*set normalizations for external instruments 
	*get the pool of available coefficients for normalization
	loc available ""
	forvalues l=1/`=-`lwindow'+1'{
		loc l = -`l'
		loc available "`available' `l'"
	}
	loc available: list available - norm 
	foreach var of loc proxyiv_vrnames{
		loc available: list available - ivnorm
		loc lenav: word count(`available')
		if `lenav'==1 {
			di as err "Number of instruments specified in {bf:proxyiv} reached the maximum imposed by the number of pre-event periods."
			exit 301
		}
		*normalize one extra coefficient per external instrument 
		loc avcomma : subinstr loc available " " ",", all
		loc avmax = max(`avcomma') //choose the coefficient closest to zero 
		loc ivnorm "`ivnorm' `avmax'" // add it to ivnorm 
		di as text _n "The coefficient at `avmax' was selected to be normalized to zero"
	}
	
	* Normalize one more lag if normalization = number of proxys
	if "`instype'"=="numlist" | "`instype'"=="mixed" {
		loc np: word count `proxy' 
		* loc npiv: word count `norm' `ivnorm'
		loc npiv : list norm | ivnorm
		loc npiv : list uniq npiv
		loc npiv : word count `npiv'
		if `np'==`npiv' {
			loc ivnormcomma : subinstr local ivnorm " " ",", all
			loc ivmin = min(`ivnormcomma')
			loc ivnorm "`ivnorm' `=`ivmin'-1'"
		}
	}
		
	* No need to normalize for external instruments. If the user generates a lead of z and uses it as a variable, the instrument is collinear.
	
	foreach j in `norm' `ivnorm' {
		loc norm "`norm' `j' "
		loc komit "`komit' `j'"
	}
	loc komit: list uniq komit		
	
	if "`gen'" != "nogen" {	
		*If impute was specified, this is the second call to _eventgenvars: this time, both the policyvar and the event-time dummies will be imputed. Additional computations will happen as well  (e.g., macros, etc.).
		_eventgenvars if `tousegen', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') `trend' norm(`norm') impute(`impute') `repeatedcs'
		loc included=r(included)
		loc names=r(names)	
		loc komittrend=r(komittrend)
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
				clonevar `sub' = `var'
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
		loc komittrend=r(komittrend)
		if "`komittrend'"=="." loc komittrend = ""	
	}		
	*"
	loc komit "`norm' `komittrend'"
	loc komit = strtrim(stritrim("`komit'"))
	loc komit: list uniq komit	
	
	* Check that the iv normalization works
	
	foreach v in `leadivs' `varivs' {
		cap _rmdcoll `v' `included' if `touse'
		if _rc {
			di as err "Instrument {bf:`v'} is collinear with the included event-time dummies. You may have generated leads of the policy variable and included them in the proxyiv option instead of specifying the lead numbers."
			exit 301
		}
	}
	
	if "`te'" == "note" loc tte ""
	else loc tte "i.`t'"
	
	**** Main regression
	
	** In the repeated cross section case with fixed effects, cannot use xtivreg, so default to reghdfe
	
	if "`repeatedcs'"!="" & "`fe'"!="nofe" {		
		loc reghdfe = "reghdfe"
		di as text _n "Using {cmd:reghdfe} for fixed effects estimation with repeated cross-sectional data."
	}
	
	if "`noestimate'"==""{
		if "`reghdfe'"=="" {
			
			if "`fe'" == "nofe" {
				loc cmd "ivregress 2sls"
				loc ffe ""
				loc small "small"
			}
			else {
				loc cmd "xtivreg"
				loc ffe "fe"
			}
			*translate standard error specification:
			*analyze inclusion of cluster or robust in options
			parse_es ,`options'
			foreach orig in cl_orig rob_orig vce_orig other_opts{
				loc `orig' = r(`orig')
				if "``orig''"=="." loc `orig' ""
			}
			*if xtivreg, warn the user about robust estandar errors equivalent to vce(cluster panelvar)
			if "`cmd'"=="xtivreg" & (("`vce_orig'"=="robust" | "`vce_orig'"=="r") | "`rob_orig'"!=""){
				di as text _n "You asked for robust standard errors and the underlying estimation command is {cmd:xtivreg}. Standard errors will be clustered by panelvar. See {help xtivreg##options_fe:xtivreg}."
			}
			*if it doesn't contain cluster and robust:
			if "`cl_orig'"=="" & "`rob_orig'"=="" {
				`cmd' `varlist' (`proxy' = `leadivs' `varivs') `included' `tte' [`weight'`exp'] if `touse' , `ffe' `small' `options'
			}
			*if it contains either cluster or robust:
			else{
				*if the user already specified vce, then we cannot specify a second vce 
				if "`vce_orig'"!="" {
					*execute as defined by the user and expect some error 
					`cmd' `varlist' (`proxy' = `leadivs' `varivs') `included' `tte' [`weight'`exp'] if `touse' , `ffe' `small' `options'
				}
				else{
					loc vce_opt ""
					*parse cluster
					if "`cl_orig'"!=""{
						loc vce_opt = "vce(cluster `cl_orig')" //if robust is also specified, no need to add it
					}
					else {
						loc vce_opt = "vce(robust)"
					}
					`cmd' `varlist' (`proxy' = `leadivs' `varivs') `included' `tte' [`weight'`exp'] if `touse' , `ffe' `small' `vce_opt' `other_opts'
				}
			}
		}
		else {
			loc noabsorb "" 
			*absorb nothing
			if "`fe'" == "nofe" & "`tte'"=="" & "`addabsorb'"=="" {
				*loc noabsorb "noabsorb"
				/*the only option ivreghdfe inherits from reghdfe is absorb, therefore it doesn't support noabsorb. In contrast with reghdfe, ivreghdfe doesn't require noabsorb when absorb is not specified*/ 
				loc abs ""
			}
			*absorb only one
			else if "`fe'" == "nofe" & "`tte'"=="" & "`addabsorb'"!="" {
				loc abs "absorb(`addabsorb')"
			}
			else if "`fe'" == "nofe" & "`tte'"!="" & "`addabsorb'"=="" {						
				loc abs "absorb(`t')"
			}
			else if "`fe'" != "nofe" & "`tte'"=="" & "`addabsorb'"=="" {						
				loc abs "absorb(`i')"
			}
			*absorb two
			else if "`fe'" == "nofe" & "`tte'"!="" & "`addabsorb'"!="" {						
				loc abs "absorb(`t' `addabsorb')"
			}
			else if "`fe'" != "nofe" & "`tte'"=="" & "`addabsorb'"!="" {						
				loc abs "absorb(`i' `addabsorb')"
			}
			else if "`fe'" != "nofe" & "`tte'"!="" & "`addabsorb'"=="" {						
				loc abs "absorb(`i' `t')"
			}
			*absorb three
			else if "`fe'" != "nofe" & "`tte'"!="" & "`addabsorb'"!="" {						
				loc abs "absorb(`i' `t' `addabsorb')"
			}
			*
			else {
				loc abs "absorb(`i' `t' `addabsorb')"	
			}
			
			*analyze inclusion of vce in options
			loc vce_y= strmatch("`options'","*vce(*)*")
			
			*if user did not specify vce option 
			if "`vce_y'"=="0" { 
			ivreghdfe `varlist' (`proxy' = `leadivs' `varivs') `included' [`weight'`exp'] if `touse', `abs' `noabsorb' `options'
			}
			*if user did specify vce option
			else {  
				*find start and end of vce text 
				loc vces=strpos("`options'","vce(")
				loc vcef=0
				loc ocopy="`options'"
				while `vcef'<`vces' {
					loc vcef=strpos("`ocopy'", ")")
					loc ocopy=subinstr("`ocopy'",")", " ",1)
				}
				*substrac vce words
				loc svce_or=substr("`options'",`vces',`vcef')
				loc vce_len=strlen("`svce_or'")
				loc svce=substr("`svce_or'",5,`vce_len'-5)
				loc svce=strltrim("`svce'")
				loc svce=strrtrim("`svce'")
				*inspect whether vce contains bootstrap or jackknife
				loc vce_bt= strmatch("`svce'","*boot*")
				loc vce_jk= strmatch("`svce'","*jack*")
				if `vce_bt'==1 | `vce_jk'==1 {
					di as err "Options {bf:bootstrap} and {bf:jackknife} are not allowed"
					exit 301
				}
				
				*if vce contains valid options, parse those options
				*erase vce from original options
				loc options_wcve=subinstr("`options'","`svce_or'"," ",1)
				*** parse vce(*) ****
				loc vce_wc=wordcount("`svce'")
				tokenize `svce'
				*extract vce arguments 
				*robust 
				loc vce_r= strmatch("`svce'","*robust*")
				loc vce_r2=0
				forv i=1/`vce_wc'{
					loc zz= strmatch("``i''","r")
					loc vce_r2=`vce_r2'+`zz'
				}
				if `vce_r'==1 | `vce_r2'==1 {
					loc vceop_r="robust"
				}
				*cluster
				loc vce_c= strmatch("`svce'","*cluster*")
				loc vce_c2= strmatch("`svce'","*cl*")
				if `vce_c'==1 | `vce_c2'==1 {
					forv i=1/`vce_wc'{
						loc vce_r2= strmatch("``i''","*cl*")
						if `vce_r2'==1 {
							loc j=`i'+1
							}
					}
					loc vceop_c="cluster(``j'')"
				}
				
				ivreghdfe `varlist' (`proxy' = `leadivs' `varivs') `included' [`weight'`exp'] if `touse', `abs' `noabsorb' `options_wcve' `vceop_r' `vceop_c'
			}
		}
	
		*clear xtset if repeatedcs and xtivreg, otherwise error message because timevar not setted
		if ("`repeatedcs'"!="" & "`cmd'"=="xtivreg") qui xtset, clear
		
		* Return coefficients and variance matrix of the delta k estimates separately
		mat `bb'=e(b)
		mat `VV'=e(V)
		
		mat `delta' = `bb'[1,`names']
		mat `Vdelta' = `VV'[`names',`names']
			
		if "`reghdfe'"=="" {
			if "`fe'" == "nofe" {
				loc df=e(df_r)
			}
			else {
				loc df=e(df_rz)
			}
		}
		else {
			loc df=e(df_r)
			if `df'==. loc df=e(Fdf2)
		}
	
		loc kmax=`=`rwindow'+1'
		loc kmin=`=`lwindow'-1'
		
		tempvar esample
		gen byte `esample' = e(sample)
	
		
		* Plots	
		
		* Calculate mean before change in policy for 2nd axis in plot
		* This needs to be relative to normalization
		tempvar temp_k
		loc absnorm=abs(`norm0')
		qui gen `temp_k'=_k_eq_m`absnorm' 
		
		tokenize `varlist'
		qui su `1' if `temp_k'!=0 & `temp_k'!=. & `esample', meanonly
		loc y1 = r(mean)
		loc depvar "`1'"	
	
		*  Calculate mean proxy before change in policy for 2nd axis in plot
		if "`proxy'"!="" {
			loc nproxy: word count `proxy'
			if `nproxy' ==1 {
				qui su `proxy' if `temp_k'!=0 & `temp_k'!=. & `esample', meanonly
				loc x1 = r(mean)
			}
			else loc x1 = .
		}
		

		* Variables for overlay plots
		
		* Need the ols estimates for y and x
		* Do not exclude vars other than m1
		*loc toexc = "_k_eq_m1"
		*unab included2: _k_eq_*
		*loc included2 : list included2 - toexc
		
		_estimates hold main
		
		qui _eventols `varlist' [`weight'`exp'] if `touse' , panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') `fe' `te' nogen nodrop kvars(_k) norm(`norm0') impute(`impute')
		mat `deltaov' = r(delta)
		mat `Vdeltaov' = r(Vdelta)
		*mat `deltay' = `bby'[1,${names}]
		*mat `Vdeltay' = `VVy'[${names},${names}]
		qui _eventols `proxy' [`weight'`exp'] if `touse', panelvar(`panelvar') timevar(`timevar') policyvar(`policyvar') lwindow(`lwindow') rwindow(`rwindow') `fe' `te' nogen nodrop kvars(_k) norm(`norm0') impute(`impute')
		mat `deltax' = r(delta)
		mat `Vdeltax' = r(Vdelta)		
		*mat `deltax' = `bb'[1,${names}]
		* mat `Vdeltax' = `VV'[${names},${names}]
		* Scaling factor
		loc ivnormcomma = strtrim("`ivnorm'")
		loc ivnorms : list sizeof ivnormcomma
		loc ivnormcomma : subinstr local ivnormcomma " " ",", all
		if `ivnorms'>1 loc scfactlead = -max(`ivnormcomma')
		else loc scfactlead = -`ivnormcomma'
		mat Mfn = `deltaov'[1,"_k_eq_m`scfactlead'"]	
		mat Mfd = `deltax'[1,"_k_eq_m`scfactlead'"]
		loc fn = Mfn[1,1]
		loc fd = Mfd[1,1]
		loc factor = `fn'/`fd'
		* Scale x estimates by factor
		mat `deltaxsc' = `factor'*`deltax'	
	}
	
	* Drop variables
	if "`savek'" == "" {
		cap confirm var _k_eq_p0
		if !_rc drop _k_eq*	
		cap confirm var __k
		if !_rc qui drop __k
		if "`trend'"!="" qui drop _ttrend		
	}
	else {
		ren __k `savek'_evtime
		ren _k_eq* `savek'_eq*
		if "`trend'"!="" ren _ttrend `savek'_trend	
	}
	if "`instype'"=="numlist" | "`instype'"=="mixed" {
		foreach v in `leadivs' {
			drop `v'
		}
	}
	
	*skip the rest of the program if the user indicated not to estimate
	if "`noestimate'"!="" exit 
	
	* Returns
	
	_estimates unhold main
	
	return matrix b = `bb'
	return matrix V = `VV'
	return matrix delta = `delta'
	return matrix Vdelta = `Vdelta'
	return matrix deltaov = `deltaov'
	return matrix Vdeltaov = `Vdeltaov'
	return matrix deltax = `deltax'
	return matrix Vdeltax = `Vdeltax'
	return matrix deltaxsc = `deltaxsc'
	loc names: subinstr local names ".." " ", all
	loc names: subinstr local names `"""' "", all
	return local names = `"`names'"'
	* "	
	return local cmd = "`cmd'"	
	return local df = `df'
	return local komit = "`komit'"
	return local kmiss = "`kmiss'"
	return local y1 = `y1'
	return local depvar = "`depvar'"
	if `x1'!=. return local x1 = `x1'
	return local method = "iv"
	
end

*program to parse savek
program define parsesavek, rclass

	syntax [anything] , [NOEstimate]
		
	return local savekl "`anything'"
	return local noestimatel "`noestimate'"
end	

*program to parse standar error specification 
program define parse_es, rclass
	#d;
	syntax [anything], 
	[
	CLuster(varname) 
	Robust
	vce(string)
	*
	]
	;
	#d cr
	return local cl_orig "`cluster'"
	return local rob_orig "`robust'"
	return local vce_orig "`vce'"
	return local other_opts "`options'"
end	


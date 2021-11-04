* _eventgenvars.ado 1.00 Aug 24 2021

version 11.2

cap program drop _eventgenvars
program define _eventgenvars, rclass

	#d;
	syntax [anything] [if] [in],
	panelvar(varname) /* Panel variable */	
	timevar(varname) /* Time variable */
	policyvar(varname) /* Policy variable */
	lwindow(real)
	rwindow(integer) /* Estimation window. Need to set a default, but it has to be based on the dataset */
	norm(numlist) /* Coefficients to normalize */
	[
	trend(string) /* Lower limit for trend */	
	nostaggered /* Calculate endpoints without staggered adoption assumption, requires z */
	]	
	;
	#d cr	
	
	tempvar mz mz2 kg
	
	marksample touse
	
	* mz maximum of policy outside window
	* kg grouped event time variable, grouping dummies outside window
	
	loc z = "`policyvar'"
	
	* Get span of calendar time
	qui su `timevar' if `touse', d
	loc tmin=r(min)
	loc tmax=r(max)
	loc tdiff = `tmax'-`tmin'
	
	* Using notation from latest draft 
	
	* Endpoints are left: G+L+1
	* Right: M+1
	
	* Left window is G+L
	* Right window is M 
	
	* If you have t=-3 -2 -1 0 1 2 3, tdiff=6 then the maximum window size you can have is 2 on each side
	* If you have t=-3 -2 -1 0 1 2 3 4, tdiff=7 then the maximum window size you can have is 2 left, 3 right
		
	
	* Error check for window outside event time range
	if abs(`lwindow') > `=abs(`tdiff')-1' | abs(`rwindow') > `=abs(`tdiff')-1' {
		di as err _n "Window outside event-time range."
		exit 301
	}
	
	* Error check for trend event time range
	if "`trend'"!="" {
		if abs(`trend') > `=abs(`tdiff')-1' {
			di as err _n "Trend outside time range."
			exit 301
		}
				
		* Error check for trend outside window
		if abs(`trend')>abs(`lwindow') {
			di as err _n "Trend outside window range."
			exit 301
		}
	}
	
	* Check for vars named _k
	cap unab oldkvars : _k*
	if !_rc {
		di as err _n "You have variable names with the _k prefix. _k is reserved for internal -xtevent- variables."
		di as err _n "Please rename these variables before proceeding."
		exit 110
	}
	
	* Check if z is binary
	cap assert inlist(`z',0,1,.) if `touse'
	if _rc {
		qui su `z' if `touse'
		cap assert inlist(`z',0,`=r(max)')
		if !_rc loc bin 1
		else loc bin 0
	}
	else loc bin 1
	
	* If not binary default to nostaggered adoption
	if `bin'==0 {
		loc staggered ="nostaggered"
		di "The policy variable is not binary. Assuming no staggered adoption."
		di "If event dummies and variables are saved, event-time will be missing."		
	}
	
	
	qui xtset `panelvar' `timevar', noquery
	
	qui sort `panelvar' `timevar', stable
		
	* Generate event time dummies 
	* First I generate all possible event time dummies to have event time for the trend regressions, then I keep only the ones in the window.
	* While inefficient, this allows me to have event-time outside the window 
	* Fix: This is too inefficient for large datasets. Only generate in window
	* quietly forv klevel=-`tdiff'(1)`tdiff' {
	qui forv klevel=`lwindow'(1)`rwindow' {
		loc absk = abs(`klevel')
		
		if `klevel'<0 { 
			loc plus = "m"
			* bys `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=`z'[_n+`absk']-`z'[_n+`absk'-1] if `touse'
			by `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=F`absk'.`z'-F`=`absk'-1'.`z' if `touse'
			la var _k_eq_`plus'`absk' "Event-time = - `absk'"
		}		
		else {
			loc plus "p" 
			* bys `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=`z'[_n-`absk']-`z'[_n-`absk'-1] if `touse'		 
			by `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=L`absk'.`z'-L`=`absk'+1'.`z' if `touse'
			la var _k_eq_`plus'`absk' "Event-time = + `absk'"
		}
		
		if "`staggered'"=="" {
			if `klevel'>=0 {	
				* bys `panelvar' (`timevar'): replace _k_eq_`plus'`absk'=`z'[_n-`klevel'] if _k_eq_`plus'`absk'==. & `touse'
				by `panelvar' (`timevar'): replace _k_eq_`plus'`absk'=L`klevel'.`z' if _k_eq_`plus'`absk'==. & `touse'
			}		
		}
		
		qui replace _k_eq_`plus'`absk'=0 if _k_eq_`plus'`absk'==. & `touse'	
		
		
	}
	
	* Generate event time
	* To fix: If multiple events, should generate all.
	qui {
		if "`staggered'"=="" {
			tempvar __kmax __kind
			gen __k=.
			by `panelvar': gen `__kind' = `timevar' if _k_eq_p0 == 1
			egen `__kmax' = max(`__kind'), by(`panelvar')
			replace __k = `timevar' - `__kmax'
		}
		else if "`staggered'"=="nostaggered" {
			qui gen __k=.
		}
	}
				
	* Error check for window outside event time range
	qui sum __k if `touse'
	if `=-`lwindow'+1' > abs(r(min)) | `=`rwindow'+1' > abs(r(max)) {
		di as err _n "Window outside event-time range"
		qui drop _k*
		qui drop __k
		exit 301
	}
		
	
	* Generate endpoint dummies
	* Left
	* -6 : z lead 6
	* +5 : z lag 5
	
	* Absorbing version
	if "`staggered'"=="" {
		qui {
			* Left
			gen _k_eq_m`=-`lwindow'+1' = (1-f`=-`lwindow''.`z') if `touse'
			replace _k_eq_m`=-`lwindow'+1' = 0 if _k_eq_m`=-`lwindow'+1' == . & `touse'
			by `panelvar' (`timevar'): egen double `mz' = max(`z') if `touse'
			replace _k_eq_m`=-`lwindow'+1' =0 if `mz'==0 & `touse'
			drop `mz'
			order _k_eq_m`=-`lwindow'+1', before(_k_eq_m`=-`lwindow'')
			
			* Right
			
			egen double `mz' = rowmax(_k_eq_m`=-`lwindow'+1'-_k_eq_p`=`rwindow'') if `touse'
			gen _k_eq_p`=`rwindow'+1'= 1-`mz' if `touse'
			by `panelvar' (`timevar'): egen `mz2' = max(`z') if `touse'		
			replace _k_eq_p`=`rwindow'+1'=0 if `mz2'==0 & `touse'
			drop `mz'
			drop `mz2'	
			order __k, after(_k_eq_p`=`rwindow'+1')			
		}	
	}
	* Not absorbing version
	else if "`staggered'"=="nostaggered" {
		qui {
			* Left
			gen _k_eq_m`=-`lwindow'+1' = (1-f`=-`lwindow''.`z') if `touse'
			order _k_eq_m`=-`lwindow'+1', before(_k_eq_m`=-`lwindow'')
			* Right
			gen _k_eq_p`=`rwindow'+1'= l`=`rwindow'+1'.`z' if `touse'			
			order __k, after(_k_eq_p`=`rwindow'+1')
		}
	}
	
	la var _k_eq_m`=-`lwindow'+1' "Event time <= - `=-`lwindow'+1'"
	la var _k_eq_p`=`rwindow'+1' "Event time >= + `=`rwindow'+1'"
	
	* Drop units where treatment can not be timed
	
	* If z is binary, check if event-time is missing
	if `bin' & "`staggered'"=="" {
		cap assert __k !=. if `touse'
		* If it is, check for which units
		if _rc {
			tempvar etmis etmismax minz
			qui {
				gen byte `etmis' = (__k==.) & `touse'
				by `panelvar' : egen byte `etmismax' = max(`etmis') if `touse'
				by `panelvar' : egen double `mz' = max(`z') if `touse'
				by `panelvar' : egen double `minz' = min(`z') if `touse'
			}
			* Exclude units with missing event-time
			foreach x of varlist _k_eq* {
				qui replace `x' = . if `etmismax'==1 & `mz'>0 & `minz'==0 & `touse'
			}
			qui replace __k = . if `etmismax'==1 & `touse'
			qui levelsof `panelvar' if `etmismax'==1 & `mz'>0 & `minz'==0 & `touse', loc(mis)
			foreach j in `mis' {
				di as txt _n "Unit `j' not used because of ambiguous event-time due to missing values in policyvar."
			}
			qui replace `touse' = 0 if `etmismax'==1 & `mz'>0 & `minz'==0 & `touse'			
		}
	}	
		
	* Set omitted variable.
	unab included : _k*
	loc toexc ""
	foreach j in `norm' {
		loc abs = abs(`j')
		if `j'<0 loc toexc "`toexc' _k_eq_m`abs'"
		else if `j'>=0 loc toexc "`toexc' _k_eq_p`abs'"
	}
	loc included: list local included - toexc
	
	* Group k
	qui gen `kg' = __k if `touse'
	* Group if outside window
	qui replace `kg' = `=`lwindow'-1' if __k < `=`lwindow'' & `touse'
	qui replace `kg' = `=`rwindow'+1' if __k >= `rwindow' & `touse'
	qui levelsof `kg', loc(kgs)
	
	* If extrapolating a linear trend, exclude some of the event time dummies
	loc komittrend ""
	* di "`included'"
	if "`trend'" != "" {
		if `bin'!=1 {
			di as err _n "Cannot extrapolate linear trend with non-binary policyvar."
			exit 301
		}
	
		* Generate the trend		
		qui gen _ttrend = __k  if `touse'	
		qui replace _ttrend = 0 if !inrange(_ttrend,`lwindow',`=`rwindow'') & `touse'
		* qui replace _ttrend = 0 if _ttrend<`=`trend'' & `touse'
		qui replace _ttrend = 0 if mi(_ttrend) & `touse'
		la var _ttrend trend
		
		
		* Exclude the coefficients that are restricted: Those on the negative values of the trend range, plus the endpoints
		
		loc komittrend ""	
		
		foreach klevel in `kgs' {
			if (inrange(`klevel',`trend',-1) & `klevel' != -1) {
				loc absk = abs(`klevel')
				if `klevel'<0 loc plus = "m"
				else loc plus "p"
				loc l`plus'`absk' "`plus'`absk'"
				loc toexc "_k_eq_`l`plus'`absk''"
				loc included: list included - toexc
				loc komittrend = "`komittrend' `klevel'"				
			}
		*noi di "***"
		*noi di "`included'"
		}
		* loc toexc: word 1 of `included'
		*loc included: list local included - toexc
		*loc total: word count `included'
		*loc toexc: word `total' of `included'
		*loc included: list local included - toexc
		* di "`included'"
	}	
	
	* Save the names of included reg vars to extract these coefficients from the overall matrix later
	
	loc j=1
	loc names ""
	foreach var in `included' {
		if `j'==1 loc names `""`var'""'
		else loc names `"`names'.."`var'""'
		loc ++ j
	}	
	return local included = "`included'"
	return local names = `"`names'"'
	return local komittrend= "`komittrend'"	
end






	
	
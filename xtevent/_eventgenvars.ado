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
	stag /* Imputes outside missing values of z assuming staggered adoption*/
	nuchange /* Impute outside missing values of z*/
	instag /* impute outer and inner missing values */
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
	
********************* find first and last observed values *********************
	*find minimum valid time
	cap drop zmint zmint2 zminv zminv2
	by `panelvar' (`timevar'): egen zmint=min(`timevar') if !missing(`z') & `touse'
	by `panelvar' (`timevar'): egen zmint2=min(zmint)
	*find minimum valid value
	by `panelvar' (`timevar'): gen zminv=`z' if `timevar'==zmint2 
	by `panelvar' (`timevar'): egen zminv2=min(zminv)

	*find maximum valid time
	cap drop zmaxt zmaxt2 zmaxv zmaxv2
	cap by `panelvar' (`timevar'): egen zmaxt=max(`timevar') if !missing(`z') & `touse'
	cap by `panelvar' (`timevar'): egen zmaxt2=max(zmaxt)
	*find maximum valid value
	cap by `panelvar' (`timevar'): gen zmaxv=`z' if `timevar'==zmaxt2 
	cap by `panelvar' (`timevar'): egen zmaxv2=max(zmaxv)

	*create a copy of z. If imputation happens, it will be on this copy
	cap drop zn2 
	gen zn2=`z'
	order zn2, after(`z')
	

********** check consistency with staggered adoption *******************
	
	tempvar zn l1 notmiss   
	
	****** Check if z is binary
	cap assert inlist(`z',0,1,.) if `touse'
	if _rc {
		qui su `z' if `touse'
		cap assert inlist(`z',`=r(min)',`=r(max)',.) 
		if !_rc loc bin 1
		else loc bin 0
	}
	else loc bin 1

	* If not binary default to nostaggered adoption & no_unobserved_change cannot be applied
	if `bin'==0 & "`stag'"=="stag" {
		
		di "The policy variable is not binary. Assuming no-staggered adoption."
		di "If event dummies and variables are saved, event-time will be missing."	
		loc stag =""
	}
	
	
	****** verify no reversion (once reached 1, never returns to zero)
	tempvar zr
	gen `zr'=`z'
	cap by `panelvar' (`timevar'): replace `zr'=`zr'[_n-1] if missing(`zr') & `timevar'>=zmint2 & `timevar'<=zmaxt2 
	
	loc norever 0
	cap by `panelvar' (`timevar'): gen `l1'= (F1.`zr'>=`zr') if !missing(`zr') & !missing(F1.`zr') & `touse'
	cap assert `l1'==1 if !missing(`l1')
	if ! _rc{
		loc norever 1
	}
	else loc norever 0
	
	if `norever'==0 & "`stag'"=="stag" {
		di "Some units fail to follow the staggered pattern of no reversion. Assuming no-staggered adoption."
		loc stag=""
	}

	
	****** if no-reversion holds, verify "bounds" condition: 0 as the first observed and 1 as the last observed 
	cap drop `notmiss'
	cap gen `notmiss'=!missing(`z')
	*order `notmiss', after(`z')
	
	cap drop zt
	cap by `panelvar' (`timevar'): gen zt=`timevar' if `notmiss'==1 &  `touse'
	cap drop minzt maxzt
	cap by `panelvar' (`timevar'): egen maxzt=max(zt) 
	cap by `panelvar' (`timevar'): egen minzt=min(zt)
	*order zt maxzt minzt,after(`notmiss')

	loc bounds 0
	if `bin'==1 & `norever'==1 {
		*verify the condition 
		cap assert `z'==0 if minzt==`timevar' & `touse'
		* if low-bound value is zero, then test the upper-bound
		if !_rc{
			cap assert `z'==1 if maxzt==`timevar' & `touse'
			if !_rc loc bounds 1
		} 
		
		if `bounds'==0 {
			if "`stag'"=="stag"{
				di "For some units, the first observed value is not zero and the last observed value is not one. Assuming no-staggered adoption."
				loc stag =""
			}	
		}
	}
		
***************** no unobserved change ***************************

	if "`nuchange'"=="nuchange" | "`stag'"=="stag" | "`instag'"=="instag" {
		replace zn2=zminv2 if `timevar'<zmint2
		replace zn2=zmaxv2 if `timevar'>zmaxt2
	}

************** impute inner missing values ***********************
	if `bin'==1 & `norever'==1 & `bounds'==1 & "`instag'"=="instag" {
		
		tempvar zdown zup 
		gen `zdown'=`z'
		gsort `panelvar' `timevar'
		replace `zdown'=`zdown'[_n-1] if missing(`zdown')
		gen `zup'=`z'
		gsort + `panelvar' - `timevar'
		replace `zup'=`zup'[_n-1] if missing(`zup')
		sort `panelvar' `timevar'
		
		replace zn2=`zdown' if `timevar'>=zmint2 & `timevar'<=zmaxt2 & missing(`z') & `zdown'==`zup'
		
	}

****************************** event-time dummies ***********************
	
	qui xtset `panelvar' `timevar', noquery
	
	qui sort `panelvar' `timevar', stable
		
	* Generate event time dummies 
	* First I generate all possible event time dummies to have event time for the trend regressions, then I keep only the ones in the window.
	* While inefficient, this allows me to have event-time outside the window 
	* Fix: This is too inefficient for large datasets. Only generate in window
	* quietly forv klevel=-`tdiff'(1)`tdiff' {
	
	*create z delta
	cap drop zd
	qui gen zd=zn2- L1.zn2
	order zd, after(zn2)
	
	*matrix limits
	tempvar minz maxz minz2 maxz2 
	by `panelvar' (`timevar'): egen `minz'=min(`timevar') if !missing(zn2)
	by `panelvar' (`timevar'): egen `minz2'=min(`minz')
			
	by `panelvar' (`timevar'): egen `maxz'=max(`timevar') if !missing(zn2)
	by `panelvar' (`timevar'): egen `maxz2'=max(`maxz')
	
	*qui forv klevel=`lwindow'(1)`rwindow' {
	forv klevel=`lwindow'(1)`rwindow' {
		loc absk = abs(`klevel')
		
		
		if `klevel'<0 { 
			loc plus = "m"
			* bys `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=`z'[_n+`absk']-`z'[_n+`absk'-1] if `touse'
			*by `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=F`absk'.`z'-F`=`absk'-1'.`z' if `touse'
			by `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=F`absk'.zd if ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse'
			la var _k_eq_`plus'`absk' "Event-time = - `absk'"
			*this to impute zeros in the corner 
			cap drop minp minp2 maxp maxp2 
			by `panelvar' (`timevar'): egen minp=min(`timevar') if !missing(_k_eq_`plus'`absk')
			by `panelvar' (`timevar'): egen minp2=min(minp)
			by `panelvar' (`timevar'): egen maxp=max(`timevar') if !missing(_k_eq_`plus'`absk')
			by `panelvar' (`timevar'): egen maxp2=max(maxp)
			by `panelvar' (`timevar'): replace _k_eq_`plus'`absk'=0 if missing(_k_eq_`plus'`absk') & ((`timevar' < minp2) & (`timevar' >= `minz2')) | ((`timevar' > maxp2) & (`timevar' <= `maxz2')) &  `touse'
		}		
		else {
			loc plus "p" 
			* bys `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=`z'[_n-`absk']-`z'[_n-`absk'-1] if `touse'		 
			*by `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=L`absk'.`z'-L`=`absk'+1'.`z' if `touse'
			by `panelvar' (`timevar'): gen _k_eq_`plus'`absk'=L`absk'.zd if ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse'
			la var _k_eq_`plus'`absk' "Event-time = + `absk'"
			*this to impute zeros in the corner 
			cap drop minp minp2 maxp maxp2 
			by `panelvar' (`timevar'): egen minp=min(`timevar') if !missing(_k_eq_`plus'`absk')
			by `panelvar' (`timevar'): egen minp2=min(minp)
			by `panelvar' (`timevar'): egen maxp=max(`timevar') if !missing(_k_eq_`plus'`absk')
			by `panelvar' (`timevar'): egen maxp2=max(maxp)
			by `panelvar' (`timevar'): replace _k_eq_`plus'`absk'=0 if missing(_k_eq_`plus'`absk') & ((`timevar' < minp2) & (`timevar' >= `minz2')) | ((`timevar' > maxp2) & (`timevar' <= `maxz2')) &  `touse'
		}
		
		
		*This imputates part of the right-upper corner of the matrix (see "missing within"), but it is not correct to make imputations of the corners since we cannot infer something about z outside the data range
		/*
		if "`staggered'"=="" {
			if `klevel'>=0 {	
				* bys `panelvar' (`timevar'): replace _k_eq_`plus'`absk'=`z'[_n-`klevel'] if _k_eq_`plus'`absk'==. & `touse'
				by `panelvar' (`timevar'): replace _k_eq_`plus'`absk'=L`klevel'.`z' if _k_eq_`plus'`absk'==. & `touse'
			}		
		}
		*/
		*This fills the remaining with zeros. Not correct to infer z delta outside the data range as well. All allowed imputations were made when applied no_unobserved_change and they are already considered in z delta
		/*
		qui replace _k_eq_`plus'`absk'=0 if _k_eq_`plus'`absk'==. & `touse'	
		*/
		
	}
	
	* Generate event time
	tempvar __kmax
			gen __k=.
			by `panelvar' (`timevar'): egen p0mink=min(`timevar') if _k_eq_p0 == 1
			by `panelvar' (`timevar'): egen `__kmax'=max(p0mink) 
			replace __k = `timevar' - `__kmax'
	order _k* __k, after(zd)
	
	/*
	* To fix: If multiple events, should generate all.
	qui {
		if "`staggered'"=="" {
			tempvar __kmax
			gen __k=.
			by `panelvar' (`timevar'): egen p0mink=min(`timevar') if _k_eq_p0 == 1
			by `panelvar' (`timevar'): egen `__kmax'=max(p0mink)
			replace __k = `timevar' - `__kmax'
		}
		else if "`staggered'"=="nostaggered" {
			qui gen __k=.
		}
	}
	*/
				
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
	
	/*
	*left
	gen _k_eq_m`=-`lwindow'+1' = (1-f`=-`lwindow''.`zn2') if !missing(f`=-`lwindow''.`zn2') & `touse'
	order _k_eq_m`=-`lwindow'+1', before(_k_eq_m`=-`lwindow'')
	gen _k_eq_p`=`rwindow'+1'= l`=`rwindow'+1'.`zn2' if `touse'			
	order __k, after(_k_eq_p`=`rwindow'+1')
	*/
	
	
	* Absorbing version
	di "stag:`stag'"
	if "`stag'"=="stag" | "`nuchange'"=="nuchange" | "`instag'"=="instag" { 
		qui {
			* Left
			gen _k_eq_m`=-`lwindow'+1' = (1-f`=-`lwindow''.zn2) if ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse' //cc:this guarantees there will be 1's before the 1 corresponding to that _k_eq_m variable. See the excel file
			*find maximum valid time for left endpoint
			cap drop maxl maxl2
			by `panelvar' (`timevar'): egen maxl=max(`timevar') if !missing(_k_eq_m`=-`lwindow'+1')
			by `panelvar' (`timevar'): egen maxl2=max(maxl)
			*replace with zeros
			replace _k_eq_m`=-`lwindow'+1' = 0 if _k_eq_m`=-`lwindow'+1' == . & (`timevar'>maxl2) & (`timevar'<=`maxz2') & `touse'
			by `panelvar' (`timevar'): egen double `mz' = max(zn2) if `touse'
			replace _k_eq_m`=-`lwindow'+1' =0 if `mz'==0 & ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse'
			drop `mz'
			order _k_eq_m`=-`lwindow'+1', before(_k_eq_m`=-`lwindow'')
			
			* Right
			
			*egen double `mz' = rowmax(_k_eq_m`=-`lwindow'+1'-_k_eq_p`=`rwindow'') if `touse'
			*gen _k_eq_p`=`rwindow'+1'= 1-`mz' if `touse'
			gen _k_eq_p`=`rwindow'+1'= l`=`rwindow'+1'.zn2 if ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse'
			*find minimun valid time for right endpoint 
			cap drop minr minr2 
			by `panelvar' (`timevar'): egen minr=min(`timevar') if !missing(_k_eq_p`=`rwindow'+1') & `touse'
			by `panelvar' (`timevar'): egen minr2=min(minr)
			*replace missing values in the upper-right corner
			by `panelvar' (`timevar'): replace _k_eq_p`=`rwindow'+1'=0 if (`timevar'>=`minz2') & (`timevar'<minr2) & `touse'
			by `panelvar' (`timevar'): egen `mz2' = max(zn2) if `touse'		
			replace _k_eq_p`=`rwindow'+1'=0 if `mz2'==0 & ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) &  `touse'
			*drop `mz'
			drop `mz2'	
			order __k, after(_k_eq_p`=`rwindow'+1')			
		}	
	}
	* Not absorbing version
	*else if "`stag'"=="" {
	else {
		qui {
			* Left
			gen _k_eq_m`=-`lwindow'+1' = (1-f`=-`lwindow''.zn2) if ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse'
			order _k_eq_m`=-`lwindow'+1', before(_k_eq_m`=-`lwindow'')
			* Right
			gen _k_eq_p`=`rwindow'+1'= l`=`rwindow'+1'.zn2 if ((`timevar'>=`minz2') & (`timevar'<=`maxz2')) & `touse'			
			order __k, after(_k_eq_p`=`rwindow'+1')
		}
	}
	
	order z zn2 zd _k* __k, after(y)
	
	
	
	la var _k_eq_m`=-`lwindow'+1' "Event time <= - `=-`lwindow'+1'"
	la var _k_eq_p`=`rwindow'+1' "Event time >= + `=`rwindow'+1'"
	
	* Drop units where treatment can not be timed
	
	* If z is binary, check if event-time is missing
	*if `bin' & "`staggered'"=="" {
	if `bin' & ("`stag'"=="stag" | "`instag'"=="instag") {
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






	
	

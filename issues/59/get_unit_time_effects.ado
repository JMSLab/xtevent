* get_unit_time_effects.ado 1.0.0 Sep 14 2022

version 11.2

cap program drop get_unit_time_effects
program define get_unit_time_effects, eclass

	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in] , 

	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */
	[
	name(string) /*name for the effects dataset*/
	NOOutput /* supress output */
	NOCONStant /*omit constant*/
	*
	]
	;
	#d cr
	
	marksample touse
	
	tempvar predicted
	
	if "`nooutput'"!="" loc q quietly
	
	*split varlist
	loc nvars: word count(`varlist')
	tokenize `varlist'
	loc depenvar `1'
	if `nvars'>1 {
		forval k=2(1)`nvars'{
			loc indepvars "`indepvars' ``k''"
		}
	}
	else loc indepvars ""
	
	*get_unit_time_effects
	* firs step of the two-step estimation for repeated cross-sectional datasets 
	* regress dependent variable on controls and unit time effects
		
	`q' reg `depenvar' `indepvars' i.`panelvar'#i.`timevar' [`weight'`exp'] if `touse', `options'
	qui predict `predicted'	
	
	* create list of coefficient values to subtract
	loc tosub "0"
	foreach var in `indepvars'{
		loc tosub "`tosub' + _b[`var']*`var'"
	}
	
	*handle noconstant
	loc constant "0"
	if "`noconstant'"=="" loc constant "_b[_cons]"
	
	*remove prediction from the controls and the constant
	qui replace `predicted' = `predicted' - (`tosub') - `constant'
	
	*create file necessary for step 2
	preserve
	qui gen effects = `predicted'
	qui bysort `panelvar' `timevar': keep if _n==1 //or collapse?
	keep `panelvar' `timevar' effects
	if "`name'"!=""{
		if strmatch("`name'", "*.dta*"){
			save "`name'", replace
		}
		else{
			save "`name'.dta", replace
		}
	}
	else {
		save "unit_time_effects.dta", replace
	}

	*go back to the original dataset 
	restore
	
end
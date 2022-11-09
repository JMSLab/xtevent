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
	replace /*replace unit_time_effects file*/
	load /*load the unit_time_effects file*/
	]
	;
	#d cr
	
	marksample touse
	
	tempvar predicted goup_interact
		
	* Check for a var named effects
	cap unab effvar : effects
	if !_rc {
		di as err _n "You have a variable named {bf:effects}. This name is reserved for the variable that will contain the unit-time effects."
		di as err _n "Please rename this variable before proceeding."
		exit 110
	}
	
	*check if file already exists
	if "`replace'"==""{
		if "`name'"!=""{
			cap confirm file "`name'"
			if !_rc {
				di as err _n "File `name' already exists."
				exit 602
			}
		}
		else{
			cap confirm file "unit_time_effects.dta"
			if !_rc {
				di as err _n "File unit_time_effects.dta already exists."
				exit 602
			}
		}
	}
	
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
	
	egen `goup_interact'=group(`panelvar' `timevar') 
	`q' areg `depenvar' `indepvars', absorb(`goup_interact') `options'
	qui predict `predicted', d	//calculates d_absorbvar, the individual coefficients for the absorbed variable.

	*create file necessary for step 2
	if "`load'"=="" preserve
	qui gen effects = `predicted'
	qui bysort `panelvar' `timevar': keep if _n==1 //or collapse?
	keep `panelvar' `timevar' effects
	if "`name'"!=""{
		if strmatch("`name'", "*.dta*"){
			save "`name'", `replace'
			
		}
		else{
			save "`name'.dta", `replace'
		}
	}
	else {
		save "unit_time_effects.dta", `replace'
	}

	*go back to the original dataset 
	if "`load'"=="" restore
	
end

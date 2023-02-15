* get_unit_time_effects.ado 1.0.0 Nov 14 2022

version 11.2

cap program drop get_unit_time_effects
program define get_unit_time_effects, eclass

	#d;
	syntax varlist(fv ts numeric) [aw fw pw] [if] [in] , 

	Panelvar(varname) /* Panel variable */
	Timevar(varname) /* Time variable */ 
	[
	saving(string) /*specify file name and save the effects dataset*/
	NOOutput /* supress output */
	clear /*replace data in memory with results*/
	*
	]
	;
	#d cr
	
	marksample touse
	
	tempvar predicted
		
	* Check for a variable named _unittimeeffects
	cap unab effvar : _unittimeeffects
	if !_rc {
		di as err _n "You have a variable named {bf:_unittimeeffects}. This name is reserved for the variable that will contain the unit-time effects."
		di as err _n "Please rename or drop this variable before proceeding."
		exit 110
	}
	
	*parse saving
	parsesaving `saving'
	loc filename= r(filename)
	if "`filename'"=="." loc filename ""
	loc replace= r(replace)
	if "`replace'"=="." loc replace ""
	
	*define file name  
	if "`filename'"!=""{
		*check if it contains dta extension
		loc cdta= strmatch("`filename'", "*.dta*")
		if `cdta'==0 loc filename "`filename'.dta"
	}
	else {
		loc filename "unit_time_effects.dta"
	}
	
	*in case replace is not specified, check if file already exists
	if "`replace'"==""{
		cap confirm file "`filename'"
		if !_rc {
			di as err _n "File `filename' already exists."
			exit 602
		}
	}
	
	*split varlist
	unab varlist: `varlist'
	gettoken depenvar indepvars: varlist
	
	*generate unit-time effects
	* first step of the two-step estimation procedure for repeated cross-sectional datasets 
	* regress dependent variable on controls and unit-time effects
	
	*omit regression table
	if "`nooutput'"!="" loc q quietly
	
	cap confirm variable unittimeinteraction
	if !_rc {
		di as err _n "Variable unittimeinteraction already exists. Please delete it or rename it before proceeding"
		exit 110
	}
	
	qui egen unittimeinteraction=group(`panelvar' `timevar') 
	`q' areg `depenvar' `indepvars' [`weight'`exp'] if `touse', absorb(unittimeinteraction) `options'
	qui predict `predicted', d	//calculates d_absorbvar, the individual coefficients for the absorbed variable.

	*create dta file necessary for step 2
	if "`clear'"=="" preserve
	qui gen _unittimeeffects = `predicted'
	qui bysort `panelvar' `timevar': keep if _n==1 //or collapse?: collapse (mean) _unittimeeffects [`weight'`exp'] if `touse', by(`panelvar' `timevar')
	qui keep `panelvar' `timevar' _unittimeeffects
	
	save "`filename'", `replace'
	*go back to the original dataset 
	if "`clear'"=="" restore
	
end

* Program to parse saving
cap program drop parsesaving
program define parsesaving, rclass

	syntax [anything] , [replace]
		
	return local filename "`anything'"
	return local replace "`replace'"
end	

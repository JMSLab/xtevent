
********************* issue 126: wrong exclusion of units ******************

global dir "C:/Users/B18945/Downloads"

cap log close 
log using "$dir/issue126.txt", text replace 

use "$dir\Donaldson2018.dta", clear

** Use Donaldson (2018) data
tsset distid year

***** *** Binned end points= restricted dynamic model (only necessary if all units in the sample change treatments) with xtevent
cap drop aa*
xtevent lnrealincome, policyvar(RAIL) window (9) cluster(distid) savek(aa) //no. obs=5,905
*xteventplot

*mark estimation sample 
cap drop e_sample 
gen e_sample=e(sample)

*dropped units: 
global dropped 61016, 61023, 61101, 61302, 61401, 61402, 61404, 71006, 81003, 81016, 101003, 101006, 101007, 101015, 101016, 101017, 121003, 121017, 121019, 121020, 132003, 132005, 132006, 141001, 141021, 141027, 141028, 141030, 141031, 141037, 141042, 141043, 151030 

*tabulate dropped units 
tab e_sample if inlist(distid, $dropped) //all dropped units were not used in the regression

*list dropped units in the periods close to the supposed treatment time 
list distid year RAIL lnrealincome timeToTreat e_sample if inrange(timeToTreat,-1,1) & inlist(distid,$dropped)
/*the program is not identifying treatment time because the dependent variable has missing values in the treatment time, so the progam exludes those observations and cannot identify the treatment period, despite it is well defined.
Conclusion: `touse' should not be considered when creating the event-time dummies.
*/

log close 
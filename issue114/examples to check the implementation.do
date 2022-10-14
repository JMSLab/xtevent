
***** install the branch version 
*net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/issue114_proxyiv_doesnt_allow_varnames") replace

****** load example dataset
use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
xtset i t

****** default case
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) proxy(zeta) 

***** numlist proxyiv
xtevent y x, panelvar(i) t(t) policyvar(z) window(4) proxy(zeta) proxyiv(1 2 3)

****** Mixed proxyiv
*This proxyiv type used to generate an error.  
xtevent y x, panelvar(i) t(t) policyvar(z) window(4) proxy(zeta) proxyiv(2 eta zeta)

******* varlist proxyiv 
*This proxyiv type used to generate an error. 
*the program will normalize one coefficient per external instrument. It chooses the coefficients closest to zero among the available coefficients
xtevent y x, panelvar(i) t(t) policyvar(z) window(4) proxy(zeta) proxyiv(eta alpha) 

***** number of instruments in proxyiv is greater than the number of available coefficients
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) proxy(zeta) proxyiv(2 eta alpha) 

*****Case when a lead order = normalized coefficient.
* This change was originally done by the program only for the case: lead order = normalized coefficient = -1.
*But in other cases it generated an error.
*the program changes the lead order and shows a warning message.
xtevent y x, panelvar(i) t(t) policyvar(z) window(3) proxy(zeta) proxyiv(2) norm(-2)


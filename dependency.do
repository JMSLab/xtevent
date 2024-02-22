cap ssc install ftools // v2.49.1
cap ssc install reghdfe // v6.12.3
cap ssc install ivreg2 // v4.1.11
* For ivreghdfe, trying to install the github version 
cap net install ivreghdfe, from(https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/)
* if installation failed, install the ssc version 
if _rc cap ssc install ivreghdfe // v1.0.0 
cap ssc install ranktest // v2.0.04
cap ssc install avar // v1.0.07
**********************issue7 plot multiple models: examples to check implementation *****************************

***** install the branch version 
*net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/issue7_plot_several_models_together") replace

****** load example dataset
use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
xtset i t

***************************** one model **************************************
xtevent y x, panelvar(i) timevar(t) policyvar(z) window(5)overidpost(2)
xteventplot

************************ test offset for multiple models **************************************

*model 1
xtevent y, panelvar(i) timevar(t) policyvar(z) window(5)
estimates store model1
*model 2
xtevent y eta, panelvar(i) timevar(t) policyvar(z) window(5) 
estimates store model2
*model 3
xtevent y eta x, panelvar(i) timevar(t) policyvar(z) window(5) nofe
estimates store model3
*plot 3 models
xteventplot model1 model2 model3

*model 4
xtevent y eta x, panelvar(i) timevar(t) policyvar(z) window(5) note
estimates store model4
*model 5
xtevent y eta x, panelvar(i) timevar(t) policyvar(z) window(5) nofe note
estimates store model5
*model 6
xtevent y eta x, panelvar(i) timevar(t) policyvar(z) window(5) reghdfe
estimates store model6
*plot 6 models
xteventplot model1 model2 model3 model4 model5 model6 
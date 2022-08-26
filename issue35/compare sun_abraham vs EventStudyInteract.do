* compare sun_abraham.ado vs EventStudyInteract

*load example dataset
use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
xtset i t

*generate variable of treatment time
gen timet=t if z==1
by i: egen timet2=min(timet)
drop timet
*generate never treated indicator 
cap drop never_treat
gen never_treat=timet2==.

********* estimate using sun_abraham.ado from EventStudy repository
*https://github.com/JMSLab/EventStudy/blob/master/analysis/source/lib/stata/heterogeneous/sun_abraham.ado
*install it mannually in the local computer

sun_abraham y x, individuals(i) time(t) event(timet2) endpoints(-4 5) basecohorts(.) // if there is an error, try it again
*sun_abraham y x, individuals(i) time(t) event(timet2) endpoints(-4 5) basecohorts(.) noshareadjust

*save coefficients and se to plot
matrix C = r(v)
matrix A = r(vse)
matrix sun_abraham = C' \ A'
matrix list C
matrix list A
matrix list sun_abraham
*plot
coefplot matrix(sun_abraham[1]), se(sun_abraham[2])
		
********* estimate equivalent model using eventstudyinteract package 

*generate event-time dummies 
cap drop g_*
xtevent y x, t(t) p(i) policyvar(z) window(-3 4) savek(g,noe)
*estimate with eventstudyinteract package 
eventstudyinteract y g_eq_m4-g_eq_m2 g_eq_p0-g_eq_p5, cohort(timet2) ///
            control_cohort(never_treat) covariates(x)  ///
			absorb(i.i i.t) //vce(cluster i)
			
matrix F = e(b_iw)
mata st_matrix("H",sqrt(diagonal(st_matrix("e(V_iw)"))))
matrix EventStudyInteract = F \ H'
matrix list EventStudyInteract
*plot
coefplot matrix(EventStudyInteract[1]), se(EventStudyInteract[2])


coefplot matrix(sun_abraham[1]), se(sun_abraham[2]) || matrix(EventStudyInteract[1]), se(EventStudyInteract[2])



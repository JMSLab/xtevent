** What happens if cohort is inconsistent with z?

gen fake_cohort = round(20*runiform())
replace fake_cohort = 3 if fake_cohort<3
** Not inconsistent with never_treat
replace fake_cohort = . if never_treat

xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(nuchange) cohort(fake_cohort) control_cohort(never_treat) 

** It's not checking whether cohort is inconsistent or not, running event study with z using cohort vs. control_cohort in each case
** But, we may want NOT to check if we want to use SA for other types of treatment heterogeneity, right?
** Or, we could check by default, and add a "force" option

** Cohort inconsistent with never treat

gen fake_cohort2 = round(20*uniform())
replace fake_cohort = 3 if fake_cohort<3

xtevent y eta , policyvar(z) window(5) vce(cluster i) impute(nuchange) cohort(fake_cohort2) control_cohort(never_treat) 

*! Not checking either
tab fake_cohort2 never_treat
** Original cohort IS consistent
tab time_of_treat never_treat
** Control cohort in SA is never treated or last treated, need to check consistency there

** Write syntax like proxyiv: allow some auto options, but take var as well
** Actually proxiv should take a different syntax, select could clash with a variable name
** Something like proxyiv(select) or proxyiv(fixed var1 var2) or proxyiv(lags 1 2). This way there are no clashes.

**cohort(auto) vs cohort(fixed var1) and cohort(fixed var1, force)
** control_cohort(never_treat) vs control_cohort(fixed var1) vs control_cohort(fixed var1, force)
















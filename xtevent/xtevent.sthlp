
{smcl}
{* *! version 3.1.0 July 7 2024}{...}
{cmd:help xtevent}
{hline}

{title:Title}

{phang}
{bf:xtevent} {hline 2} Panel Event Study Estimation


{marker syntax}{...}
{title:Syntax}

{pstd}

{p 8 17 2}
{cmd:xtevent}
{depvar} [{indepvars}]
{ifin} {weight}
{cmd:,}
{opth pol:icyvar(varname)}
{opth p:anelvar(varname)}
{opth t:imevar(varname)}
[{it:options}]

{synoptset 50 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opth pol:icyvar(varname)}} policy variable{p_end}
{synopt: {opth p:anelvar(varname)}} variable that identifies the panels{p_end}
{synopt: {opth t:imevar(varname)}} variable that identifies the time periods{p_end}
{synopt: {opth w:indow(xtevent##windowspec:windowspec)}} estimation window{p_end}
{synopt: {opth pre(integer)}} # of periods with anticipation effects{p_end}
{synopt: {opth post(integer)}} # of periods with policy effects{p_end}
{synopt: {opth overidpre(integer)}} # of periods to test pre-trends{p_end}
{synopt: {opth overidpost(integer)}} # of periods to test effects leveling off{p_end}
{synopt:{opt st:atic}} estimate static model {p_end}
{synopt: {opth imp:ute(xtevent##imputetype:type [, saveimp])}} impute leads, lags, and missing values of policyvar{p_end}
{synopt:{opth norm(integer)}} event-time coefficient to normalize to 0{p_end}
{synopt:{opt diff:avg}} estimate the difference in averages between the post and pre-periods {p_end}
{synopt:{opt sav:ek(stub [, subopt])}} save time-to-event, event-time, trend, and interaction variables{p_end}
{synopt: {opt kvars(stub)}} use previously generated event-time variables{p_end}
{synopt:{opt reghdfe}} use {help reghdfe} for estimation{p_end}
{synopt:{opth addabsorb(varlist)}} absorb additional variables in {help reghdfe}{p_end}
{synopt:{opt plot}} display plot. See {help xteventplot}{p_end}
{synopt:{opt nofe}} omit panel fixed effects {p_end}
{synopt:{opt note}} omit time fixed effects {p_end}
{synopt:{it: additional_options}} additional options to be passed to the estimation command{p_end}

{syntab:Instrumental variable estimation with proxy variables (Freyaldenhoven et al 2019)}
{synopt:{opth proxy(varname)}} proxy for the confound{p_end}
{synopt:{opth proxyiv:(xtevent##proxyiv_spec:proxyiv_spec)}} instruments for the proxy variable{p_end}

{syntab:Controlling for event-time trends}
{synopt:{opt tr:end(#1 [, subopt])}} extrapolate linear trend from time period #1 before treatment{p_end}

{syntab: Heterogeneous treatment effects (Sun and Abraham 2021)}
{synopt:{opth cohort:(xtevent##cohortspec:cohortspec [, subopt])}} cohorts for Sun and Abraham (2021) estimation{p_end}
{synopt:{opth control_cohort:(xtevent##controlcohortspec:control_cohort_spec [, subopt])}} control cohort for Sun and Abraham (2021) estimation{p_end}
{synopt:{opt sunab:raham}} Sun and Abraham (2021) estimation automatically creating cohort variables{p_end}

{syntab: Estimation with repeated cross sectional data}
{synopt:{opt rep:eatedcs}} indicate that the dataset in memory is repeated cross-sectional{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2} {it: depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2} {it: depvar} and {it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}

{p 4 6 2}* {opth policyvar(varname)} is required. {opth window(integer)} is required unless {opt static}, or {opt pre}, {opt post},
{opt overidpre}, and {opt overidpost} are specified. {opth panelvar(varname)} and {opth timevar(varname)} are required if the data 
have not been {cmd:xtset}, otherwise they are optional. See {help xtset}. {p_end}
{p 4 6 2}
See {help xteventtest} for hypothesis testing after estimation and {help xteventplot} for plotting after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd: xtevent} estimates the effect of a policy variable of interest on a dependent variable using a panel event-study 
design. Additional control variables can be included in {it:varlist}. The command allows for estimation when a pre-trend
 is present using the instrumental variables estimator of Freyaldenhoven et al. (2019). It also allows estimation in 
 settings with heterogeneous effects by cohort using the Interaction Weighted Estimator of Sun and Abraham (2021).{p_end}


{marker options}{...}
{title:Options}
 
{dlgtab:Main}

{phang}
{opth policyvar(varname)} specifies the policy variable of interest. {opt policyvar()} is required.

{phang}
{opth panelvar(varname)} specifies the cross-sectional identifier variable that identifies the panels. {cmd:panelvar()} is required if the data
have not been previously {cmd:xtset}. See {help xtset}.

{phang}
{opth timevar(varname)} specifies the time variable. {cmd:timevar()} is required if the data have not been previously {cmd:xtset}. See
{help xtset}.

{marker windowspec}{...}
{phang}
{opt window(windowspec)} specifies the window around the policy change event to estimate dynamic effects. 

{phang2}
{opt window(k)} with a single positive integer {it:k}>0 uses a symmetric window of {it:k} periods around the event. For example, if {it:k} = 2, there will be five 
coefficients in the window (-2,-1,0,1,2) and two endpoints: -3 and +3. 

{phang2}
{opt window(k1 k2)} with two distinct integers {it:k1}<=0 and {it:k2}>=0 uses an asymmetric window with {it:k1} periods before the event and {it:k2} periods after the event. For example, with {it:k1} = -1 
and {it:k2} = 2, there will be four coefficients in the window (-1,0,1,2) and two endpoints: -2 and +3. 

{phang2}
{cmd: window(max)} uses the largest possible window with the minimum and maximum event times in the estimation sample, accounting for the endpoints.
{cmd: window(max)} is only allowed if the policy follows staggered adoption and requires {cmd: impute(stag)} or {cmd: impute(instag)} to be specified (see below). 

{phang2}
{cmd: window(balanced)} uses the largest possible window with the minimum and maximum event times in the estimation sample for which all cross sectional units have data. 
{cmd: window(balanced)} is only allowed if the policy follows staggered adoption and requires {cmd: impute(stag)} or {cmd: impute(instag)} to be specified (see below). 

{phang}
{opt window()} is required unless {opt static} is specified, or if the estimation window is specified using  options {opt pre()}, {opt post()}, {opt overidpre()}, 
and {opt overidpost()} (See below).

{phang}
{opt pre},
{opt post}, 
{opt overidpre} and 
{opt overidpost} offer an alternative way to specify the estimation window:

{phang2} {opt pre} is the number of pre-event periods where anticipation effects are allowed. With {opt window}, {opt pre} is 0.

{phang2} {opt post} is the number of post-event periods where policy effects are allowed. With {opt window}, {opt post} is the number
of periods after the event (not including the period for the event, e.g. event time = 0), 
except the latest two periods (assigned to {opt overidpost} for the leveling-off test).

{phang2} {opt overidpre} is the number of pre-event periods for an overidentification test of pre-trends. With {opt window}, {opt overidpre}
is the number of periods before the event.

{phang2} {opt overidpost} is the number of post-event periods for an overidentification test of effects leveling off. With {opt window},
{opt overidpost} is 2.

{phang} Only one of {opt window}  or 
{opt pre},
{opt post}, 
{opt overidpre} and 
{opt overidpost} can be declared. 

{phang}
{opt static} estimates a static panel data model and does not generate or plot event-time dummies. {opt static} is not allowed with 
{opt window}, {opt pre}, {opt post}, {opt overidpre}, {opt overidpost}, or {opt diffavg}.

{marker imputetype}{...}
{phang}
{opt impute(type, [ saveimp])} imputes leads, lags, and missing values of {it:policyvar} and uses this new variable as the actual {it:policyvar}. 
{cmd:type} determines the imputation rule. The suboption {cmd:saveimp} adds the new variable to the dataset as 
{it:policyvar_imputed}. The following imputation types are available:

{phang2}
{cmd:impute(nuchange)} imputes missing values in {it:policyvar} according to {it:no unobserved change}: it assumes that 
for each unit: i) in periods before the first observed value, the policy value is the same as the first observed value and;
 ii) in periods after the last observed value, the policy value is the same as the last observed value.

{phang2}
{cmd:impute(stag)} applies {it:no unobserved change} if {it:policyvar} satisfies staggered-adoption assumptions for all units: 
i) {it:policyvar} must be binary, and ii) once {it:policyvar} reaches the adopted-policy state, it never reverts to the 
unadopted-policy state. See Freyaldenhoven et al. (2021) for detailed explanation of the staggered adoption case.

{phang2}
{cmd:impute(instag)} applies {opt impute(stag)} and additionally imputes missing values inside the observed data range: a missing 
value or a group of them will be imputed only if they are both preceded and followed by the unadopted-policy state or by the 
adopted-policy state. 

{phang2}
See {browse "https://rawcdn.githack.com/JMSLab/xtevent/cf16d12f90ddf363df62c397cf0e9dc05bbd9875/impute_option_description.html":this} for a detailed example of the {opt impute} option.

{phang} {opth norm(integer)} specifies the event-time coefficient to be normalized to 0.
The default is to normalize the coefficient on -1.

{phang}
{opt diffavg} calculates the difference in averages between the post-event estimated coefficients and the pre-event estimated 
coefficients. It also calculates its standard error with {help lincom}. {opt diffavg} is not allowed with {opt static}.

{phang}
{opt savek(stub [, subopt])} saves variables for time-to-event, event-time, trend, and interaction variables. Event-time dummies are stored as 
{it: stub}_eq_m# for the dummy variable # periods before the policy change, and {it:stub}_eq_p# for the dummy variable # periods after the 
policy change. The dummy variable for the policy change time is {it:stub}_eq_p0. Event time is stored as {it:stub}_evtime. The trend is stored
 as {it:stub}_trend. For estimation with the Sun and Abrahm (2021) method, such that {opt cohort} and {opt control_cohort} or {opt sunabraham} are active, the
 interaction variables are stored as {it:stub}_m#_c# or {it:stub}_p#_c#, where c# indicates the cohort. The following suboptions can be
 specified:

{phang2}
{opt noe:stimate} saves variables for event-time dummies, event-time, and trends without estimating the model. This option is helpful if the 
users want to customize their regressions and plots.

{phang2}
{opt saveint:eract} saves interaction variables if {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified. {opt noe:stimate} and 
{opt saveint:eract} cannot be specified simultaneously.

{phang2}
{opt replace} replaces variables for time-to-event, event-time, trend, and interaction variables starting with {it:stub}.

{phang}
{opt kvars(stub)} uses previously used event-time dummies saved with prefix {it:stub}. This can be used to speed up estimation.

{phang}
{opt reghdfe} uses {help reghdfe} for estimation, instead of {help areg}, {help ivregress}, and {help xtivreg}. {opt reghdfe} is useful for large 
datasets. By default, it absorbs the panel fixed effects and the time fixed effects. For OLS estimation, the {opt reghdfe}
option requires {help reghdfe} and {help ftools} to be installed. For IV estimation, it also requires {help ivreghdfe} and {help ivreg2}
 to be installed. Note that standard errors may be different and singleton clusters may be dropped using {help reghdfe}.
 See Correia (2016).

{phang}
{opth addabsorb(varlist)} specifies additional fixed effects to be absorbed when using {help reghdfe}. By default, {cmd:xtevent} includes time
 and unit fixed effects. {opt addabsorb} requires {opt reghdfe}.

{phang}
{opt plot} displays a default event-study plot with standard confidence intervals and sup-t confidence bands (Montiel Olea and Plagborg-Møller 2019).
Additional options are available with the postestimation command {help xteventplot}.

{phang}
{opt nofe} excludes panel fixed effects.

{phang}
{opt note} excludes time fixed effects.

{phang}
{it: additional_options}: Additional options to be passed to the estimation command. When {opt proxy} is specified, these options are passed
to {help ivregress}. When {opt reghdfe} is specified, these options are passed to {help reghdfe}. Otherwise, they are passed to {help areg} or
to {help regress} if {opt nofe} is specified. This option is useful for calculating clustered standard errors or changing regression reporting. 

{dlgtab: Instrumental variable estimation with proxy variables (Freyaldenhoven et al 2019)}

{phang}
{opth proxy(varlist)} specifies proxy variables for the confound to be included. {opt proxy} is not allowed with {opt cohort}, 
{opt control_cohort} or {opt sunabraham}.

{marker proxyiv_spec}{...}
{phang}
{opt proxyiv(proxyiv_spec)} specifies instruments for the proxy variable for the policy. {cmd:proxyiv()} admits three syntaxes to use 
either leads of the policy variable or additional variables as instruments. {opt proxy} is not allowed with {opt cohort}, 
{opt control_cohort} or {opt sunabraham}. 

{phang2}
{cmd:proxyiv(select)} selects the lead with the strongest first stage among all possible leads of the 
differenced policy variable to be used as an instrument.
{cmd:proxyiv(select)} is the default for the one proxy, one instrument case, and it is only available in this case. 

{phang2}
{cmd:proxyiv(# ...)} specifies a {it: numlist} with the leads of the differenced policy variable as instruments. For example, 
{cmd:proxyiv(1 2)} specifies that the two first leads of the difference of the policy variable will be used as instruments.

{phang2}
{opth proxyiv(varlist)} specifies a {it:varlist} with the additional variables to be used as instruments.

{dlgtab:Controlling for event-time trends}

{phang}
{opt tr:end(#1 [, subopt])} extrapolates a linear trend using the time periods from period #1 before the policy change to one
period before the policy change, as in Dobkin et al. (2018). For example, {cmd: trend(-3)} uses the coefficients on event-times
-3, -2, and -1 to estimate the trend. The estimated effect of the policy is the deviation from the extrapolated linear trend. 
#1 must be less than -1. {opt trend} is only available when the normalized coefficient is -1 and {opt pre} = 0.
The following can be passed as suboptions:

{phang2}
{opt method(string)} sets the method to estimate the linear trend. It can be Ordinary Least Squares ({opt method(ols)}) or 
Generalized Method of Moments ({opt method(gmm)}). {opt method(ols)} omits the event-time dummies from {opt trend(#1)} to
-1 and adds a linear trend (_ttrend) to the regression. {opt method(gmm)} uses the GMM to compute the trend for the event-time
 dummy coefficients. The default is {opt method(gmm)}.

{phang2}
Note that the coefficients for negative-event time will differ between {opt method(ols)} and {opt method(gmm)}. {opt method(ols)} 
omits the event-time coefficients used to calculate the trend, while {opt method(gmm)} expresses them as differences from the 
estimated linear trend.

{phang2}
{opt saveov:erlay} saves estimations for the overlay plot produced by {opt xteventplot, overlay(trend)}.

 {dlgtab:Heterogeneous treatment effects (Sun and Abraham 2021)}

{marker cohortspec}{...}
{phang}
{opt cohort(cohort_spec)} specifies how to identify the treatment cohorts used for estimation of heterogenous effects by cohort using the
estimator from Sun and Abraham(2021). {opt cohort} requires the  Stata module {cmd:avar}; click {stata ssc install avar :here} to install or 
type "ssc install avar" from inside Stata. {opt cohort} is not allowed with {opt proxy} or {opt proxyiv}.

{phang2}
{cmd:cohort(variable {help varname}},{cmd: [,force])} specifies that the categorical variable {help varname} identifies each treatment cohort.
By default, {cmd:xtevent} checks for consistency of the cohort variable and the policy variable. {bf:force} forces {cmd:xtevent} to 
skip this check. This can be useful when estimating heterogenous treatment effects across groups not defined by treatment cohorts.

{phang2}
{cmd:cohort(create},{cmd: [,save replace]}) asks {cmd:xtevent} to create the categorical treatment cohort variable based on values of the policy variable.
{opt save} adds the new cohort variable to the dataset as {it: policyvar_cohort}. {opt replace} replaces the cohort variable if it already exists. 
The automatic creation of the cohort variable is only available in the staggered adoption case. 
 
{marker controlcohortspec}{...}
{phang}
{opt control_cohort(control_cohort_spec)} specifies how to identify the control cohort used for estimation of heterogenous effects by cohort 
using the estimator from Sun and Abraham(2021). {opt control_cohort} requires {opt cohort} to be specified. {opt control_cohort} is not 
allowed with {opt proxy} or {opt proxyiv}.

{phang2}
{cmd:control_cohort(variable {help varname}},{cmd: [,force])} specifies that the binary variable {help varname} identifies the control cohort.
By default, {cmd:xtevent} checks for consistency of the control cohort variable and the policy variable. {bf:force} forces {cmd:xtevent} to 
skip this check. This can be useful when estimating heterogenous treatment effects across groups not defined by treatment cohorts.

{phang2}
{cmd:control_cohort(create},{cmd: [,save replace]}) asks {cmd:xtevent} to create the binary control cohort variable based on the missing values of 
the cohort variable. {opt save} adds the new control cohort variable to the dataset as {it: policyvar_control_cohort}. {opt replace} replaces
 the control cohort variable if it already exists. {opt control_cohort(create)} is the default if {opt cohort(create)} is specified but {opt control_cohort}
 is not specified.

{phang}
{opt sunab:raham} is a shorthand to specify estimation with heterogenous treatment effects by cohort using the estimator from Sun and Abraham (2021). 
{opt sunabraham} is equivalent to {opt cohort(create)} and {opt control_cohort(create)}.

{dlgtab:Estimation with repeated cross sectional data}

{phang}
{opt repeatedcs} indicates that the dataset in memory is repeated cross-sectional. In this case, {opt panelvar} should indicate the groups 
at which {opt policyvar} changes. For instance, {opt panelvar} could indicate states at which {opt policyvar} changes, while the observations 
in the dataset are individuals in each state. An alternative method to
estimate the event study in a repeated cross-sectional dataset involves using {cmd:get_unit_time_effects} first, and then {cmd:xtevent}. 
See {help get_unit_time_effects}. For fixed-effects estimation, {opt repeatedcs} enables {opt reghdfe}.

{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. {stata webuse nlswork}}{p_end}
{pstd}year variable has many missing observations.{p_end}
{pstd}Create a time variable that ignores these gaps.{p_end}
{phang2}{cmd:. {stata "by idcode (year): gen time=_n"}}{p_end}
{phang2}{cmd:. {stata xtset idcode time}}{p_end}

{pstd}Generate a policy variable that follows staggered adoption.{p_end}
{phang2}{cmd:. {stata "by idcode (time): gen union2 = sum(union)"}}{p_end}
{phang2}{cmd:. {stata replace union2 = 1 if union2 > 1}}{p_end}

{hline}
{pstd}Estimate a basic event study with clustered standard errors.{p_end}
{pstd}Impute the policy variable assuming no unobserved changes{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(3) cluster(idcode) impute(nuchange)}}
{p_end}

{pstd}Omit unit and time fixed effects{p_end}
{pstd}Impute the policy variable verifying staggered adoption{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(3) cluster(idcode) nofe note impute(stag)}}
{p_end}

{pstd}Save event-time dummies without estimating the model{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(3) cluster(idcode) impute(stag) savek(a, noe)}}
{p_end}

{pstd}Change the normalized coefficient and use an asymmetric window{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) cluster(idcode) w(-3 1) norm(-2) impute(stag)}}
{p_end}

{pstd}Estimate using all possible periods before and after the event{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) cluster(idcode) w(max) impute(stag)}}
{p_end}

{pstd}Adjust the pre-trend by estimating a linear trend by GMM {p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(2) cluster(idcode) trend(-2, method(gmm)) impute(stag)}}
{p_end}

{hline}

{pstd}Freyaldenhoven, Hansen and Shapiro (2019) estimator with proxy variables{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(3) vce(cluster idcode) proxy(wks_work) impute(stag)}}
{p_end}

{pstd}Include additional proxy variables, and additional policy variable leads as instruments{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(3) vce(cluster idcode) proxy(wks_work hours) proxyiv(1 2) impute(stag)}}
{p_end}

{pstd}{help reghdfe} and two-way clustering {p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union2) w(3) cluster(idcode year) reghdfe proxy(wks_work) impute(stag)}}
{p_end}

{hline}

{pstd}Interaction Weighted Estimator proposed by Sun and Abraham (2021){p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure, policyvar(union2) window(3) impute(stag) vce(cluster idcode) sunabraham}}
{p_end}

{hline}

{pstd}Interaction Weighted Estimator proposed by Sun and Abraham (2021) with user-created cohort variables{p_end}
{pstd}First, create the control and control cohort variables{p_end}
{pstd}Generate the variable that indicates cohort{p_end}
{phang2}{cmd:. {stata gen timet=year if union2==1}}
{p_end}
{phang2}{cmd:. {stata "by idcode: egen time_of_treat=min(timet)"}}
{p_end}

{pstd}Generate the variable that indicates the control cohort. We use the never-treated units as the control cohort{p_end}
{phang2}{cmd:. {stata gen never_treat=time_of_treat==.}}
{p_end}

{pstd}Estimate{p_end}
{phang2}{cmd:. {stata xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure, policyvar(union2) window(3) impute(stag) vce(cluster idcode) cohort(variable time_of_treat) control_cohort(variable never_treat)}}
{p_end}


{marker saved}{...}
{title:Saved Results}

{pstd}
{cmd:xtevent} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(lwindow)}}left endpoint for estimation window{p_end}
{synopt:{cmd:e(rwindow)}}right endpoint for estimation window{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(names)}}names of the variables for the event-time dummies{p_end}
{synopt:{cmd:e(y1)}}mean of dependent variable at event-time = -1{p_end}
{synopt:{cmd:e(x1)}}mean of proxy variable at event-time = -1, when only one proxy is specified{p_end}
{synopt:{cmd:e(trend)}}"trend" if estimation included extrapolation of a linear trend{p_end}
{synopt:{cmd:e(trendmethod)}}method used to estimate the linear trend: can be "ols" or "gmm"{p_end}
{synopt:{cmd:e(cmd)}}estimation command: can be {help regress}, {help areg}, {help ivregress}, {help xtivreg}, or {help reghdfe}
{p_end}
{synopt:{cmd:e(df)}}degrees of freedom{p_end}
{synopt:{cmd:e(komit)}}list of lags/leads omitted from regression{p_end}
{synopt:{cmd:e(kmiss)}}list of lags/leads to be omitted from plot{p_end}
{synopt:{cmd:e(ambiguous)}}list of cross sectional units omitted because of ambiguous event times{p_end}
{synopt:{cmd:e(method)}}"ols" or "iv"{p_end}
{synopt:{cmd:e(cmd2)}}"xtevent"{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(pre)}}number of periods with anticipation effects{p_end}
{synopt:{cmd:e(post)}}number of periods with policy effects{p_end}
{synopt:{cmd:e(overidpre)}}number of periods to test for pre-trends{p_end}
{synopt:{cmd:e(overidpost)}}number of periods to test for effects leveling off{p_end}
{synopt:{cmd:e(stub)}}prefix for saved event-time dummy variables{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(delta)}}coefficient vector of event-time dummies{p_end}
{synopt:{cmd:e(Vdelta)}}variance-covariance matrix of the event-time dummies coefficients{p_end}
{synopt:{cmd:e(deltax)}} coefficients for proxy event-study to be used in overlay plot{p_end}
{synopt:{cmd:e(deltaxsc)}}scaled coefficients for proxy event-study to be used in overlay plot{p_end}
{synopt:{cmd:e(deltaov)}}coefficients for event-study to be used in overlay plot{p_end}
{synopt:{cmd:e(Vdeltax)}} variance-covariance matrix of proxy-event study coefficients for overlay plot{p_end}
{synopt:{cmd:e(Vdeltaov)}} variance-covariance matrix of event-study coefficients for overlay plot{p_end}
{synopt:{cmd:e(mattrendy)}} matrix with y-axis values of trend for overlay plot, only when {opt trend(#1)} is specified{p_end}
{synopt:{cmd:e(mattrendx)}} matrix with x-axis values of trend for overlay plot, only when {opt trend(#1)} is specified{p_end}
{synopt:{cmd:e(b_ir)}} each column vector contains estimates of each cohort-relative-time interaction and controls included in the interaction regression. The interaction variables are named {it:_interact_m#_c#} or {it:_interact_p#_c#}, where {it:m#} indicates {it:#} periods before the policy change, {it:p#} indicates {it:#} periods after the policy change, and {it:c#} indicates the cohort. Available only when {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified{p_end}
{synopt:{cmd:e(V_ir)}} covariance matrix of the cohort-relative-time interactions and controls included in the interaction regression. The interaction variables are named {it:_interact_m#_c#} or {it:_interact_p#_c#}, where {it:m#} indicates {it:#} periods before the policy change, {it:p#} indicates {it:#} periods after the policy change, and {it:c#} indicates the cohort. Available only when {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified{p_end}
{synopt:{cmd:e(b_interact)}} each column vector contains estimates of cohort-specific effect for the given relative time, only when {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified{p_end}
{synopt:{cmd:e(V_interact)}} each column vector contains variance estimate of the cohort-specific effect estimator for the given relative time, only when {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified{p_end}
{synopt:{cmd:e(ff_w)}} each column vector contains estimates of cohort shares underlying the given relative time, only when {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified{p_end}
{synopt:{cmd:e(Sigma_ff)}} variance estimate of the cohort share estimators, only when {opt cohort} and {opt control_cohort}, or {opt sunabraham} are specified{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:Authors}

{pstd}Simon Freyaldenhoven, Federal Reserve Bank of Philadelphia.{p_end}
       simon.freyaldenhoven@phil.frb.org
{pstd}Christian Hansen, University of Chicago, Booth School of Business.{p_end}
       chansen1@chicagobooth.edu
{pstd}Jorge Pérez Pérez, Banco de México.{p_end}
       jorgepp@banxico.org.mx
{pstd}Jesse Shapiro, Harvard University and NBER.{p_end}
       jesse_shapiro@fas.harvard.edu	   
           
{title:Support}    
           
{pstd}For support and to report bugs please email Jorge Pérez Pérez, Banco de México.{break} 
       jorgepp@banxico.org.mx   

{pstd}{cmd:xtevent} can also be found on {browse "https://github.com/JMSLab/xtevent":GitHub}.
       
{title:References}

{pstd}Correia, S. (2016) . "Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator" Working Paper. {browse "http://scorreia.com/research/hdfe.pdf"} 

{pstd}Dobkin, C., Finkelstein A., Kluender. R., and Notowidigdo, M. J. (2018) "The Economic Consequences of Hospital Admissions."
{it:American Economic Review}, 108 (2): 308-52.

{pstd}Freyaldenhoven, S., Hansen, C. and Shapiro, J. (2019) "Pre-event Trends in the Panel Event-study Design" {it:American Economic Review}, 109 (9):
3307-38.

{pstd}Freyaldenhoven, S., Hansen, C., Pérez Pérez, J. and Shapiro, J. (2021) "Visualization, Identification, 
and Estimation in the Linear Panel Event-study Design". Working paper.

{pstd}Montiel Olea, J.L.  and Plagborg-Møller, M. (2019) "Simultaneous confidence bands: Theory, implementation, and an application to SVARs".
{it:Journal of Applied Econometrics}, 34: 1– 17.

{pstd}Sun, L.  and Abraham, S. (2021) "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects".
{it:Journal of Econometrics}, 225 (2): 175-199.

{title:Acknowledgements}
{pstd}We are grateful to Veli Andirin, Mauricio Cáceres, Richard Calvo, Constantino Carreto, Kathryn Dawson-Townsend, Theresa Doppstadt,
 Ángel Espinoza, Miguel Fajardo-Steinhauser, Samuele Giambra, Santiago Hermo, Ray Huang, Stephen Jenkins, Chandra Kant Dhakal, 
 Daniel Klein, Ryan Kobler, Panagiotis Konstantinou, Per Lidbom, Isabel Z. Martínez, Diego Mayorga, Eric Melse, Stefano Molina,
  Asjad Naqvi, René Nieto, Anna Pasnau, Nathan Schor, Emily Wang, Matthias Weigand, Wenli Xu and an anonymous reviewer for 
  contributions to development and for testing earlier versions of this command.

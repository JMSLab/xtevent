
{smcl}
{* *! version 1.0.0 Sep 13 2022}{...}
{cmd:help get_unit_time_effects}
{hline}

{title:Title}

{phang}
{bf:get_unit_time_effects} {hline 2} Generate Group & Time effects in a Repeated Cross-Sectional Dataset


{marker syntax}{...}
{title:Syntax}

{pstd}

{p 8 17 2}
{cmd:get_unit_time_effects}
{depvar} [{indepvars}]
{ifin}
{cmd:,}
{opth p:anelvar(varname)}
{opth t:imevar(varname)}
[{opt {opt replace}} 
{opt {opt load}}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt: {opth p:anelvar(varname)}} variable that identifies the group at which effects will be computed {p_end}
{synopt: {opth t:imevar(varname)}} variable that identifies the time periods{p_end}
{synopt: {opt name}} name of the unit-time effects file{p_end}
{synopt:{opt noo:utput}} omit regression table{p_end}
{synopt:{opt replace}} replace the unit-time effects file{p_end}
{synopt:{opt load}} replace the dataset in memory with the unit-time effects file{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2} {it: depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2} {it: depvar} and {it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}

{p 4 6 2}* {it:indepvars} should contain covariates that vary at the individual level.

{marker description}{...}
{title:Description}

{pstd}
{cmd: get_unit_time_effects} estimates group-time fixed effects in a repeated cross-sectional dataset. It produces a dta file with the variables, {it:panelvar}, {it:timevar}, and {it:effects}, which contains the group-time effects. 
Hansen (2007) describes a two-step procedure to obtain the coefficient estimates of covariates that vary at the group level within a repeated cross-sectional framework. The two-step procedure can be used to obtain the coefficient estimates of an  
event-study when the data is repeated cross-sectional. {cmd:get_unit_time_effects} implements the first part of the two-step procedure. Then, {cmd: xtevent} can be used for the second part of the procedure and obtain the event-study coefficient 
estimates. See {help xtevent}.{p_end}

{marker options}{...}
{title:Options}
{synoptline}

{phang}
{opth panelvar(varname)} specifies the variable that uniquely identifies the groups at which the policy variable changes.

{phang}
{opth timevar(varname)} specifies the time variable. 

{phang}
{opt name} specifies the name of the unit-time effects file. It can be either only the name, so the output file will be saved in the current directory, or the whole directory/name. If {opt name} is not specified, the file will be saved in the 
current directoy with the name {it: unit_time_effects}.

{phang}
{opt nooutput} omits the regression table. 

{phang}
{opt replace} overwrites the unit-time effects file.

{phang}
{opt load} replaces the dataset in memory with the unit-time effects file. 

{title:Examples}

{hline}
{pstd}Load the small version of the repeated cross-sectional dataset example31{p_end}
{phang2}{cmd:. use "https://github.com/JMSLab/xtevent/blob/main/test/small_repeated_cross_sectional_example31.dta?raw=true", clear}{p_end}
{phang2}{cmd:. {stata xtset, clear}}{p_end}

{pstd}Get unit-time effects and save them as a dta file with the name and directory indicated through the {bf:name} option. Add the {bf:replace} option to overwrite the file.{p_end}
{phang2}{cmd:. get_unit_time_effects y u eta, panelvar(state) timevar(t) name("My_directory\effect_file.dta") replace}
{p_end}

{pstd}Proceed with {bf:xtevent}{p_end}
{phang2}{cmd:. {stata "bysort state t (z): keep if _n==1"}}{p_end}
{phang2}{cmd:. {stata "keep state t z"}}{p_end}

{pstd}Merge with the file that was created with {bf:get_unit_time_effects}{p_end}
{phang2}{cmd:. merge m:1 state t using "My_directory\effect_file.dta"}{p_end}
{phang2}{cmd:. {stata drop _merge}}{p_end}
{pstd}Use {bf:xtevent} to estimate an event-study{p_end}
{phang2}{cmd:. {stata xtevent effects, panelvar(state) t(t) policyvar(z) window(5)}}{p_end}
{phang2}{cmd:. {stata xteventplot}}{p_end}



{title:References}

{pstd}Hansen, C. (2007) . "Generalized Least Squares Inference in Panel and Multilevel Models with Serial Correlation and Fixed Effects" Journal of Econometrics. 


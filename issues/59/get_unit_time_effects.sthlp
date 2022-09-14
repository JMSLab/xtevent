
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
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt: {opth p:anelvar(varname)}} variable that identifies the group at which effects will be computed {p_end}
{synopt: {opth t:imevar(varname)}} variable that identifies the time periods{p_end}
{synopt: {opt name}} name of the output file{p_end}
{synopt:{opt noo:utput}} omit regression output{p_end}
{synopt:{opt nocons:tant}} suppress constant term{p_end}
{synopt:{it: additional_options}} additional options to be passed to {cmd:regress} command{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2} {it: depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2} {it: depvar} and {it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}

{p 4 6 2}* {it:indepvars} should contain covariates that vary at the individual level.

{marker description}{...}
{title:Description}

{pstd}
{cmd: get_unit_time_effects} estimates group-time fixed effects in a repeated cross-sectional dataset. It produces a dta output file with the variables, {it:panelvar}, {it:timevar}, and {it:effects}, which contains the group-time effects. Hansen (2007) describes a two-step procedure to obatain the coefficient estimates of covariates that vary at the group level within a repeated cross-sectional framework. The two-step procedure can be used to obtain the coefficient estimates of an  event-study 
when the data is repeated cross-sectional. {cmd: get_unit_time_effects} implements the first part of the two-step procedure. Then, {cmd: xtevent} can be used for the second part of the procedure and obtain the event-study coefficient estimates. 
See {help xtevent}.{p_end}

{marker options}{...}
{title:Options}
{synoptline}

{phang}
{opth panelvar(varname)} specifies the variable that uniquely identifies the groups at which the policy variable changes.

{phang}
{opth timevar(varname)} specifies the time variable. 

{phang}
{opt name} specifies the name of the output file. It can be either only the name, so the output file will be saved in the current directory, or the whole route/name. If {opt name} is not specified, the ouput file will be saved in the current 
directoy with the name {it: unit_time_effects}.

{phang}
{opt nooutput} omits the regression output. 

{phang}
{opt noconstant} suppresses constant term. 

{phang}
{it: additional_options} additional options to be passed to {cmd:regress} command.

{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. {stata webuse nlswork}}{p_end}


{title:References}

{pstd}Hansen, C. (2007) . "Generalized Least Squares Inference in Panel and Multilevel Models with Serial Correlation and Fixed Effects" Journal of Econometrics. 


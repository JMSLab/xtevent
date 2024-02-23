
{smcl}
{* *! version 3.0.0 Feb 23 2024}{...}
{cmd:help get_unit_time_effects}
{hline}

{title:Title}

{phang}
{bf:get_unit_time_effects} {hline 2} Generate Group and Time Effects in a Repeated Cross-Sectional Dataset

{marker syntax}{...}
{title:Syntax}

{pstd}

{p 8 17 2}
{cmd:get_unit_time_effects}
{depvar} [{indepvars}]
{ifin} {weight}
{cmd:,}
{opth p:anelvar(varname)}
{opth t:imevar(varname)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt: {opth p:anelvar(varname)}} variable that identifies the groups{p_end}
{synopt: {opth t:imevar(varname)}} variable that identifies the time periods{p_end}
{synopt: {opt saving(filename, [replace])}} save results to {it:filename}{p_end}
{synopt:{opt noo:utput}} omit regression table{p_end}
{synopt:{opt clear}} replace data in memory with the unit-time effects file{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2} {it: depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2} {it: depvar} and {it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}

{p 4 6 2}* {it:indepvars} should contain covariates that vary at the individual level.

{marker description}{...}
{title:Description}

{pstd}
{cmd: get_unit_time_effects} estimates group-time fixed effects in a repeated cross-sectional dataset. It produces a Stata data file with the 
variables {it:panelvar}, {it:timevar}, and {it:_unittimeeffects}. The variable {it:_unittimeeffects} contains the group-time effects. Hansen (2007)
 describes a two-step procedure to obtain the coefficient estimates of covariates that vary at the group level within a repeated
 cross-sectional framework. The  two-step procedure can be used to obtain the coefficient estimates of an event-study when the data
 is repeated cross-sectional. {cmd:get_unit_time_effects} implements the first part of the two-step procedure. Then, {cmd: xtevent} can
 be used for the second part of the procedure to obtain the event-study coefficient estimates. See {help xtevent}.{p_end}

{marker options}{...}
{title:Options}
{synoptline}

{phang}
{opth panelvar(varname)} specifies the group variable. The policy variable should vary at this group level.

{phang}
{opth timevar(varname)} specifies the time variable. 

{phang}
{opt saving(filename, [replace])} specifies the name of the Stata data file to store the unit-time effects estimates. If {opt saving} is
 not specified, the file will be saved in the current directory with the name {it: unit_time_effects.dta}. The suboption {it:replace} overwrites
 the unit-time effects file.

{phang}
{opt nooutput} omits the regression table. 

{phang}
{opt clear} replaces the dataset in memory with the unit-time effects file. 

{title:Examples}

{hline}
{pstd}Load example repeated cross-sectional dataset{p_end}
{phang2}{cmd:. use "https://github.com/JMSLab/xtevent/blob/main/test/small_repeated_cross_sectional_example31.dta?raw=true", clear}{p_end}
{phang2}{cmd:. {stata xtset, clear}}{p_end}

{pstd}Get unit-time effects and save them as a dta file with the name and directory indicated through the {bf:saving} option. Add the
 {bf:replace} suboption to overwrite the file.{p_end}
{phang2}{cmd:. {stata get_unit_time_effects y u eta, panelvar(state) timevar(t) saving("effect_file.dta", replace)}}
{p_end}

{pstd}Proceed with {bf:xtevent}{p_end}
{phang2}{cmd:. {stata "bysort state t (z): keep if _n==1"}}{p_end}
{phang2}{cmd:. {stata "keep state t z"}}{p_end}

{pstd}Merge with the file that was created with {bf:get_unit_time_effects}{p_end}
{phang2}{cmd:. {stata "merge m:1 state t using effect_file.dta"}}{p_end}
{phang2}{cmd:. {stata drop _merge}}{p_end}
{pstd}Use {bf:xtevent} to estimate an event-study{p_end}
{phang2}{cmd:. {stata xtevent _unittimeeffects, panelvar(state) t(t) policyvar(z) window(5)}}{p_end}
{phang2}{cmd:. {stata xteventplot}}{p_end}

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

{pstd}Hansen, C. (2007) . "Generalized Least Squares Inference in Panel and Multilevel Models 
with Serial Correlation and Fixed Effects" Journal of Econometrics, 140(2), 670-694.{p_end}

 

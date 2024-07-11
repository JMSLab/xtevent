{smcl}
{* *! version 3.1.0 July 11 2024}{...}
{cmd:help xteventplot}
{hline}

{title:Title}

{phang}
{bf:xteventplot} {hline 2} Plots After Panel Event Study Estimation


{marker syntax}{...}
{title:Syntax}

{pstd}

{p 8 17 2}
{cmd:xteventplot}
{cmd:,}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth suptreps(integer)}} number of repetitions for sup-t confidence bands{p_end}
{synopt:{opt overlay(string)}} generate overlay plots{p_end}
{synopt:{opt y}} generate event study plot for dependent variable in IV setting{p_end}
{synopt:{opt proxy}} generate event study plot for proxy variable in IV setting{p_end}
{synopt:{opt lev:els(numlist)}} customize confidence levels for plot{p_end}
{synopt:{opt sm:path([type, subopt])}} smoothest path through confidence region{p_end}
{synopt:{opt overidpre(integer)}} change pre-event coefficients to be tested{p_end}
{synopt:{opt overidpost(integer)}} change post-event coefficients to be tested{p_end}

{syntab:Appearance}
{synopt: {opt noci}} omit all confidence intervals and bands{p_end}
{synopt:{opt nosupt}} omit sup-t confidence bands{p_end}
{synopt:{opt nozero:line}} omit reference line at 0{p_end}
{synopt:{opt nonorml:abel}} omit label for value of dependent variable at event-time = -1 {p_end}
{synopt:{opt noprepval}} omit p-value for pre-trends test{p_end}
{synopt:{opt nopostpval}} omit p-value for leveling-off test{p_end}
{synopt:{opt scatterplot:opts(string)}} graphics options for coefficient scatter plot{p_end}
{synopt:{opt ciplot:opts(string)}} graphics options for confidence interval plot{p_end}
{synopt:{opt suptciplot:opts(string)}} graphics options for sup-t confidence band plot{p_end}
{synopt:{opt smplot:opts(string)}} graphics options for smoothest path plot{p_end}
{synopt:{opt trendplot:opts(string)}} graphics options for extrapolated trend plot{p_end}
{synopt:{opt staticovplot:opts(string)}} graphics options for the static effect overlay plot {p_end}
{synopt:{opt textboxoption(string)}} textbox options for displaying the p-values of the pre-trend and leveling-off tests{p_end}
{synopt:{opt addplots(string)}} plot to be overlaid on event-study plot{p_end}
{synopt:{it: additional_options}} additional options to be passed to {cmd:twoway}{p_end}

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd: xteventplot} produces event-study plots after {cmd:xtevent}. {p_end}

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth suptreps(integer)} specifies the number of repetitions to calculate Montiel Olea and Plagborg-Møller (2019) sup-t confidence bands for
the dynamic effects. The default is 10000. See {help xtevent}.

{phang}
{opt overlay(string)} creates overlay plots for trend extrapolation, instrumental variables estimation in presence of pre-trends, and constant 
policy effects over time.

{phang2} {bf: overlay(trend)} overlays the event-time coefficients for the trajectory of the dependent variable and the extrapolated linear trend.
{bf: overlay(trend)} is only available after {cmd: xtevent, trend(, saveoverlay)}.

{phang2} {bf: overlay(iv)} overlays the event-time coefficients trajectory of the dependent variable and the proxy variable used to infer the 
trend of the confounder. {bf: overlay(iv)} is only available after {cmd: xtevent, proxy() proxyiv()}.

{phang2} {bf: overlay(static)} overlays the event-time coefficients from the estimated model and the coefficients implied by a constant policy
effect over time. These coefficients are calculated by (i) estimating a model where the policy affects the outcome contemporaneously and 
its effect is constant, (ii) obtaining predicted values of the outcome variable from this constant effects model, and (iii) regressing 
the predicted values on event-time dummy variables.

{phang}
{opt y} creates an event-study plot of the dependent variable in instrumental variables estimation. {opt y} is only available after 
{cmd: xtevent, proxy() proxyiv()}.

{phang}
{opt proxy} creates an event-study plot of the proxy variable in instrumental variables estimation. {opt proxy} is only available after 
{cmd: xtevent, proxy() proxyiv()}.

{phang}
{opt levels(numlist)} customizes the confidence level for the confidence intervals in the event-study plot. By default, xteventplot draws a standard confidence interval and a sup-t confidence band.
{opt levels} allows different confidence levels for standard confidence intervals. For example, {opt levels(90 95)} draws both 90% and 95% level
confidence intervals, along with a sup-t confidence band for Stata's default confidence level.

{phang}
{opt smpath([type , subopt])}} displays the "least wiggly" path through the Wald confidence region of the event-time coefficients.
{opt type} determines the line type, which may be {opt scatter} or {opt line}. {opt smpath} is not allowed with {opt noci}. 

{phang} The following suboptions for {opt smpath} control the optimization process. Because of the nature of the 
optimization problem, optimization error messages 4 and 5 (missing derivatives) or 8 (flat regions) may be
 frequent. Nevertheless, the approximate results from the optimization should be close to the results that would be obtained with convergence of the optimization process. Modifying these optimization suboptions may improve optimization behavior.

{phang2}
{opt postwindow(scalar > 0)} sets the number of post event coefficient estimates to use for calculating the 
smoothest line. The default is to use all the estimates in the post event window.

{phang2}
{opt maxiter(integer)} sets the maximum number of inner iterations for optimization. The default is 100.

{phang2}
{opt maxorder(integer)} sets the maximum order for the polynomial smoothest line. Maxorder must be between 1 and 10. The default is 10.

{phang2} 
{opt technique(string)} sets the optimization technique for the inner iterations of the smoothest-path optimization.
"nr", "bfgs", "dfp", and combinations are allowed. See {help maximize}. The default is "nr 5 bfgs". 

{phang}
{opt overidpre(integer)} changes the coefficients to be tested for the pre-trends overidentification test. 
The default is to test all pre-event coefficients. {opt overidpre(#1)} tests if the coefficients 
for the earliest #1 periods before the event are equal to 0, including the endpoints.  
For example, with a window of 3, {opt overidpre(2)} tests that the coefficients for event-times -4+ 
(the endpoint) and -3 are jointly equal to 0. #1 must be greater than 0.
 See {help xteventtest}.

{phang}
{opt overidpost(integer)} changes the coefficients to be tested for the leveling-off overidentification
 test. The default is to test that the rightmost coefficient and the previous coefficient are
 equal. {opt overidpost(#1)} tests if the coefficients for the latest
 #1 periods after the event  are equal to each other, including the endpoints. For example, with a window of 3, 
 {opt overidpost(3)} tests that the coefficients for event-times 4+ (the endpoint), 3, 
 and 2 are equal to each other. #1 must be greater than 1. See {help xteventtest}.

{dlgtab:Appearance}

{phang}
{opt noci} omits the display and calculation of both Wald and sup-t confidence bands. {opt noci} overrides {opt suptreps} if it is specified.
{opt noci} is not allowed with {opt smpath}.

{phang}
{opt nosupt} omits the display and calculation of sup-t confidence bands. {opt nosupt} overrides {opt suptreps} if it is specified.

{phang}
{opt nozeroline} omits the display of the reference line at 0. Note that reference lines with different styles can be obtained by removing the 
default line with {opt nozeroline} and adding other lines with {opt yline}. See {help added_line_options}. 

{phang}
{opt nonormlabel} suppresses the vertical-axis label for the mean of the dependent variable at 
event-time corresponding to the normalized coefficient.

{phang}
{opt noprepval} omits the display of the p-value for a test for pre-trends. By default, this is a
 Wald test for all the pre-event coefficients being equal to 0, unless {opt overidpre} is specified.

{phang}
{opt nopostpval} omits the display of the p-value for a test for effects leveling off. By default, 
this is a Wald test for the last post-event coefficients being equal, unless {opt overidpost} is specified.

{phang}
{opt scatterplotopts} specifies options to be passed to {cmd:scatter} for the coefficients' plot.

{phang}
{opt ciplotopts} specifies options to be passed to {cmd:rcap} for the confidence interval's 
plot. These options are disabled if {opt noci} is specified.

{phang}
{opt suptciplotopts} specifies options to be passed to {cmd:rcap} for the sup-t confidence
 band's plot. These options are disabled if {opt nosupt} is specified.
 
{phang}
{opt smplotopts} specifies options to be passed to {cmd:line} for the smoothest path through 
the confidence region plot. These options are only active if {opt smpath} is specified.

{phang}
{opt trendplotopts} specifies options to be passed to {cmd:line} for the extrapolated trend
overlay plot. These options are only active if {opt overlay(trend)} is specified.

{phang}
{opt staticovplotopts} specifies options to be passed to {cmd:line} for the static effect overlay
 plot. These options are only active if {opt overlay(static)} is specified.

{phang}
{opt addplots} specifies additional plots to be overlaid to the event-study plot.

{phang}
{opt textboxoption} specifies options to be passed to the textbox of the pre-trend and leveling-off 
tests. These options are disabled if {opt noprepval} and {opt nopostval} are specified. See {help textbox_options}.

{phang}
{it: additional_options}: Additional options to be passed to {cmd:twoway}. See {help twoway}.

{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. {stata webuse nlswork}}{p_end}
{pstd}year variable has many missing observations{p_end}
{pstd}Create a time variable that ignores these gaps{p_end}
{phang2}{cmd:. {stata "by idcode (year): gen time=_n"}}{p_end}
{phang2}{cmd:. {stata xtset idcode time}}{p_end}

{hline}

{pstd}Basic event study with clustered standard errors{p_end}
{pstd}Impute policy variable assuming no unobserved changes{p_end}
{phang2}{cmd:. {stata xtevent ln_wage age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union) w(3) cluster(idcode) impute(nuchange)}}
{p_end}

{pstd}Simple plot{p_end}
{phang2}{cmd:. {stata xteventplot}}{p_end}

{pstd}Supress confidence intervals or sup-t confidence bands{p_end}
{phang2}{cmd:. {stata xteventplot, noci}}{p_end}
{phang2}{cmd:. {stata xteventplot, nosupt}}{p_end}

{pstd}Plot smoothest path in confidence region{p_end}
{phang2}{cmd:. {stata xteventplot, smpath(line)}}{p_end}
{phang2}{cmd:. {stata xteventplot, smpath(line, technique(dfp))}}{p_end}

{pstd}Adjust textbox options for the p-values of the pre-trend and leveling-off tests{p_end}
{phang2}{cmd:. {stata xteventplot, textboxoption(color(blue) size(large))}}{p_end}

{hline}

{pstd}Freyaldenhoven, Hansen and Shapiro (2019) estimator with proxy variables{p_end}
{phang2}{cmd:. {stata xtevent ln_wage age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , pol(union) w(3) vce(cluster idcode) impute(nuchange) proxy(wks_work)}}{p_end}

{pstd}Dependent variable, proxy variable, and overlay plots{p_end}
{phang2}{cmd:. {stata xteventplot, y}}{p_end}
{phang2}{cmd:. {stata xteventplot, proxy}}{p_end}
{phang2}{cmd:. {stata xteventplot, overlay(iv)}}{p_end}
{phang2}{cmd:. {stata xteventplot}}{p_end}

{title:Authors}

{pstd}Simon Freyaldenhoven, Federal Reserve Bank of Philadelphia.{p_end}
       simon.freyaldenhoven@phil.frb.org
{pstd}Christian Hansen, University of Chicago, Booth School of Business.{p_end}
       chansen1@chicagobooth.edu
{pstd}Jorge Pérez Pérez, Banco de México.{p_end}
       jorgepp@banxico.org.mx
{pstd}Jesse Shapiro, Brown University.{p_end}
       jesse_shapiro_1@brown.edu	   
           
{title:Support}    
           
{pstd}For support and to report bugs please email Jorge Pérez Pérez, Banco de México.{break} 
       jorgepp@banxico.org.mx  

{pstd}{cmd:xtevent} can also be found on {browse "https://github.com/JMSLab/xtevent":Github}.
	   

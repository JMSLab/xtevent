# xtevent
![GitHub release (latest by date)](https://img.shields.io/github/v/release/JMSLab/xtevent?label=last%20version)

-----------

### Description
`xtevent` is a Stata package to estimate linear panel event-study models. It includes three commands: `xtevent` for estimation; `xteventplot` to create event-study plots and; `xteventtest` for post-estimation hypotheses testing. 


- Last version: 3.1.0 (07jul2024)
- Current SSC version: 3.1.0 (07jul2024)
-----------

### Updates

* **Version 3.1.0 (07jul2024)**:
    - Options for choosing the largest available estimation window, and the largest available balanced estimation window [#170](https://github.com/JMSLab/xtevent/issues/170) 
    - Simpler syntax for Sun and Abraham (2021) estimation with automatic cohort variables generation [#179](https://github.com/JMSLab/xtevent/issues/179)
    - New default graph style for Stata 18 [#214](https://github.com/JMSLab/xtevent/issues/214)
    - Fixed bugs present in version 3.0.0 [#181](https://github.com/JMSLab/xtevent/issues/181), [#186](https://github.com/JMSLab/xtevent/issues/186), [#188](https://github.com/JMSLab/xtevent/issues/188), [#189](https://github.com/JMSLab/xtevent/issues/189), [#203](https://github.com/JMSLab/xtevent/issues/203), [#204](https://github.com/JMSLab/xtevent/issues/204), [#217](https://github.com/JMSLab/xtevent/issues/217), [#222](https://github.com/JMSLab/xtevent/issues/222)
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v3.1.0) for the complete update list.

* **Version 3.0.0 (23feb2024)**:
    - Increase default replications for sup-t confidence intervals: [#153](https://github.com/JMSLab/xtevent/issues/153)
    - Change the name of the option to omit the label for the value of the dependent variable from `nominus1label` to `nonormlabel`: [#152](https://github.com/JMSLab/xtevent/issues/152)
    - Fixed bugs present in version 2.2.0: [#155](https://github.com/JMSLab/xtevent/issues/155), [#159](https://github.com/JMSLab/xtevent/issues/159), [#166](https://github.com/JMSLab/xtevent/issues/166)
    - Clarifications in the documentation: [#152](https://github.com/JMSLab/xtevent/issues/152), [#161](https://github.com/JMSLab/xtevent/issues/161), [#163](https://github.com/JMSLab/xtevent/issues/163) 
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v3.0.0) for the complete update list.

* **Version 2.2.0 (15mar2023)**:
    - Add `cohort` and `control_cohort` to obtain estimates using [Sun and Abraham's (2021)](https://www.sciencedirect.com/science/article/pii/S030440762030378X) method.
    - Add `repeatedcs`option and `get_unit_time_effects`command to estimate event-studies in repeated cross-section settings.
    - Add `noestimate` option to `savek()` to generate event-time dummies without estimating the regression model.
    - Enable clustered and robust standard errors for IV estimation without `reghdfe`.
    - Fixed bugs present in version 2.1.1.    
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.2.0) for the complete update list.

* **Version 2.1.1 (12aug2022)**:
    - Fixed bugs present in version 2.1.0.
    - Updates in the help files and other documentation.
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.1.1)  for the complete update list.
    
* **Version 2.1.0 (1aug2022)**:
    - Adds `diffavg` option to `xtevent` to obtain the difference between the average post-event and pre-event coefficient estimates. 
    - Adds `textboxoption` option to `xteventplot` to specify characteristics for displaying the p-values of the pre-trend and leveling-off tests.
    - Fixed bugs present in version 2.0.0
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.1.0)  for the complete update list.
    
* **Version 2.0.0 (24jun2022)**:
    - **To produce equivalent results as with xtevent 1.0.0, where the default was to impute the endpoints, the user should use *impute(stag)*.** The **impute** option imputes missing values in the *policyvar* following different rules. For instance, specifying **impute(stag)** indicates the program to check before imputing if the *policyvar* follows staggered adoption. For a detailed explanation of the **impute** option, see this [detailed example](https://rawcdn.githack.com/JMSLab/xtevent/cf16d12f90ddf363df62c397cf0e9dc05bbd9875/impute_option_description.html).
    - The option `nonstaggered` has been depreciated. The default option is now not to impute missing values or endpoints.   You should now choose any of the imputation rules in the `impute` option. To get results using imputation consistent with staggered adoption, as in version 1.0.0 you should use `impute(stag)`.
    - Now the option `trend` allows for trend adjustment by either OLS or GMM.
    - Fixed several bugs present in version 1.0.0.
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.0.0)  for the complete update list.
    
-----------
### Installation

#### To install version 3.1.0 from SSC:
```stata
ssc install xtevent
```

To update from an older version:
```stata
adoupdate xtevent, update
```


#### To install the last version in this repository, use the `github` command:
   First, install the `github` command:
```stata
net install github, from("https://haghish.github.io/github/")
```
   Then execute:
```stata
cap github uninstall xtevent
```
```stata
github install JMSLab/xtevent
```

The `github` command will also install all the necessary dependencies.

If you have an older version and want to update:
```stata
github update xtevent
```

#### To install using `net`:
```stata
cap ado uninstall xtevent
```
```stata
net install xtevent, from("https://raw.githubusercontent.com/JMSLab/xtevent/master")
```
-----------

### To get started
```stata
help xtevent
```

-----------

### Examples

Using xtevent 3.1.0

#### xtevent
```stata
*** setup
webuse nlswork, clear
* year variable has many missing observations
* Create a time variable that ignores the gaps
by idcode (year): gen time=_n
xtset idcode time


*Generate a policy variable that follows staggered adoption
by idcode (time): gen union2=sum(union)
replace union2=1 if union2>1 
order time union union2, after(year)

*** Examples
*Estimate a basic event study with clustered standard errors 
*Impute the policy variable assuming no unobserved changes
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union2) w(3) cluster(idcode) impute(nuchange)
	   
*Omit unit and time fixed effects
*Impute the policy variable verifying staggered adoption
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union2) w(3) cluster(idcode) nofe note impute(stag)

* Bring back unit and time fixed effects
*Adjust for a pre-trend by estimating a linear trend by GMM
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
      pol(union2) w(3) cluster(idcode) trend(-2, method(gmm)) ///
	    impute(stag)
			
*Freyaldenhoven, Hansen and Shapiro (2019) estimator with proxy variables
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
      pol(union2) w(3) vce(cluster idcode) proxy(wks_work) ///
	    impute(stag)
			          
*reghdfe and two-way clustering
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union2) w(3) impute(stag) cluster(idcode year) reghdfe ///
            proxy(wks_work) 
            
*Sun and Abraham (2021) Estimator
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure, ///
            policyvar(union2) window(3) impute(stag) vce(cluster idcode) ///			
            reghdfe sunabraham
```

#### xteventplot
```stata

*** Setup
webuse nlswork, clear
* year variable has many missing observations
* Create a time variable that ignores the gaps
by idcode (year): gen time=_n
xtset idcode time

*** Examples 
*Basic event study with clustered standard errors 
*Impute the policy variable assuming no unobserved changes
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) cluster(idcode) impute(nuchange) 

* Simple plot
xteventplot

*Plot smoothest path in confidence region
xteventplot, smpath(line)

*Freyaldenhoven, Hansen and Shapiro (2019) estimator with proxy variables
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) vce(cluster idcode) impute(nuchange) ///
            proxy(wks_work)

*Dependent variable, proxy variable, and overlay plots
xteventplot, y
xteventplot, proxy
xteventplot, overlay(iv)
xteventplot
```

#### xteventtest
```stata
*** setup
webuse nlswork, clear
xtset idcode year

*** examples 
*Basic event study with clustered standard errors. 
*Impute the policy variable assuming no unobserved changes
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) cluster(idcode) impute(nuchange) 

*Test some coefficients to be equal to 0 jointly
xteventtest, coefs(1 2)

*Test that the sum of all pre-event coefficients is equal to 0
xteventtest, allpre cumul

*Test whether the coefficients before the event follow a linear trend
xteventtest, linpretrend

*Tests that the coefficients for the earliest 2 periods before the event are equal to 0
xteventtest, overidpre(2)
```

-----------

### Video tutorial:

Our YouTube channel, [Linear Panel Event-Study Design](https://www.youtube.com/watch?v=hOIB3PwntYg), contains a video series discussing `xtevent` and the accompanying paper, Visualization, Identification, and Estimation in the Panel Event-Study Design.

-----------

### Citation

Simon Freyaldenhoven, Christian Hansen, Jorge Pérez Pérez, and Jesse M. Shapiro. "Visualization, Identification, and Estimation in the Linear Panel Event-Study Design." [NBER Working Paper No. 29170](https://www.nber.org/papers/w29170),
August 2021; forthcoming in _Advances in Economics and Econometrics: Twelfth World Congress_.

Simon Freyaldenhoven, Christian Hansen, Jorge Pérez Pérez, Jesse M. Shapiro, and Constantino Carreto. "xtevent: Estimation and Visualization in the Linear Panel Event-Study Design." [Article to accompany Stata package](https://jorgeperezperez.com/files/xtevent_merged.pdf), July 2024.


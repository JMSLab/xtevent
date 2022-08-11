# xtevent
![GitHub release (latest by date)](https://img.shields.io/github/v/release/JMSLab/xtevent?label=last%20version)

Stata package `xtevent` estimates linear panel event-study models.

-----------

### Description
`xtevent` is a Stata package to estimate linear panel event-study models. It includes three commands: `xtevent` for estimation; `xteventplot` to create event-study plots and; `xteventtest` for post-estimation hypotheses testing. 


- Last version: 2.1.0 (1aug2022)
- Current SSC version: 2.1.0 (1aug2022)
-----------

### Updates
* **Version 2.1.0 (1aug2022)**:
    - Adds `diffavg` option to `xtevent` to obtain the difference between the average post-event and pre-event coefficient estimates. 
    - Adds `textboxoption` option to `xteventplot` to specify characteristics for displaying the p-values of the pre-trend and leveling-off tests.
    - Fixed bugs present in version 2.0.0
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.1.0)  for the complete update list.
    
* **Version 2.0.0 (24jun2022)**:
    - Adds `impute` option for imputing missing values in the policy variable according to several available rules. See the help file to know more about the available imputation rules. 
    - The option `nonstaggered` has been depreciated. The default option is now not to impute missing values or endpoints.   You should now choose any of the imputation rules in the `impute` option. To get results using imputation consistent with staggered adoption, as in version 1.0.0 you should use `impute(stag)`.
    - Now the option `trend` allows for trend adjustment by either OLS or GMM.
    - Fixed several bugs present in version 1.0.0
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.0.0)  for the complete update list.
-----------

### Installation

#### To install version 2.1.0 from SSC:
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

Using xtevent 2.1.0
#### xtevent
```stata
*setup
webuse nlswork
xtset idcode year

*Estimate a basic event study with clustered standard errors. 
*Besides, impute the policy variable without verifying staggered adoption.
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) cluster(idcode) impute(nuchange)
            
*Omit fixed effects
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) cluster(idcode) impute(nuchange) nofe note

*Adjust by estimating a linear trend with gmm method
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(2) cluster(idcode) impute(nuchange) trend(-2, ///
            method(gmm))
      
*FHS estimator with proxy variables
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) vce(cluster idcode) impute(nuchange) ///
            proxy(wks_work)

*reghdfe and two-way clustering
xtevent ln_w age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) impute(nuchange) cluster(idcode year) reghdfe ///
            proxy(wks_work)


```
#### xteventplot
```
*setup
webuse nlswork
xtset idcode year

*Add an extra effect if union equals 1
gen ln_wage2=ln_wage
replace ln_wage2=ln_wage2+0.5 if union==1

*Basic event study with clustered standard errors. 
*Impute policy variable without verifying staggered adoption.
xtevent ln_wage2 age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) cluster(idcode) impute(nuchange) 

* Plot
xteventplot

*Plot smoothest path in confidence region
xteventplot, smpath(line)

*FHS estimator with proxy variables
xtevent ln_wage age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure , ///
            pol(union) w(3) vce(cluster idcode) impute(nuchange) ///
            proxy(wks_work)

*Dependent variable, proxy variable, and overlay plots
xteventplot, y
xteventplot, proxy
xteventplot, overlay(iv)
```
#### xteventtest
```
*setup
webuse nlswork
xtset idcode year

*Basic event study with clustered standard errors. 
*Impute policy variable without verifying staggered adoption.
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

### Citation

Simon Freyaldenhoven, Christian Hansen, Jorge Pérez Pérez, and Jesse M. Shapiro. "Visualization, Identification, and Estimation in the Panel Event-Study Design." [NBER Working Paper No. 29170](https://www.nber.org/papers/w29170),
August 2021.
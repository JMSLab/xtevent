# xtevent
![GitHub release (latest by date)](https://img.shields.io/github/v/release/JMSLab/xtevent?label=last%20version)

Stata package `xtevent` estimates linear panel event-study models.

-----------

### Description
`xtevent` is a stata package to estimate linear panel event-study models. It includes three commands: `xtevent` for estimation; `xteventplot` for creation of event-study plots and; `xteventtest` for post-estimation hypothesis testing. 


- Last version: 2.0.0 (24jun2022)
- Current SSC version: 2.0.0 (24jun2022)
-----------

### Updates
* **Version 2.0.0 (24jun2022)**:
    - Add `impute` option for imputing missing values in the policy variable according to several available rules. See the help file to know more about the available imputation rules. 
    - The option `nonstaggered` has been depreciated and then in the default estimation there is no imputation of the endpoints. Instead, you can choose any of the imputation rules in the `impute` option.
    - Now the option `trend` allows for trend adjustment by either OLS or GMM.
    - Fixed several bugs present in version 1.0.0
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.0.0)  for the whole list of updates.
-----------

### Installation

#### To install version 2.0.0 from SSC:
```stata
ssc install xtevent
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

`help xtevent`

-----------

### Citation

Simon Freyaldenhoven, Christian Hansen, Jorge Pérez Pérez, and Jesse M. Shapiro. "Visualization, Identification, and Estimation in the Panel Event-Study Design." [NBER Working Paper No. 29170](https://www.nber.org/papers/w29170),
August 2021.
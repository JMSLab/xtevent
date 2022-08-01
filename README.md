# xtevent
![GitHub release (latest by date)](https://img.shields.io/github/v/release/JMSLab/xtevent?label=last%20version)

Stata package `xtevent` estimates linear panel event-study models.

-----------

### Description
`xtevent` is a Stata package to estimate linear panel event-study models. It includes three commands: `xtevent` for estimation; `xteventplot` to create event-study plots and; `xteventtest` for post-estimation hypotheses testing. 


- Last version: 2.1.0 (1aug2022)
- Current SSC version: 2.0.0 (24jun2022)
-----------

### Updates
* **Version 2.1.0 (1aug2022)**:
    - Adds `diffavg` option to `xtevent` to obtain the difference between the average post-event and pre-event coefficient estimates. 
    - Adds `textboxoption` option to `xteventplot` to specify characteristics for displaying the p-values of the pre-trend and leveling-off tests.
    - Fixed bugs present in version 2.0.0
    - See [here](https://github.com/JMSLab/xtevent/releases/tag/v2.1.0)  for the complete update list.
-----------

### Installation

#### To install version 2.0.0 from SSC:
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

### Citation

Simon Freyaldenhoven, Christian Hansen, Jorge Pérez Pérez, and Jesse M. Shapiro. "Visualization, Identification, and Estimation in the Panel Event-Study Design." [NBER Working Paper No. 29170](https://www.nber.org/papers/w29170),
August 2021.
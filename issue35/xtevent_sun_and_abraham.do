*===============================================================================       
* Xtevent issue 35        
* Author: Ray Huang 
* Estimate a basic event study using EventStudyIntereact package and xtevent example
* https://github.com/lsun20/EventStudyInteracts
*===============================================================================

*net install github, from("https://haghish.github.io/github/")
* Dependencies: 
*ssc install avar
*ssc install reghdfe
*ssc install ftools

********************************************************************************
************************************ Load data *********************************
********************************************************************************


clear all
set more off
if "`c(username)'" == "rayhuang" {
	cd "/Users/rayhuang/Documents/JMSLab/xtevent-git/test"
	}
use example31.dta, clear

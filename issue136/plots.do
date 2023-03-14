


cd "C:\ado\personal\xtevent-136-check-smoothest-line-solution\test"

adopath + "C:\ado\personal\xtevent-136-check-smoothest-line-solution\xtevent"

* cap log close

* log using plots.txt, text replace

clear all

frame create results

frame change results

set obs 100

gen y_var = ""

foreach x in post pre order Wcritic Woptim errorcodem errorcodep maxedout {
         gen `x' = .
}

frame create data


frame change data


use "simulation_data_dynamic.dta", clear

loc i=1

foreach var in y_smooth_m y_jump_m {
    forv pre=4(1)4 {
        forv post = 7(1)7 {
                      
                     di _n "*********************************************"
                        di _n "Results for `var', pre = `pre', post = `post'"
                        
                     qui xtevent `var' x_r, pol(z) window(-`pre' `post') 
                        xteventplot, smpath(line, technique(nr 5 bfgs))                 
                        
                     graph export `var'_post`post'_pre`pre'.png, replace

                     frame change results
                        
                     quietly {
                        
                             replace y_var = "`var'" in `i'
                                replace pre = `pre' in `i'
                                replace post = `post' in `i'
                                replace Wcritic = e(Wcrit) in `i'
                                replace Woptim = e(WB) in `i'
                                replace errorcodem = e(errorcodem) in `i'
                                replace errorcodep = e(errorcodep) in `i'
                                replace maxedout = e(maxedout) in `i'
                                replace order = e(orderout) in `i'
                        }
                        
                     
             frame change data
                loc ++i
                }
        }
}

* log close



 
 
********** create the html file

* The markstat package needs some prerequisites. See: https://grodri.github.io/markstat/gettingStarted
*indicate stata Pandoc's directory
whereis pandoc "C:/Program Files/Pandoc/pandoc.exe"
* you need to move to the directory where you saved the stmd file you want markstat to use to create an html file. In this example, the stmd file is named impute_option_description 
*it will create a smcl file and an html file
cd "C:\Users\tino_\Dropbox\PC\Documents\xtevent\issues\120\issue120"
markstat using impute_option_description

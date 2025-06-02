* 1. Collection of Financial Data
clear all
cls
cd "C:\Users\suuser\Desktop\Delistings\Stata"

use "C:\Users\suuser\Desktop\Delistings\Stata\fromexcel.dta", clear  /*This dataset contains confidential data, not reported*/
describe
bro

duplicates list firm variables
duplicates drop firm variables, force
rename variables finvar
reshape long yr, i(dp firm finvar) j(year)
save "C:\Users\suuser\Desktop\Delistings\Stata\finvar.dta", replace

keep if dp=="DEL"
save "C:\Users\suuser\Desktop\Delistings\Stata\finvar_delist.dta", replace
clear



*2. Computing Daily Excess Returns /*This dataset contains confidential data, not reported*/
clear all
cls
set more off

*A. Adjusted returns
use "C:\Users\suuser\Desktop\Delistings\Stata\Adj_ret.dta", clear
describe

gen edate = date(date,"MDY")
format edate %td
drop date
rename edate date

order ticker date

sort ticker date
by ticker: gen return=adj_price[_n]/adj_price[_n-1]-1
drop if missing(return)

save "C:\Users\suuser\Desktop\Delistings\Stata\Adj_ret.dta", replace
drop if ticker=="XU100"
save "C:\Users\suuser\Desktop\Delistings\Stata\delisted_ret.dta", replace
clear

*B. xu100 index returns
use "C:\Users\suuser\Desktop\Delistings\Stata\Adj_ret.dta", clear
keep if ticker=="XU100"
rename return XU100
drop ticker adj_price

save "C:\Users\suuser\Desktop\Delistings\Stata\xu100.dta", replace
clear

*C. Merge & Compute excess returns 
use "C:\Users\suuser\Desktop\Delistings\Stata\delisted_ret.dta", clear
joinby date using "C:\Users\suuser\Desktop\Delistings\Stata\xu100.dta", unmatched(master) _merge(_merge1)

table _merge1
drop _merge1
drop adj_price

gen excess_ret = return - XU100

save "C:\Users\suuser\Desktop\Delistings\Stata\return.dta", replace
clear




*3. Manipulating Delisted Firms Data & Merging with Excess Returns
clear all
cls

*A. Manipulation
use "C:\Users\suuser\Desktop\Delistings\Stata\delisted_raw.dta", clear
describe

gen edate = date(first_trading_date,"DMY")
format edate %td
drop first_trading_date
rename edate first_trading_date

gen edate = date(last_trading_date,"DMY")
format edate %td
drop last_trading_date
rename edate last_trading_date
clear

replace findistress=0 if missing(findistress)
replace ma=0 if missing(ma)
replace voluntary=0 if missing(voluntary)
replace other=0 if missing(other)

order ticker company first_trading_date last_trading_date yearoffoundation neden findistress

save "C:\Users\suuser\Desktop\Delistings\Stata\delisted_raw.dta", replace

*B. Merging
use "C:\Users\suuser\Desktop\Delistings\Stata\delisted_raw.dta", clear
drop if ticker=="ARTI:IS" | ticker=="ASCEL:IS"

sum findistress if findistress==1
sum voluntary if voluntary==1
sum ma if ma==1

joinby ticker using "C:\Users\suuser\Desktop\Delistings\Stata\return.dta", unmatched(master) _merge(_merge1)
tabulate _merge1
drop _merge1
sort ticker date

drop if date > last_trading_date


*Trading day variable: 
sort ticker date
egen id=group(ticker)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==last_trading_date
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

save "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", replace
clear
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
table id if gun_sayisi==.



*4. CARs & Graphs (I use BHARs, not CARs)

*A. Last five years
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

table id if findistress==1 
table id if findistress==0

bysort id (gun_sayisi): gen car=sum(excess_ret) if gun_sayisi > -1251  
gen car_m = car*100

drop if gun_sayisi<-1250

tabstat car_m if gun_sayisi==0 & findistress==1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat car_m if gun_sayisi==0 & findistress!=1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)

ttest car_m==0 if gun_sayisi==0 & findistress==1
ttest car_m==0 if gun_sayisi==0 & findistress!=1


collapse (mean) car_m, by(gun_sayisi findistress)
drop if findistress==0
rename car_m Mali_Sikintidaki_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
bysort id (gun_sayisi): gen car=sum(excess_ret) if gun_sayisi > -1251
gen car_m = car*100
drop if gun_sayisi<-1250

collapse (mean) car_m, by(gun_sayisi findistress)
drop if findistress==1
rename car_m Diger_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress0a.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a.dta", unmatched(both) _merge(_merge1)
drop _merge1 findistress

label variable Mali_Sikintidaki_Sirketler "Mali_Sıkıntıdaki_Şirketler"
label variable Diger_Sirketler "Diger_Şirketler"

line Mali_Sikintidaki_Sirketler Diger_Sirketler gun_sayisi, title("Son Beş Yılın Getirileri") ytitle("Birikmiş Anormal Getiriler, %") xtitle("Gün Sayısı")
clear


*B. Last two years
clear all
cls
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
bysort id (gun_sayisi): gen car=sum(excess_ret) if gun_sayisi > -500  
gen car_m = car*100

drop if gun_sayisi<-500

tabstat car_m if gun_sayisi==0 & findistress==1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat car_m if gun_sayisi==0 & findistress!=1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)

collapse (mean) car_m, by(gun_sayisi findistress)
drop if findistress==0
rename car_m Mali_Sikintidaki_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress1.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
bysort id (gun_sayisi): gen car=sum(excess_ret) if gun_sayisi > -500 
gen car_m = car*100
drop if gun_sayisi<-500

collapse (mean) car_m, by(gun_sayisi findistress)
drop if findistress==1
rename car_m Diger_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress0.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress1.dta", unmatched(both) _merge(_merge1)
drop _merge1 findistress

label variable Mali_Sikintidaki_Sirketler "Mali_Sıkıntıdaki_Şirketler"
label variable Diger_Sirketler "Diger_Şirketler"

line Mali_Sikintidaki_Sirketler Diger_Sirketler gun_sayisi, title("Son İki Yılın Getirileri") ytitle("Birikmiş Anormal Getiriler, %") xtitle("Gün Sayısı")
clear

*C. Last one year
clear all
cls
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
bysort id (gun_sayisi): gen car=sum(excess_ret) if gun_sayisi > -252 
gen car_m = car*100

drop if gun_sayisi<-252

tabstat car_m if gun_sayisi==0 & findistress==1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat car_m if gun_sayisi==0 & findistress!=1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)

collapse (mean) car_m, by(gun_sayisi findistress)
drop if findistress==0
rename car_m Mali_Sikintidaki_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress1.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
bysort id (gun_sayisi): gen car=sum(excess_ret) if gun_sayisi > -252
gen car_m = car*100
drop if gun_sayisi<-252

collapse (mean) car_m, by(gun_sayisi findistress)
drop if findistress==1
rename car_m Diger_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress0.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress1.dta", unmatched(both) _merge(_merge1)
drop _merge1 findistress

label variable Mali_Sikintidaki_Sirketler "Mali_Sıkıntıdaki_Şirketler"
label variable Diger_Sirketler "Diger_Şirketler"

line Mali_Sikintidaki_Sirketler Diger_Sirketler gun_sayisi, title("Son Yılın Getirileri") ytitle("Birikmiş Anormal Getiriler, %") xtitle("Gün Sayısı")
clear




*5. BHARs & Graphs
cls
clear all

*A. Last five years
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

*table ticker if findistress==1
*table ticker if findistress==0

sort id gun_sayisi
xtset id gun_sayisi

drop if gun_sayisi<-1250

gen gret= excess_ret +1 if !missing(excess_ret)
gen gxu100ret= XU100 + 1 if !missing(XU100)

by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = L.product_ret * gret if _n > 1

by id (gun_sayisi), sort: gen product_xu100ret = gxu100ret if _n == 1
by id: replace product_xu100ret = L.product_xu100ret * gxu100ret if _n > 1

gen BHAR1 = product_ret - product_xu100ret
gen BHAR = BHAR1 *100


tabstat BHAR if gun_sayisi==0 & findistress==1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat BHAR if gun_sayisi==0 & findistress!=1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)

ttest BHAR==0 if gun_sayisi==0 & findistress==1
ttest BHAR==0 if gun_sayisi==0 & findistress==0

signrank BHAR=0 if gun_sayisi==0 & findistress==1
signrank BHAR=0 if gun_sayisi==0 & findistress==0

collapse (mean) BHAR, by(gun_sayisi findistress)
drop if findistress==0
rename BHAR Mali_Sikintidaki_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a_BHAR.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
sort id gun_sayisi
xtset id gun_sayisi

drop if gun_sayisi<-1250

gen gret= excess_ret +1 if !missing(excess_ret)
gen gxu100ret= xu100_return + 1 if !missing(xu100_return)

by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = L.product_ret * gret if _n > 1

by id (gun_sayisi), sort: gen product_xu100ret = gxu100ret if _n == 1
by id: replace product_xu100ret = L.product_xu100ret * gxu100ret if _n > 1

gen BHAR1 = product_ret - product_xu100ret
gen BHAR = BHAR1 *100


collapse (mean) BHAR, by(gun_sayisi findistress)
drop if findistress==1
rename BHAR Diger_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress0a_BHAR.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a_BHAR.dta", unmatched(both) _merge(_merge1)
drop _merge1 findistress

label variable Mali_Sikintidaki_Sirketler "Firms with Financial Distress"
label variable Diger_Sirketler "Other Firms"

rename Mali_Sikintidaki_Sirketler Firms_with_Financial_Distress
rename Diger_Sirketler Other_Firms

line Firms_with_Financial_Distress Other_Firms gun_sayisi, ytitle("BHARs, %") xtitle("Number of Days")
clear


*B. Last two years
clear all
cls
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

sort id gun_sayisi
xtset id gun_sayisi

drop if gun_sayisi<-500

gen gret= excess_ret +1 if !missing(excess_ret)
gen gxu100ret= XU100 + 1 if !missing(XU100)

by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = L.product_ret * gret if _n > 1

by id (gun_sayisi), sort: gen product_xu100ret = gxu100ret if _n == 1
by id: replace product_xu100ret = L.product_xu100ret * gxu100ret if _n > 1

gen BHAR1 = product_ret - product_xu100ret
gen BHAR = BHAR1 *100


tabstat BHAR if gun_sayisi==0 & findistress==1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat BHAR if gun_sayisi==0 & findistress!=1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)


collapse (mean) BHAR, by(gun_sayisi findistress)
drop if findistress==0
rename BHAR Mali_Sikintidaki_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a_BHAR.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
sort id gun_sayisi
xtset id gun_sayisi

drop if gun_sayisi<-500

gen gret= excess_ret +1 if !missing(excess_ret)
gen gxu100ret= xu100_return + 1 if !missing(xu100_return)

by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = L.product_ret * gret if _n > 1

by id (gun_sayisi), sort: gen product_xu100ret = gxu100ret if _n == 1
by id: replace product_xu100ret = L.product_xu100ret * gxu100ret if _n > 1

gen BHAR1 = product_ret - product_xu100ret
gen BHAR = BHAR1 *100


collapse (mean) BHAR, by(gun_sayisi findistress)
drop if findistress==1
rename BHAR Diger_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress0a_BHAR.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a_BHAR.dta", unmatched(both) _merge(_merge1)
drop _merge1 findistress

label variable Mali_Sikintidaki_Sirketler "Mali_Sıkıntıdaki_Şirketler"
label variable Diger_Sirketler "Diger_Şirketler"

line Mali_Sikintidaki_Sirketler Diger_Sirketler gun_sayisi, title("Son Iki Yılın Getirileri") ytitle("Satin-Al-ve-Elde-Tut Getirileri, %") xtitle("Gün Sayısı")
clear

*C. Last one year
clear all
cls
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

sort id gun_sayisi
xtset id gun_sayisi

drop if gun_sayisi<-252

gen gret= excess_ret +1 if !missing(excess_ret)
gen gxu100ret= xu100_return + 1 if !missing(xu100_return)

by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = L.product_ret * gret if _n > 1

by id (gun_sayisi), sort: gen product_xu100ret = gxu100ret if _n == 1
by id: replace product_xu100ret = L.product_xu100ret * gxu100ret if _n > 1

gen BHAR1 = product_ret - product_xu100ret
gen BHAR = BHAR1 *100


tabstat BHAR if gun_sayisi==0 & findistress==1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat BHAR if gun_sayisi==0 & findistress!=1, stats(N mean p5 p50 p95 sd sk k min max) columns(stats)

tabstat BHAR if gun_sayisi==0 & findistress==1 & yılönce=="görüş vermekten kaçınma", stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat BHAR if gun_sayisi==0 & findistress==1 & yılönce=="Olumlu", stats(N mean p5 p50 p95 sd sk k min max) columns(stats)
tabstat BHAR if gun_sayisi==0 & findistress==1 & yılönce=="Olumsuz", stats(N mean p5 p50 p95 sd sk k min max) columns(stats)



ttest BHAR==0 if gun_sayisi==0 & findistress==1 & yılönce=="görüş vermekten kaçınma"
ttest BHAR==0 if gun_sayisi==0 & findistress==0

signrank BHAR=0 if gun_sayisi==0 & findistress==1
signrank BHAR=0 if gun_sayisi==0 & findistress==0


collapse (mean) BHAR, by(gun_sayisi findistress)
drop if findistress==0
rename BHAR Mali_Sikintidaki_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a_BHAR.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear
sort id gun_sayisi
xtset id gun_sayisi

drop if gun_sayisi<-252

gen gret= excess_ret +1 if !missing(excess_ret)
gen gxu100ret= xu100_return + 1 if !missing(xu100_return)

by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = L.product_ret * gret if _n > 1

by id (gun_sayisi), sort: gen product_xu100ret = gxu100ret if _n == 1
by id: replace product_xu100ret = L.product_xu100ret * gxu100ret if _n > 1

gen BHAR1 = product_ret - product_xu100ret
gen BHAR = BHAR1 *100


collapse (mean) BHAR, by(gun_sayisi findistress)
drop if findistress==1
rename BHAR Diger_Sirketler
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress0a_BHAR.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress1a_BHAR.dta", unmatched(both) _merge(_merge1)
drop _merge1 findistress

label variable Mali_Sikintidaki_Sirketler "Firms with Financial Distress"
label variable Diger_Sirketler "Other Firms"

rename Mali_Sikintidaki_Sirketler Firms_with_Financial_Distress
rename Diger_Sirketler Other_Firms

line Firms_with_Financial_Distress Other_Firms gun_sayisi, ytitle("BHARs, %") xtitle("Number of Days")
clear


*6. BHARs (Last 2 years)
clear all
cls

* Financial Distress Firms
* 1. Event Study for the Delisting Date 

*Trading day variable: 
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

sort ticker date
egen id=group(ticker)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==last_trading_date
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

drop if (gun_sayisi<-1501 | gun_sayisi>30) & gun_sayisi!=.


*Estimation and event windows
sort id date
by id: gen event_window=1 if gun_sayisi>=-500 & gun_sayisi<=0
egen count_event_obs=count(event_window), by(id)
by id: gen estwindow=1 if gun_sayisi<-501 & gun_sayisi>=-751
egen count_est_obs=count(estwindow), by(id)
replace event_window=0 if event_window==.
replace estwindow=0 if estwindow==.

drop if count_est_obs<50
*keep if findistress==1
drop id
egen id = group(ticker) 
sort id date

* 1.2. Compute ARs for each day in the event and estimation window
gen predicted_return=.

summarize id
forvalues i=1(1)84 {
	l id if id==`i' & gun_sayisi==0
	reg return xu100 if id==`i' & estwindow==1 
	predict p if id==`i'
	replace predicted_return = p if id==`i' & (event_window==1 | estwindow==1)
	drop p
}

* 1.4. Compute BHARs
sort id gun_sayisi
xtset id gun_sayisi

gen gret= return +1 if !missing(return)
gen g_predicted_return=predicted_return +1  if !missing(predicted_return)


by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = (L.product_ret * gret) if _n > 1

by id (gun_sayisi), sort: gen product_gpr = g_predicted_return if _n == 1
by id: replace product_gpr = (L.g_predicted_return * g_predicted_return) if _n > 1

gen BHAR = product_ret - product_gpr 
by id: egen BHAR_M500_P0 = total(BHAR) if event_window==1

save "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1.dta", replace
clear
use"C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1.dta", clear

keep if gun_sayisi==0
duplicates drop id, force

tabstat BHAR_M500_P0, stats(N mean p50 sd min max) columns(stats)

rename yılönce lastopinion
rename var19 penultopinion

tabstat BHAR_M500_P0 if lastopinion=="Olumlu", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="Şartlı görüş", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="Olumsuz", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="görüş vermekten kaçınma", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="-", stats(N mean p50 sd min max) columns(stats)

* Check for t-stats
ttest BHAR_M500_P0 ==0 if lastopinion=="-"
signrank BHAR_M500_P0 =0 if lastopinion=="-"
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1.dta", clear
collapse (mean) BHAR, by(gun_sayisi findistress)
keep if gun_sayisi>-501
rename BHAR Distressed_Firms
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress2a.dta", replace
clear



* Other Firms
* Event Study for the Delisting Date 

*Trading day variable: 
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

sort ticker date
egen id=group(ticker)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==last_trading_date
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

drop if (gun_sayisi<-1501 | gun_sayisi>30) & gun_sayisi!=.


*Estimation and event windows
sort id date
by id: gen event_window=1 if gun_sayisi>=-500 & gun_sayisi<=0
egen count_event_obs=count(event_window), by(id)
by id: gen estwindow=1 if gun_sayisi<-501 & gun_sayisi>=-751
egen count_est_obs=count(estwindow), by(id)
replace event_window=0 if event_window==.
replace estwindow=0 if estwindow==.

drop if count_est_obs<50
keep if findistress==0
drop id
egen id = group(ticker) 
sort id date

* Compute ARs for each day in the event and estimation window
gen predicted_return=.

summarize id
forvalues i=1(1)43{
	l id if id==`i' & gun_sayisi==0
	reg return xu100 if id==`i' & estwindow==1 
	predict p if id==`i'
	replace predicted_return = p if id==`i' & (event_window==1 | estwindow==1)
	drop p
}

* Compute BHARs
sort id gun_sayisi
xtset id gun_sayisi

gen gret= return +1 if !missing(return)
gen g_predicted_return=predicted_return +1  if !missing(predicted_return)


by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = (L.product_ret * gret) if _n > 1

by id (gun_sayisi), sort: gen product_gpr = g_predicted_return if _n == 1
by id: replace product_gpr = (L.g_predicted_return * g_predicted_return) if _n > 1

gen BHAR = product_ret - product_gpr 
by id: egen BHAR_M500_P0 = total(BHAR) if event_window==1

save "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2.dta" , replace

keep if gun_sayisi==0
duplicates drop id, force

tabstat BHAR_M500_P0, stats(N mean p50 sd min max) columns(stats)

* Check for t-stats
ttest BHAR_M500_P0 ==0 
signrank BHAR_M500_P0 =0 
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2.dta", clear
collapse (mean) BHAR, by(gun_sayisi findistress)
keep if gun_sayisi>-501
rename BHAR Other_Firms
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress2b.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress2a.dta", unmatched(both) _merge(_merge1)
table _merge1
drop _merge1 findistress

line Distressed_Firms Other_Firms gun_sayisi, xlabel(-500(100)0) title("Two_Year BHARs") ytitle("BHARs, %") xtitle("Days")  legend(label(1 "Distressed Firms") label(2 "Other Firms"))

graph save "Graph" "C:\Users\suuser\Desktop\Delistings\Stata\BHAR2Y.gph", replace
clear





*7. Regressions
use "C:\Users\suuser\Desktop\Delistings\Stata\finvar_delist.dta", clear 
drop dp

replace finvar="STL" if finvar=="Short-term Liabilities"
replace finvar="MK" if finvar=="Short-term Financial Investment"
replace finvar="PPE" if finvar=="Property, Plant and Equipment (Maddi duran varlıklar)"
replace finvar="MB" if finvar=="Market-toBook Ratio"
replace finvar="NI" if finvar=="Net İncome"
replace finvar="IE" if finvar=="Interest expense"
replace finvar="CAPEX" if finvar=="Capital Expenditures (Sabit sermaye yatırımları)"
replace finvar="OI" if finvar=="Operating income"
replace finvar="RD" if finvar=="R&D Expenses"
replace finvar="TA" if finvar=="Total Assets"
replace finvar="INTA" if finvar=="Intangible Assets"
replace finvar="CAPITAL" if finvar=="Özkaynaklar"
replace finvar="CA" if finvar=="Current Assets"
replace finvar="TAX" if finvar=="Tax Expense"
replace finvar="DIV" if finvar=="Toplam temettü"
replace finvar="EQUITY" if finvar=="Shareholders' Equity"
replace finvar="INV" if finvar=="Inventory"

table finvar

duplicates drop firm year finvar, force
reshape wide yr, i(firm year) j(finvar) string

label variable yrCA "Current Assets"
label variable yrCAPEX "CAPEX"
label variable yrCAPITAL "Paid-in Capital"
label variable yrDIV "Annual Dividends"
label variable yrEBITDA "EBITDA"
label variable yrEQUITY "Shareholders' Equity"
label variable yrIE "Interest Expense"
label variable yrINTA "Intangible Assets"
label variable yrMARCAP "MARCAP"
label variable yrMB "Market-to-Book Ratio"
label variable yrMK "Menkul Kiymetler-Marketable Securities"
label variable yrNI "Net Income"
label variable yrOI "Operating Income"
label variable yrPPE "Plant Property and Equipment"
label variable yrRD "R&D Expenses"
label variable yrSTL "Short-term Liabilities"
label variable yrSales "Net Sales"
label variable yrTA "Total Assets"
label variable yrTAX "Tax Expense"
label variable yrInventory "Inventory stock"




use "C:\Users\suuser\Desktop\Delistings\Stata\BS.dta", clear
gen fortyear=year+1
rename year yeart
rename fortyear year

*1. Firms with financial distress
use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1.dta", clear

joinby ticker year using "C:\Users\suuser\Desktop\Delistings\Stata\BS.dta", unmatched(master) _merge(_merge1)
drop _merge1

joinby ticker using "C:\Users\suuser\Desktop\Delistings\Stata\modifications.dta", unmatched(master) _merge(_merge1)
drop _merge1
replace mod=0 if missing(mod)

gen mcap=ln(marcap)
gen assets=ln(ta)

gen auditnote=0
replace auditnote=1 if yılönce=="Şartlı görüş"
replace auditnote=2 if yılönce=="Olumlu"

keep if gun_sayisi==0
egen id_sector=group(index)

regress auditnote leverage roa tangibility mcap
predict residuals

regress auditnote leverage roa tangibility mcap i.id_sector i.year 
predict res

regress BHAR_M500_P0 auditnote residuals mod
regress BHAR_M500_P0 auditnote res mod

regress BHAR_M500_P0 mod



*6.2. Firms with strategic decisions
use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2.dta", clear

joinby ticker year using "C:\Users\suuser\Desktop\Delistings\Stata\BS.dta", unmatched(master) _merge(_merge1)
drop _merge1

gen mcap=ln(marcap)

gen auditnote=0
replace auditnote=1 if yılönce=="Şartlı görüş"
replace auditnote=2 if yılönce=="Olumlu"

keep if gun_sayisi==0
egen id_sector=group(index)

regress auditnote leverage roa tangibility mcap
predict residuals

regress auditnote leverage roa tangibility mcap i.id_sector i.year 
predict res

regress BHAR_M500_P0 auditnote residuals
regress BHAR_M500_P0 auditnote res





*8. CARs
clear all
cls
set more off

*A. Adjusted returns
use "C:\Users\suuser\Desktop\Delistings\Stata\Adj_ret.dta", clear
describe

gen edate = date(date,"DMY")
format edate %td
drop date
rename edate date

order ticker date

sort ticker date
by ticker: gen return=adj_ret[_n]/adj_ret[_n-1]-1
drop if missing(return)

save "C:\Users\suuser\Desktop\Delistings\Stata\Adj_ret.dta", replace
drop if ticker=="XU100"
save "C:\Users\suuser\Desktop\Delistings\Stata\delisted_ret.dta", replace
clear

*B. xu100 index returns
use "C:\Users\suuser\Desktop\Delistings\Stata\Adj_ret.dta", clear
keep if ticker=="XU100"
rename return xu100
drop ticker
save "C:\Users\suuser\Desktop\Delistings\Stata\xu100.dta", replace
clear

*C. Merge & Compute excess returns 
use "C:\Users\suuser\Desktop\Delistings\Stata\delisted_ret.dta", clear
joinby date using "C:\Users\suuser\Desktop\Delistings\Stata\xu100.dta", unmatched(master) _merge(_merge1)

drop adj_ret _merge1

drop if xu100==.

save "C:\Users\suuser\Desktop\Delistings\Stata\del_ret.dta", replace

*8.1. Manipulating Delisted Firms Data & Merging with Excess Returns
clear all
cls

*A. Manipulation
use "C:\Users\suuser\Desktop\Delistings\Stata\Delisting.dta", clear
sum voluntary if voluntary==1


gen edate = date(first_trading_date,"DMY")
format edate %td
drop first_trading_date
rename edate first_trading_date

gen edate = date(last_trading_date,"DMY")
format edate %td
drop last_trading_date
rename edate last_trading_date

gen edate = date(sonraportarihi,"DMY")
format edate %td
drop sonraportarihi
rename edate sonraportarihi

gen edate = date(ÖncekiRaportarihi,"DMY")
format edate %td
drop ÖncekiRaportarihi
rename edate ÖncekiRaportarihi

gen edate = date(OlumsuzeDönüşRaporTarihi,"DMY")
format edate %td
drop OlumsuzeDönüşRaporTarihi
rename edate OlumsuzeDönüşRaporTarihi



replace findistress=0 if missing(findistress)
replace ma=0 if missing(ma)
replace voluntary=0 if missing(voluntary)
replace other=0 if missing(other)

save "C:\Users\suuser\Desktop\Delistings\Stata\delisted_raw.dta", replace

*B. Merging
use "C:\Users\suuser\Desktop\Delistings\Stata\delisted_raw.dta", clear

*sum findistress if findistress==1
*sum voluntary if voluntary==1
*sum ma if ma==1

joinby ticker using "C:\Users\suuser\Desktop\Delistings\Stata\del_ret.dta", unmatched(master) _merge(_merge1)
tabulate _merge1
drop _merge1
sort ticker date

drop if date > last_trading_date

save "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", replace
clear

*Event Study for Report Decision Changes

*Trading day variable: 
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

drop if missing(OlumsuzeDönüşRaporTarihi)
sort ticker date
egen id=group(ticker)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==OlumsuzeDönüşRaporTarihi
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

drop if (gun_sayisi<-151 | gun_sayisi>30) & gun_sayisi!=.


*Estimation and event windows
sort id date
by id: gen event_window=1 if gun_sayisi>=-10 & gun_sayisi<=10
egen count_event_obs=count(event_window), by(id)
by id: gen estwindow=1 if gun_sayisi<-30 & gun_sayisi>=-151
egen count_est_obs=count(estwindow), by(id)
replace event_window=0 if event_window==.
replace estwindow=0 if estwindow==.

drop if count_est_obs<50
keep if findistress==1
drop id
egen id = group(ticker)
sort id date

* 8.2. Compute ARs for each day in the event and estimation window
gen predicted_return=.

summarize id
forvalues i=1(1)36 {
	l id if id==`i' & gun_sayisi==0
	reg return xu100 if id==`i' & estwindow==1 
	predict p if id==`i'
	replace predicted_return = p if id==`i' & (event_window==1 | estwindow==1)
	drop p
}


* 8.3. Compute CARs
gen AR=ret-predicted_return if estwindow==1 | event_window==1
by id: egen car_M1_P1 = total(AR) if gun_sayisi>=-1 & gun_sayisi<=1
by id: egen car_M0_P1 = total(AR) if gun_sayisi>=0 & gun_sayisi<=1
by id: egen car_M2_P2 = total(AR) if gun_sayisi>=-2 & gun_sayisi<=2
by id: egen car_M5_P5 = total(AR) if gun_sayisi>=-5 & gun_sayisi<=5
by id: egen car_M2_P5 = total(AR) if gun_sayisi>=-2 & gun_sayisi<=5
by id: egen car_M10_P10 = total(AR) if gun_sayisi>=-10 & gun_sayisi<=10
by id: egen car_M2_P10 = total(AR) if gun_sayisi>=-2 & gun_sayisi<=10


* 8.4. Compute standardized abnormal returns(SARs) 
*t-stat calculations: Step 1
by id: egen M=count(estwindow) if estwindow==1 & return!=.

by id: egen Rm_bar_est=mean(xu100) if estwindow==1 

by id: gen abnormal_return_square=AR^2 if estwindow==1
by id: egen sum_u_2=total(abnormal_return_square) if estwindow==1

by id: egen market_rets_m1_p1=total(xu100) if gun_sayisi>=-1 & gun_sayisi<=1
by id: egen market_rets_m0_p1=total(xu100) if gun_sayisi>=0 & gun_sayisi<=1
by id: egen market_rets_m2_p2=total(xu100) if gun_sayisi>=-2 & gun_sayisi<=2
by id: egen market_rets_m5_p5=total(xu100) if gun_sayisi>=-5 & gun_sayisi<=5
by id: egen market_rets_m2_p5=total(xu100) if gun_sayisi>=-2 & gun_sayisi<=5
by id: egen market_rets_m10_p10=total(xu100) if gun_sayisi>=-10 & gun_sayisi<=10
by id: egen market_rets_m2_p10=total(xu100) if gun_sayisi>=-2 & gun_sayisi<=10

by id: egen W_m1_p1=count(event_window) if gun_sayisi>=-1 & gun_sayisi<=1 & return!=.
by id: egen W_m0_p1=count(event_window) if gun_sayisi>=0 & gun_sayisi<=1 & return!=.
by id: egen W_m2_p2=count(event_window) if gun_sayisi>=-2 & gun_sayisi<=2 & return!=.
by id: egen W_m5_p5=count(event_window) if gun_sayisi>=-5 & gun_sayisi<=5 & return!=.
by id: egen W_m2_p5=count(event_window) if gun_sayisi>=-2 & gun_sayisi<=5 & return!=.
by id: egen W_m10_p10=count(event_window) if gun_sayisi>=-10 & gun_sayisi<=10 & return!=.
by id: egen W_m2_p10=count(event_window) if gun_sayisi>=-2 & gun_sayisi<=10 & return!=.

by id: gen market_ret_min_average_sq=(xu100-Rm_bar_est)^2 if estwindow==1
by id: egen denominator=total(market_ret_min_average_sq) if estwindow==1

drop abnormal_return_square market_ret_min_average_sq

*Variable organization:
foreach var of varlist  car_M1_P1-denominator {
by id: egen `var'x=max(`var')
drop `var'
rename `var'x `var'
}

save "C:\Users\suuser\Desktop\Delistings\Stata\data_long_c.dta", replace

keep if gun_sayisi==0
duplicates drop id, force


gen mod=0
replace mod=1 if  year(OlumsuzeDönüşRaporTarihi)> year(ÖncekiRaportarihi) | year(OlumsuzeDönüşRaporTarihi)== year(ÖncekiRaportarihi)

keep ticker mod 

save "C:\Users\suuser\Desktop\Delistings\Stata\modifications.dta", replace


/*
*Winsorization, 1% from both sides:
foreach var of varlist  car_M1_P1-car_M10_P10 {
winsor `var', gen(`var'w) p(0.01)
}
*/

*t-stat calculations: Step 2
*For CAR(-1,+1):
gen numerator=(market_rets_m1_p1 - W_m1_p1 * Rm_bar_est)^2
gen SCAR_m1_p1=(car_M1_P1) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m1_p1 *  (1 + W_m1_p1/M + numerator/denominator))     )
drop numerator W_m1_p1
*For CAR(0,+1):
gen numerator=(market_rets_m0_p1 - W_m0_p1 * Rm_bar_est)^2
gen SCAR_m0_p1=(car_M0_P1) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m0_p1 *  (1 + W_m0_p1/M + numerator/denominator))     )
drop numerator W_m0_p1
*For CAR(-2,+2):
gen numerator=(market_rets_m2_p2 - W_m2_p2 * Rm_bar_est)^2
gen SCAR_m2_p2=(car_M2_P2) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m2_p2 *  (1 + W_m2_p2/M + numerator/denominator))     )
drop numerator W_m2_p2
*For CAR(-5,+5):
gen numerator=(market_rets_m5_p5 - W_m5_p5 * Rm_bar_est)^2
gen SCAR_m5_p5=(car_M5_P5) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m5_p5 *  (1 + W_m5_p5/M + numerator/denominator))     )
drop numerator W_m5_p5
*For CAR(-2,+5):
gen numerator=(market_rets_m2_p5 - W_m2_p5 * Rm_bar_est)^2
gen SCAR_m2_p5=(car_M2_P5) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m2_p5 *  (1 + W_m2_p5/M + numerator/denominator))     )
drop numerator W_m2_p5
*For CAR(-10,+10):
gen numerator=(market_rets_m10_p10 - W_m10_p10 * Rm_bar_est)^2
gen SCAR_m10_p10=(car_M10_P10) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m10_p10 *  (1 + W_m10_p10/M + numerator/denominator))     )
drop numerator W_m10_p10
*For CAR(-2,+10):
gen numerator=(market_rets_m2_p10 - W_m2_p10 * Rm_bar_est)^2
gen SCAR_m2_p10=(car_M2_P10) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m2_p10 *  (1 + W_m2_p10/M + numerator/denominator))     )
drop numerator W_m2_p10

save "C:\Users\suuser\Desktop\Delistings\Stata\data_short_c.dta", replace
clear

use "C:\Users\Burcu Avci\Desktop\Step3-EventStudy\data_short_c.dta", clear
tabstat car_M1_P1-car_M2_P10, stats(N mean p50 min max) columns(stats)

*t-tests for CARs 
foreach var of varlist SCAR_m1_p1- SCAR_m2_p10 {
di "`var'"
quietly summarize `var' 
scalar count_`var'=r(N)
scalar sqrt_count_`var'=sqrt(r(N))
scalar sd_`var'=r(sd)
scalar sum_`var'=r(sum)
scalar Z_`var'=sum_`var' / (sqrt_count_`var' * sd_`var')
di Z_`var'
}

* Check for t-stats
ttest car_M1_P1 ==0 
ttest car_M0_P1 ==0 
ttest car_M2_P2 ==0 
ttest car_M5_P5 ==0 
ttest car_M2_P5 ==0 
ttest car_M10_P10 ==0 
ttest car_M2_P10 ==0 


* Regressions
regress car_M1_P1 mod 
regress car_M2_P2 mod 
regress car_M5_P5 mod 
regress car_M10_P10 mod 



*7. Peer Firms
*7.1. Computing Daily Excess Returns of Peer Companies
clear all
cls
set more off

*Trading day variable: 
use "C:\Users\suuser\Desktop\Delistings\Stata\merged_peer.dta", clear

drop if missing(ÖncekiRaportarihi)
sort peer date
egen id=group(peer)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==last_trading_date
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

drop if (gun_sayisi<-1501 | gun_sayisi>30) & gun_sayisi!=.


*Estimation and event windows
sort id date
by id: gen event_window=1 if gun_sayisi>=-500 & gun_sayisi<=0
egen count_event_obs=count(event_window), by(id)
by id: gen estwindow=1 if gun_sayisi<-501 & gun_sayisi>=-751
egen count_est_obs=count(estwindow), by(id)
replace event_window=0 if event_window==.
replace estwindow=0 if estwindow==.

drop if count_est_obs<50
keep if findistress==1
drop id
egen id = group(ticker) 
sort id date

* Compute ARs for each day in the event and estimation window
gen predicted_return=.

summarize id
forvalues i=1(1)33 {
	l id if id==`i' & gun_sayisi==0
	reg peer_return xu100 if id==`i' & estwindow==1 
	predict p if id==`i'
	replace predicted_return = p if id==`i' & (event_window==1 | estwindow==1)
	drop p
}

* 1.4. Compute BHARs
sort id gun_sayisi
xtset id gun_sayisi

gen gret= peer_return +1 if !missing(peer_return)
gen g_predicted_return=predicted_return +1  if !missing(predicted_return)


by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = (L.product_ret * gret) if _n > 1

by id (gun_sayisi), sort: gen product_gpr = g_predicted_return if _n == 1
by id: replace product_gpr = (L.g_predicted_return * g_predicted_return) if _n > 1

gen BHAR = product_ret - product_gpr 
by id: egen BHAR_M500_P0 = total(BHAR) if event_window==1

save "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1_peer.dta", replace
clear
use"C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1_peer.dta", clear

keep if gun_sayisi==0
duplicates drop id, force

tabstat BHAR_M500_P0 , stats(N mean p50 sd min max) columns(stats)

rename yılönce lastopinion
rename var19 penultopinion

tabstat BHAR_M500_P0 if lastopinion=="Olumlu", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="Şartlı görüş", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="Olumsuz", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="görüş vermekten kaçınma", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="-", stats(N mean p50 sd min max) columns(stats)

* Check for t-stats
ttest BHAR_M500_P0 ==0 
signrank BHAR_M500_P0 =0

ttest BHAR_M500_P0 ==0 if lastopinion=="-"
signrank BHAR_M500_P0 =0 if lastopinion=="-"
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1_peer.dta", clear
collapse (mean) BHAR, by(gun_sayisi findistress)
keep if gun_sayisi>-501
rename BHAR Distressed_Firms
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress2a_peer.dta", replace
clear


* Other Firms
* Event Study for the Delisting Date 
clear all 
cls
*Trading day variable: 
use "C:\Users\suuser\Desktop\Delistings\Stata\merged_peer.dta", clear

drop if missing(ÖncekiRaportarihi)
sort peer date
egen id=group(peer)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==last_trading_date
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

drop if (gun_sayisi<-1501 | gun_sayisi>30) & gun_sayisi!=.


*Estimation and event windows
sort id date
by id: gen event_window=1 if gun_sayisi>=-500 & gun_sayisi<=0
egen count_event_obs=count(event_window), by(id)
by id: gen estwindow=1 if gun_sayisi<-501 & gun_sayisi>=-751
egen count_est_obs=count(estwindow), by(id)
replace event_window=0 if event_window==.
replace estwindow=0 if estwindow==.

drop if count_est_obs<50
keep if findistress==0
drop id
egen id = group(ticker) 
sort id date


* Compute ARs for each day in the event and estimation window
gen predicted_return=.

summarize id
forvalues i=1(1)41 {
	l id if id==`i' & gun_sayisi==0
	reg peer_return xu100 if id==`i' & estwindow==1 
	predict p if id==`i'
	replace predicted_return = p if id==`i' & (event_window==1 | estwindow==1)
	drop p
}

* Compute BHARs
sort id gun_sayisi
xtset id gun_sayisi

gen gret= peer_return +1 if !missing(peer_return)
gen g_predicted_return=predicted_return +1  if !missing(predicted_return)


by id (gun_sayisi), sort: gen product_ret = gret if _n == 1
by id: replace product_ret = (L.product_ret * gret) if _n > 1

by id (gun_sayisi), sort: gen product_gpr = g_predicted_return if _n == 1
by id: replace product_gpr = (L.g_predicted_return * g_predicted_return) if _n > 1

gen BHAR = product_ret - product_gpr 
by id: egen BHAR_M500_P0 = total(BHAR) if event_window==1

save "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2_peer.dta", replace
clear
use"C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2_peer.dta", clear

keep if gun_sayisi==0
duplicates drop id, force

tabstat BHAR_M500_P0 , stats(N mean p50 sd min max) columns(stats)

rename yılönce lastopinion
rename var19 penultopinion

tabstat BHAR_M500_P0 if lastopinion=="Olumlu", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="Şartlı görüş", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="Olumsuz", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="görüş vermekten kaçınma", stats(N mean p50 sd min max) columns(stats)
tabstat BHAR_M500_P0 if lastopinion=="-", stats(N mean p50 sd min max) columns(stats)

* Check for t-stats
ttest BHAR_M500_P0 ==0 if lastopinion=="-"
signrank BHAR_M500_P0 =0 if lastopinion=="-"

ttest BHAR_M500_P0 ==0
signrank BHAR_M500_P0 =0 
clear

* AR Graphs
use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2_peer.dta", clear
collapse (mean) BHAR, by(gun_sayisi findistress)
keep if gun_sayisi>-501
rename BHAR Other_Firms
save "C:\Users\suuser\Desktop\Delistings\Stata\findistress2b_peer.dta", replace

joinby gun_sayisi using "C:\Users\suuser\Desktop\Delistings\Stata\findistress2a_peer.dta", unmatched(both) _merge(_merge1)
table _merge1
drop _merge1 findistress

line Distressed_Firms Other_Firms gun_sayisi, xlabel(-500(100)0) title("Two_Year BHARs") ytitle("BHARs, %") xtitle("Days")  legend(label(1 "Distressed Firms") label(2 "Other Firms"))

graph save "Graph" "C:\Users\suuser\Desktop\Delistings\Stata\BHAR2Y_peer.gph", replace
clear


* Regressions
*1. Firms with financial distress
use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_1_peer.dta", clear

joinby ticker year using "C:\Users\suuser\Desktop\Delistings\Stata\BS.dta", unmatched(master) _merge(_merge1)
drop _merge1

gen mcap=ln(marcap)

gen auditnote=0
replace auditnote=1 if yılönce=="Şartlı görüş"
replace auditnote=2 if yılönce=="Olumlu"

keep if gun_sayisi==0
egen id_sector=group(index)

regress auditnote leverage roa tangibility mcap
predict residuals

regress auditnote leverage roa tangibility mcap i.id_sector i.year 
predict res

regress BHAR_M500_P0 auditnote residuals
regress BHAR_M500_P0 auditnote res


*7.2. Firms with strategic decisions
use "C:\Users\suuser\Desktop\Delistings\Stata\data_long2_2_peer.dta", clear

joinby ticker year using "C:\Users\suuser\Desktop\Delistings\Stata\BS.dta", unmatched(master) _merge(_merge1)
drop _merge1

gen auditnote=0
replace auditnote=1 if yılönce=="Şartlı görüş"
replace auditnote=2 if yılönce=="Olumlu"

keep if gun_sayisi==0
regress BHAR_M500_P0 auditnote leverage roa tangibility marcap






* 8. Event Study for the Last Audit Report Date
clear all
cls

*Trading day variable: 
use "C:\Users\suuser\Desktop\Delistings\Stata\merged.dta", clear

drop if missing(sonraportarihi)
sort ticker date
egen id=group(ticker)

sort id date
by id: gen datenum=_n
by id: gen target=datenum if date==sonraportarihi
egen td=min(target), by(id)
drop target
gen gun_sayisi=datenum-td
drop datenum td 

drop if (gun_sayisi<-151 | gun_sayisi>30) & gun_sayisi!=.

*Estimation and event windows
sort id date
by id: gen event_window=1 if gun_sayisi>=-10 & gun_sayisi<=10
egen count_event_obs=count(event_window), by(id)
by id: gen estwindow=1 if gun_sayisi<-30 & gun_sayisi>=-151
egen count_est_obs=count(estwindow), by(id)
replace event_window=0 if event_window==.
replace estwindow=0 if estwindow==.

drop if count_est_obs<50
keep if findistress==1
drop id
egen id = group(ticker)
sort id date

* Compute ARs for each day in the event and estimation window
gen predicted_return=.

summarize id
forvalues i=1(1)36 {
	l id if id==`i' & gun_sayisi==0
	reg return xu100 if id==`i' & estwindow==1 
	predict p if id==`i'
	replace predicted_return = p if id==`i' & (event_window==1 | estwindow==1)
	drop p
}


* Compute CARs
gen AR=ret-predicted_return if estwindow==1 | event_window==1
by id: egen car_M1_P1 = total(AR) if gun_sayisi>=-1 & gun_sayisi<=1
by id: egen car_M0_P1 = total(AR) if gun_sayisi>=0 & gun_sayisi<=1
by id: egen car_M2_P2 = total(AR) if gun_sayisi>=-2 & gun_sayisi<=2
by id: egen car_M5_P5 = total(AR) if gun_sayisi>=-5 & gun_sayisi<=5
by id: egen car_M2_P5 = total(AR) if gun_sayisi>=-2 & gun_sayisi<=5
by id: egen car_M10_P10 = total(AR) if gun_sayisi>=-10 & gun_sayisi<=10
by id: egen car_M2_P10 = total(AR) if gun_sayisi>=-2 & gun_sayisi<=10


* Compute standardized abnormal returns(SARs) 
*t-stat calculations: Step 1
by id: egen M=count(estwindow) if estwindow==1 & return!=.

by id: egen Rm_bar_est=mean(xu100) if estwindow==1 

by id: gen abnormal_return_square=AR^2 if estwindow==1
by id: egen sum_u_2=total(abnormal_return_square) if estwindow==1

by id: egen market_rets_m1_p1=total(xu100) if gun_sayisi>=-1 & gun_sayisi<=1
by id: egen market_rets_m0_p1=total(xu100) if gun_sayisi>=0 & gun_sayisi<=1
by id: egen market_rets_m2_p2=total(xu100) if gun_sayisi>=-2 & gun_sayisi<=2
by id: egen market_rets_m5_p5=total(xu100) if gun_sayisi>=-5 & gun_sayisi<=5
by id: egen market_rets_m2_p5=total(xu100) if gun_sayisi>=-2 & gun_sayisi<=5
by id: egen market_rets_m10_p10=total(xu100) if gun_sayisi>=-10 & gun_sayisi<=10
by id: egen market_rets_m2_p10=total(xu100) if gun_sayisi>=-2 & gun_sayisi<=10

by id: egen W_m1_p1=count(event_window) if gun_sayisi>=-1 & gun_sayisi<=1 & return!=.
by id: egen W_m0_p1=count(event_window) if gun_sayisi>=0 & gun_sayisi<=1 & return!=.
by id: egen W_m2_p2=count(event_window) if gun_sayisi>=-2 & gun_sayisi<=2 & return!=.
by id: egen W_m5_p5=count(event_window) if gun_sayisi>=-5 & gun_sayisi<=5 & return!=.
by id: egen W_m2_p5=count(event_window) if gun_sayisi>=-2 & gun_sayisi<=5 & return!=.
by id: egen W_m10_p10=count(event_window) if gun_sayisi>=-10 & gun_sayisi<=10 & return!=.
by id: egen W_m2_p10=count(event_window) if gun_sayisi>=-2 & gun_sayisi<=10 & return!=.

by id: gen market_ret_min_average_sq=(xu100-Rm_bar_est)^2 if estwindow==1
by id: egen denominator=total(market_ret_min_average_sq) if estwindow==1

drop abnormal_return_square market_ret_min_average_sq

*Variable organization:
foreach var of varlist  car_M1_P1-denominator {
by id: egen `var'x=max(`var')
drop `var'
rename `var'x `var'
}

save "C:\Users\suuser\Desktop\Delistings\Stata\data_long_l2.dta", replace

keep if gun_sayisi==0
duplicates drop id, force

/*
*Winsorization, 1% from both sides:
foreach var of varlist  car_M1_P1-car_M10_P10 {
winsor `var', gen(`var'w) p(0.01)
}
*/

*t-stat calculations: Step 2
*For CAR(-1,+1):
gen numerator=(market_rets_m1_p1 - W_m1_p1 * Rm_bar_est)^2
gen SCAR_m1_p1=(car_M1_P1) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m1_p1 *  (1 + W_m1_p1/M + numerator/denominator))     )
drop numerator W_m1_p1
*For CAR(0,+1):
gen numerator=(market_rets_m0_p1 - W_m0_p1 * Rm_bar_est)^2
gen SCAR_m0_p1=(car_M0_P1) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m0_p1 *  (1 + W_m0_p1/M + numerator/denominator))     )
drop numerator W_m0_p1
*For CAR(-2,+2):
gen numerator=(market_rets_m2_p2 - W_m2_p2 * Rm_bar_est)^2
gen SCAR_m2_p2=(car_M2_P2) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m2_p2 *  (1 + W_m2_p2/M + numerator/denominator))     )
drop numerator W_m2_p2
*For CAR(-5,+5):
gen numerator=(market_rets_m5_p5 - W_m5_p5 * Rm_bar_est)^2
gen SCAR_m5_p5=(car_M5_P5) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m5_p5 *  (1 + W_m5_p5/M + numerator/denominator))     )
drop numerator W_m5_p5
*For CAR(-2,+5):
gen numerator=(market_rets_m2_p5 - W_m2_p5 * Rm_bar_est)^2
gen SCAR_m2_p5=(car_M2_P5) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m2_p5 *  (1 + W_m2_p5/M + numerator/denominator))     )
drop numerator W_m2_p5
*For CAR(-10,+10):
gen numerator=(market_rets_m10_p10 - W_m10_p10 * Rm_bar_est)^2
gen SCAR_m10_p10=(car_M10_P10) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m10_p10 *  (1 + W_m10_p10/M + numerator/denominator))     )
drop numerator W_m10_p10
*For CAR(-2,+10):
gen numerator=(market_rets_m2_p10 - W_m2_p10 * Rm_bar_est)^2
gen SCAR_m2_p10=(car_M2_P10) / (    sqrt(1/(M-2)* sum_u_2)  * sqrt( W_m2_p10 *  (1 + W_m2_p10/M + numerator/denominator))     )
drop numerator W_m2_p10

save "C:\Users\suuser\Desktop\Delistings\Stata\data_short_l2.dta", replace
clear

use "C:\Users\suuser\Desktop\Delistings\Stata\data_short_l2.dta", clear
tabstat car_M1_P1-car_M2_P10, stats(N mean p50 min max) columns(stats)

rename yılönce lastopinion
rename var19 penultopinion

tabstat car_M1_P1-car_M2_P10 if lastopinion=="Olumlu", stats(N mean p50 min max) columns(stats)
tabstat car_M1_P1-car_M2_P10 if lastopinion=="Şartlı görüş", stats(N mean p50 min max) columns(stats)
tabstat car_M1_P1-car_M2_P10 if lastopinion=="Olumsuz", stats(N mean p50 min max) columns(stats)
tabstat car_M1_P1-car_M2_P10 if lastopinion=="görüş vermekten kaçınma", stats(N mean p50 min max) columns(stats)
tabstat car_M1_P1-car_M2_P10 if lastopinion=="-", stats(N mean p50 min max) columns(stats)



*t-tests for CARs 
foreach var of varlist SCAR_m1_p1- SCAR_m2_p10 {
di "`var'"
quietly summarize `var' 
scalar count_`var'=r(N)
scalar sqrt_count_`var'=sqrt(r(N))
scalar sd_`var'=r(sd)
scalar sum_`var'=r(sum)
scalar Z_`var'=sum_`var' / (sqrt_count_`var' * sd_`var')
di Z_`var'
}

* Check for t-stats
ttest car_M1_P1 ==0 if lastopinion=="görüş vermekten kaçınma"
ttest car_M0_P1 ==0 if penultopinion=="Olumsuz"
ttest car_M2_P2 ==0 if lastopinion=="görüş vermekten kaçınma"
ttest car_M5_P5 ==0 if lastopinion=="görüş vermekten kaçınma"
ttest car_M2_P5 ==0 if penultopinion=="Olumsuz"
ttest car_M10_P10 ==0 if lastopinion=="görüş vermekten kaçınma"
ttest car_M2_P10 ==0 if penultopinion=="Olumsuz"




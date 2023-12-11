//1
clear
cd "C:\Users\arman\OneDrive\UNI\Year 2 - 2022,23\ECN21004\Group work\dta"

use "UK_TRADE.dta"

//2

merge m:1 year month using "Brexit.dta"

//3

egen time=group(year month)

//4

egen prod_cod=group(hs4 ISO3)


//6

gen imp_u_val=imp_value/imp_weight

gen l_imp_val=log(imp_value+1)

gen l_imp_u_val=log(imp_u_val+1)

gen exp_u_val=exp_value/exp_weight

gen l_export=log(exp_u_val+1)

gen log_export=log(exp_value+1)



//5

recode hs2 1/5 = 0 6/15 = 1 16/24 = 2 25/27 = 3 28/38 = 4 39/40 = 5 41/43 = 6 44/49 = 7 50/63 = 8 64/67 = 9 68/71 = 10 72/83 = 11 84/85 = 12 86/89 = 13 90/max = 14

label define hs2 0 "Animal & Animal Products" 1 "Vegetable Products" 2 "Foodstuffs" 3 "Mineral Products" 4 "Chemicals & Allied Industries" 5 "Plastics / Rubbers" 6 "Raw Hides, Skins, Leather, & Furs" 7 "Wood & Wood Products" 8 "Textiles" 9 "Footwear / Headgear" 10 "Stone / Glass" 11 "Metals " 12 "Machinery / Electrical" 13 "Transportation" 14 "Miscellaneous", replace

label values hs2 hs2

//7
gen EU=0
replace EU=1 if ISO3=="AUT"|ISO3=="AUT"|ISO3=="FRA"|ISO3=="ITA"|ISO3=="DEU"|ISO3=="AUT"|ISO3=="BEL"|ISO3=="CZE"|ISO3=="CYP"|ISO3=="DNK"|ISO3=="ESP"|ISO3=="EST"|ISO3=="FIN"|ISO3=="HUN"|ISO3=="IRL"|ISO3=="LTU"|ISO3=="LUX"|ISO3=="LVA"|ISO3=="NLD"|ISO3=="POL"|ISO3=="ROU"|ISO3=="SWE"|ISO3=="SVK"|ISO3=="SVN"|ISO3=="BGR"|ISO3=="PRT"|ISO3=="GRC"|ISO3=="MLT"|ISO3=="HRV"


//8

edit time if month==6 & year==2016

gen brexit=0
replace brexit=1 if time > 48

preserve
collapse (mean) exp_u_val, by (ISO3)
save exp_value.dta
restore


gen log_exp_value=log(exp_value+1)
gen log_exp_eu = log_exp_value if EU==1
gen log_exp_nonEU= log_exp_value if EU==0

//9
preserve

collapse (mean) log_exp_eu log_exp_nonEU, by (time)

tset time
twoway (tsline log_exp_eu) (tsline log_exp_nonEU), xline(48)
graph export EXP_EU_&_noneu.png

restore 

//10


gen l_brexit_google=log(brexit_google+1)
gen l_no_deal_google=log(no_deal_google+1)

gen l_epu_global=log(epu_global+1)
gen l_epu_uk=log(epu_uk+1) //16


preserve

collapse (mean) l_brexit_google l_no_deal_google l_epu_global l_epu_uk, by (time)

tset time 
twoway (tsline l_epu_global, lcolor(blue)) (tsline l_epu_uk, lcolor(purple)) (tsline l_brexit_google, lcolor(orange)) (tsline l_no_deal_google, lcolor(green)), xline(48)
restore

graph export Logs_of_policy_uncertainty.png


//11

preserve

ssc install spmap
ssc install shp2dta
ssc install mif2dta

shp2dta using EU_COD, database(brexitdb) coordinates(brexitcoord) genid(id)

use brexitdb, clear

describe

merge 1:1 ISO3 using "exp_value"
drop _merge

spmap exp_u_val using brexitcoord, id(id) fcolor(Blues) clmethod(q) clnumber(4)
graph export EU_map.png

sum exp_u_val, de

restore


//12

ssc install outreg2
xtset prod_cod time

by prod_cod: gen period=_n

xtset prod_cod period

xtreg l_imp_u_val l_imp_val log_exp_value log_exp_eu, fe
estimates store fixed
outreg2 using BREX.xls

xtreg l_imp_u_val l_imp_val log_exp_value log_exp_eu, re
estimates store random
outreg2 using BREX.xls

hausman fixed random



xtreg log_exp_value log_exp_eu, fe
outreg2 using BREX.xls



//13


xtreg log_exp_value i.EU##i.brexit i.month i.year, fe rob
outreg2 using BREX.xls


//14

reghdfe log_exp_value i.brexit##i.EU, absorb(prod_cod time)
outreg2 using BREX.xls

//15

egen prod_year=group(hs4 year)
egen cod_year=group(country_code year)

reghdfe log_exp_value i.brexit##i.EU, absorb(prod_cod time prod_year cod_year)
outreg2 using BREX.xls


//17

reghdfe log_exp_value i.EU##c.l_epu_uk, absorb(prod_cod time prod_year cod_year)
outreg2 using BREX.xls


//18

levelsof hs2, local(hs2list)
foreach brexit in `hs2list'{
	reghdfe log_exp_value i.brexit##i.EU if hs2==`brexit', absorb(prod_cod time prod_year cod_year)
	outreg2 Commodities.xls
}


//19

gen na_countries=0
replace na_countries=1 if ISO3=="USA"|ISO3=="MEX"|ISO3=="CAN"

reghdfe log_export i.brexit##i.na_countries, absorb(prod_cod time prod_year cod_year)
outreg2 using BREX.xls


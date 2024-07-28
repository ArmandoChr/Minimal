cd "C:\Users\arman\OneDrive\UNI\Year 2 - 2022,23\Portofolio\FInance\Task2"

use "C:\Users\arman\OneDrive\UNI\Year 2 - 2022,23\Portofolio\FInance\Task2\Bond yield time data.dta", clear

//1a
gen time = tm(1919m1)+_n-1
format %tm time

//do i need logs for these or just the raw values? 
* why did I do ln(x)*100 tho?
*gen l_baa = ln(baa+1)
*gen l_aaa = ln(aaa+1)
gen SP=baa-aaa
label variable SP "Corp bond spread"

//1b
//downloaded

//1c

gen new_date1 = date(Date, "YMD")
gen D2007=inrange(new_date1,date("Dec 1, 2007", "MDY"),date("Jun 1, 2009", "MDY"))


//1d
ssc install HAMILTONFILTER

gen l_PROD=ln(Prod)


tset time
hamiltonfilter l_PROD, stub(cyclical) freq(monthly)
drop cyclical_trend

gen cycle=cyclical_cycle * 100

tsline SP cycle

//1e

gen inflation=ln(((SP)/(SP[_n-12]))*100)

//2
* Double check which variables to include in this 
summarize SP inflation cycle


//3
preserve
by time, sort: drop if sum(!mi(cycle)) == 0

pwcorr SP l_PROD cycle inflation, star(.05) sig 

restore

//4
regress SP cycle  D2007 fedfunds inflation 
//5 is a writing task


//6a
tsline SP if tin(2018m1, 2022m12)


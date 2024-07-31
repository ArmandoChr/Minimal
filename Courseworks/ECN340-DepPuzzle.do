  /*Stata Government spending SVAR*/ 

clear
* paste the path of your working directory below
cd "\\studata08\home\EC\Ece21ac\ManWin\My Documents\Y3\ECN340\WS\WS2"
*cd "C:\Users\arman\OneDrive\UNI\Year 3 - 2023,24\ECN340\Coursework\Data"



***** Import the data from the Excel spreadsheet

import excel "US_data.xlsx", sheet("US") cellrange(A1:H153) firstrow
*browse

/* Dataset

News: Forecast revisions of government spending growth 
FNews: The news measure to be used in the Hamilton-filtered data 
GOV: Real Federal Government Spending
GDP: Real GDP
CON: Real total private consumption
REXR: Real effective exchange rate
NEXP_GDP: Trade balance as a percentage of GDP
*/


* read dates in a way that Stata can understand
drop Date
generate Date = q(1982q1)+_n-1
format Date %tq
******
* set the data as time setries
tsset Date

******************************************************************************
*			                  Housekeeping 									 *
******************************************************************************
/* 
 Transform time series in log-levels and first logarithmic differences. 
 Detrend the time series using the hamilton filter -> (Expres each variable as 
 pp deviation from the GDP trend)
*/
gen time_trend = _n
*GDP
* transform gdp 
* logarithms
gen lgdp = log(GDP)* 100
*first logarithmic differences
gen dlgdp = d.lgdp

/* applying hamilton filter. I will extract the trend and the cyclical component from the variable.
  regress a time series shifted 8 periods ahead, against 0-3 lags of the variable.
* For example yt+8 = b0 + b1*yt  + b2*yt-1 + b1*yt-2  + b1*yt-3 + ut-4 or equivalently 
* 			  yt   = b0 + b1*yt-8 + b2*yt-9 + b1*yt-10  + b1*yt-11 + ut 
* Fitted values will be the trend and the residual the cycle component*/

* Hamilton filtering (applied on logarithms)
reg lgdp l(8/11).lgdp
*save the residual (cycle component)
predict cycle, r 
*save the fitted values (trend)
predict trend,xb

* Plot - actual lgdp and trend (uncomment to see the plots)
tsline lgdp trend 
* Plot - detrended lgdp and first differences
tsline cycle  dlgdp
tsline cycle

* Transform the rest of the variables. logarithms, first-differneces and 
* detrend the variables using the lag of the gdp trend from hamilton filter

* GDP
gen lgdp_h = (lgdp-l.trend) 

* Government spending
gen lgov = log(GOV)* 100
gen dlgov = d.lgov 
gen lgov_h = (lgov-l.trend) 

* Private Consumption
gen lcon = log(CON)* 100
gen dlcon = d.lcon 
gen lcon_h = (lcon-l.trend) 

gen lrer = log(REXR)*100
gen dlrer = d.lrer 

* Plots
tsline lgdp   lgov    lcon 
tsline lgdp_h lcon_h
tsline lcon_h
* this basically shows that GDP GOV and CON all go hand in hand.
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *



******************************************************************************
*			                  VAR analysis 									 *
******************************************************************************

* log-levels 4-lags 
set more off
var lgov News lgdp lcon lrer NEXP_GDP, lag(1/4)   
varstable, graph  
* values are less than 1 (inside the circle) so the model is stable



cap drop LOGLEVLS
irf create LOGLEVLS, step(21) set(OIRF, replace)
* Run input response function 21 periods ahead (OIRF is cholesky decomp.)



*if grey is on the 0 line, then the response is not significant for those periods!!!!

irf graph oirf, impulse(News) response(lgov News lgdp lcon lrer NEXP_GDP ) level(80) yline(0) byopts(yrescale) 
*equal response function of shock of news on response variables in that order.
*increase in news (what does that actually mean tho and what is news?)


/*

Professor notes on results:
read cortsetti section 3. If there are increase gov exp. then appreciation. This increases return on domestic investment. Therefore, Investments increase. This is the same as output increasing.
Cannot talk about shocks if they are not significant. cannot claim theory holds because of line.

Higher significance level (90 instead of 80) causes almost no results to be significant.

Prof wants few words. Write 4 or 5 pages and put stuff in appendix. He enjoys the words more than the pictures.

Do not use non-fundamental in discussion. Put it in econometric issue section. 

*/

irf graph oirf, impulse(lgov) response(lgov News lgdp lcon lrer NEXP_GDP ) level(80) yline(0) byopts(yrescale) 
*equal response functino of lgov (fiscal policy) on the other variables.

/*
This is surprise shock I think
Twin deficit does not hold because of puzzle. lgov lgov is sig for almost 12 quarters aka 3 years. There is a depreciation which is sig after a year. The dep. causes increase in net exports (NEXP_GDP)

Consumption goes down to pay future taxes. 
return of dom invest is going down and therefore there is a negative response of gdp. 


Look at RER and look at NEXP_GDP, then see CONS and GDP (explained from theory). 
	Ricardian equiv.

Shocks on levels btw

*/

* WITH HAMILTON *
*** Hamilton filter 4-lags 
set more off
var lgov_h Fnews lgdp_h lcon_h lrer NEXP_GDP, lag(1/4)  
varstable, graph 


/*
Now we use the hamilton filter.
*/


cap drop Hamilton
irf create Hamilton, step(21) set(OIRF, replace)
irf graph oirf, impulse(Fnews) response(lgov_h Fnews lgdp_h lcon_h lrer NEXP_GDP ) level(80) yline(0) byopts(yrescale) 

/*
Picture should be ish the same but it is more significant here. 
More persistent impact on News. 2 years almost. 

Appreciation of RER. Lasts almost 1.5 years.
	NEXP_GDP has negative impact. Declines trade for 2 years.
	Consumption is only for 2 quarters. Brief impact on cons. negative impact.
		Brief sig. impact on GDP. 
		GDP is sum of cons. and inv. Almost no sig so response of inv was also not sig. 

Effect on lgov_h is sig and strong and positive. expects it to increase and so it does. 
*/


irf graph oirf, impulse(lgov_h) response(lgov_h Fnews lgdp_h lcon_h lrer NEXP_GDP ) level(80) yline(0) byopts(yrescale) 
/*
surprise shock

appreciation but not sig. depreciation after two years. 
	NEXP_GDP positive effected and long lasted and significant.
	Cons is pos for a few quarters but then negative. 
		GDP follows same trend. So Inv can be calculated from the difference.
*/






* fevd not necessary
irf graph fevd, impulse(lgov_h) response(lgov_h Fnews lgdp_h lcon_h lrer NEXP_GDP ) level(80) yline(0) byopts(yrescale)  

/*
Going over essay structure again
Intro
	explain why RQ is important. 
		Fiscal is important because recession tool.
			Problem is expan. fisc. can lead to current account deficit. 
			Twin deficit crisis. 
				Under what conditions (corsetti more open and more persistent)
				talk about lit review.
					Can also be twin divergence. 
					Explain the exchange rate puzzle. (forni and gambetti. Fiscal reversal effect)
					Econometric issues introduced. Omitted variable problem (News)
						What is this essay going to do

Seciton 2
theoretical opinions


Section 3
Econometric issues. Gambetti's paper. News omitted variable. Shocks and surprise shocks. Impulse response function

Sectino 4
Plot the function and discuss it with stats terms



Section 5
Conclude and answer RQ





*/
gen glinv = d.linv









* Differences 4-lags 
//not sure what this means
gen dNEXP_GDP=d.NEXP_GDP
set more off
var dlgov News dlgdp dlcon dlrer dNEXP_GDP if  Date < tq(2019q4), lag(1/4)   

*gives individual graphs i think?
cap drop FDif
irf create FDif, step(21) set(OIRF, replace)
irf graph oirf, impulse(News) response(News dlgdp dlcon  dlrer dNEXP_GDP) level(80) yline(0) in iname(Fdif_news, replace) 
irf graph coirf, impulse(News) response(dlgov News dlgdp dlcon  dlrer dNEXP_GDP) level(86) yline(0) in iname(Fdif_news_cum, replace) 

irf graph oirf, impulse(dlgov) response(dlgov News dlgdp dlcon  dlrer dNEXP_GDP) level(86) yline(0) in iname(Fdif_gov, replace) 
irf graph coirf, impulse(dlgov) response(dlgov News dlgdp dlcon dlrer dNEXP_GDP) level(86) yline(0) in iname(Fdif_gov_cum, replace) 
//missing dlinv so i got ridd of it :D



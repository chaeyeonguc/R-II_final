---
title: "writeup"
author: "Chaeyeong Park"
date: "2024-12-06"
output:
  word_document: default
  pdf_document: default
  html_document: default
---

## Introduction (Motivation and Research Question)
This is the writeup summarizing the final project for Data and Programming for Public Policy II - R Programming. The research is motivated by the global issue and development programs; Persistent poverty in Low-income countries and trends of finance-focused poverty alleviation programs. Despite a global decline in poverty rates over recent 20 years, low-income countries have remained nearly stagnant, trapped into poverty where over 50% of the population continues to struggle for less than $2.15 per day (World Bank. (2024). Poverty and Inequality Platform. World Bank Group. https://pip.worldbank.org/). To address this poverty issue, one of the most popular poverty alleviation program is microfinance, targetting minorities who are inaccessible to financial services and provide complements. This raised curiosity about how financial accessibility can improve poverty such that the research question below is suggested:
How and what type of financial inclusion for the poor is correlated with poverty levels across countries?

## Data Source
The research involves five data sources:

1. World Bank Global Findex Database 2021: 4 financial inclusion indicators (account, saving, borrowing, and digital payment) for income, poorest 40% (% ages 15+) across countries in 2014, 2017, and 2021 (directly downloaded its .xlsx from the world bank homepage: https://www.worldbank.org/en/publication/globalfindex/Data, choosing country-level .xlsx file.)

2. World Development Indicators: Poverty headcount ratio (%) (used the package “WDI” in R)

3. IMF Real GDP Growth (retrieved from the API as the .json version from IMF DataMapper API documentation: https://www.imf.org/external/datamapper/api/v1/NGDP_RPCH)

4. Natural Earth: world choropleth map (directly downloaded its .zip file, including the shape version from the natural earth homepage: https://www.naturalearthdata.com/downloads/10m-cultural-vectors/, choosing Admin o - Countries (version 5.1.1))

5. CAN MICROFINANCE UNLOCK A POVERTY TRAP FOR SOME ENTREPRENEURS?: The research paper (directly downloaded its pdf file from the NATIONAL BUREAU of ECONOMIC RESEARCH homepage: https://www.nber.org/papers/w26346)

You can see the detailed data processing in data.R.

## Methodology
This study employs a quantitative, correlational research method with panel data mainly sourced from World Bank. It is hypothesized that there is a negative correlation between financial inclusion percentages for the poor and poverty headcount ratio. Due to year variation across countries, the analysis uses panel data across 47 countries among a total of 89 countries, which have all years (2014, 2017 , and 2021) data. A Fixed-Effects panel regression model controls unobserved time-invariant characteristics at the country level, with clustered standard errors to account for correlation within countries over time. This design enables to apply fixed-effect for a balanced panel, which provides robust insights into the temporal relationships between financial inclusion variables and poverty across years and controls for country-level unobserved heterogenity. However, as the sample size was reduced, it potentially limits the generalizability of results. Data wrangling, visualization by static plots and shiny app, text processing, and model fitting are primary code approaches taken for this project. For further detailed code, please refer to each R script and README file.

## Research Design
The research is designed for Fixed-Effects panel regression model. Its formula is as follows:

Poverty_Headcount_Ratio_it = β0 + β1(Account_Ownership_it) + β2(Savings_it) + β3(Borrowing_it) + β4(Digital_Payments_it) + β5(GDP_it) + α_i + γ_t + ε_it

Dependent Variable:
Poverty Level: Poverty_Headcount_Ratio

Independent Variables (Financial Inclusion):
Account_Onership: Percentage of account ownership among income, poorest 40% (% ages 15+). 
Savings: Percentage of those saved any money, among income, poorest 40% (% ages 15+).
Borrowing: Percentage of those borrowed any money among income, poorest 40% (% ages 15+).
Digital_Payments: Percentage of those Made or received a digital payment among income, poorest 40% (% ages 15+).

Control Variables:
Real GDP Growth

$i$: Country.
$t$: Year.
$𝛼_𝑖$: Country fixed effects.
$𝛾_𝑡$: Year fixed effects.
$𝜖_𝑖𝑡$: Error term

## Visualization
There are two static plots and shinyapps, respectively. 
"plot_financial_inclusion_by_poverty.png" shows the estimated financial inclusion for the poor from the linear model with the poverty headcount ratio, differentiating each financial inclusion indicators. Except for borrowing, most indicators show a negative relationship with poverty.
"choropleth_financial_inclusion.png" provides an overview of average financial inclusion extent for the poor in the world by scatter plots for each country in the world map; more blue scatter plot is, higher average financial inclusion is.
Please see the detailed coding for those two static plots in staticplot.R

In shiny apps, the first app shows scatter plots allowing to select a country and year and visualize how financial inclusion for the poor correlates with poverty.
The second app is text process with the pdf file "Microfinance_poverty_trap.pdf", the research "CAN MICROFINANCE UNLOCK A POVERTY TRAP FOR SOME ENTREPRENEURS?". The app was created for line graphs showing keywords specific sentiment. The keywords were selected for the most 10 common words used in the paper. The app allows users to select one over 10 keywords, and shows its sentiment trend across page numbers, which is estimated by AFINN. The first page and reference pages are omitted in the graph. This app helps readers identify contexts for reading the paper that how each keyword is used and refer to specific page number by showing keyword's sentiment across page numbers.

## Conclusion and implications

| Variable                                 | Coefficient | Standard Error |
|------------------------------------------|-------------|----------------|
| Account Ownership (Income, poorest 40%)  | 0.505       | (3.344)        |
| Savings (Income, poorest 40%)            | 0.757       | (1.200)        |
| Borrowing (Income, poorest 40%)          | 3.524*      | (1.807)        |
| Digital Payments (Income, poorest 40%)   | -3.146      | (2.595)        |
| Real GDP Growth                          | -0.004      | (0.034)        |
| **Observations**                         | 141         |                |
| **R²**                                   | 0.172       |                |
| **Adjusted R²**                          | -0.302      |                |
| **F Statistic**                          | 3.703*** (df = 5; 89)        |
| **Note**                                 | *p<0.1; **p<0.05; ***p<0.01  |

The regression results show that a 10 percentage point increase in borrowing among the 40% poorest is associated with an increase of 0.3524 percentage points in the poverty rate at 10% significance level in 47 countries in 2014, 2017, and 2021. This indicates hypothesis fails; the borrowing is rather positively associated with poverty and drived further research on potential issues with debt management among the poorest groups. For further research, please see the text processing in the second shiny app above in visualization section.
Meanwhile, coefficients for other indicators are not statistically significant, reflecting data limitation or limited direct effects on poverty rates in the studied context. 
Please see the detailed coding for model fitting in model.R.
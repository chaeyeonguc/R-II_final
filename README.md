Chaeyeong Park

Date Created: 12/06/2024

Date Modified: 12/06/2024

Required R packages: tidyverse, httr, jsonlite, WDI, readxl, sf, pdftools, tidytext, udpipe, igraph, ggraph, shiny, plotly, plm, stargazer, lmtest, styler

Version of R used: 2023-03-15 (Version 4.2.3)

Summary of code: This is R II programming final project to investigate how and what types of financial inclusion for the poor are correlated with poverty levels across countries. There are several r scripts to be reviewed:

data.R contains any data loading, retrieval, and wrangling for further plotting and model fitting. The number of datasets are 4:

1. Global Findex 2021 Database: the raw data "DatabankWide.xlsx" is directly downloaded to the data folder then filtered with necessary columns such as country name, country code, year, income group and financial inclusion indicators; "Account, income, poorest 40% (% ages 15+)", "Saved any money, income, poorest 40% (% ages 15+)", "Borrowed any money, income, poorest 40% (% ages 15+)", and "Made or received a digital payment, income, poorest 40% (% ages 15+)". The cleaning additionally omitted na values and renamed the indicators more intuitively and renamed all to lower capital.
2. World Development Indicators: The raw data "wdi_raw.csv" is retrieved from the package "WDI" in R and extracted from the indicator poverty headcount ratio (SI.POV.DDAY). The function retrieve_wdi allows the data to be retrieved from the package if no raw data exists in the data folder or is loaded in the data path. It filtered the necessary columns for cleaning, such as country name, year, income group, poverty headcount ratio, and geometry (latitude and longitude). It filtered out aggregate variables in income group columns, which means aggregated by regions, not country level. The cleaning additionally omitted na values and renamed the indicators more intuitively and renamed all to lower capital.
3. IMF's real GDP growth: The raw data "imf_gdp_growth_raw.json" is retrieved from the API as the .json version. The function retrieve_raw_json allows data to be retrieved from the API if no raw data exists in the data folder or if it is loaded in the path otherwise. Then, it is converted as a data frame and reshaped into longer to show a similar data structure as other datasets. For cleaning, it also filtered the necessary columns such as country code, year, and GDP and included only after 2014 years, which is the start year in the other datasets. It additionally omitted na values as well.

Finally, those 3 cleaned datasets are merged together, processed further reshaping and cleaning, and written as CSV files as "inclusive_poverty_gdp_long.csv" and "inclusive_poverty_gdp_model.csv" for the plotting and model fitting steps, accordingly.

4. Natural Earth: The raw data "ne_10m_admin_0_countries.zip" (world map) is directly downloaded and unzipped to the data folder, including its shapefile.

static plot.R contains two static plots: "plot_financial_inclusion_by_poverty" and "choropleth_financial_inclusion." The first plot shows the estimated financial inclusion for the poor from the linear model with the poverty headcount ratio, differentiating each financial inclusion indicators. Except for borrowing, most indicators show a negative relationship with poverty. The second choropleth was created by combining the world map from Natural Earth's shapefile with the converted spatial format from the inclusive_poverty_gdp_long data by using sf package. It provides an overview of average financial inclusion extent for the poor in the world by scatter plots for each country in the world map; more blue scatter plot is, higher average financial inclusion is.

shinyapp.R contains two shiny apps. The first app shows scatter plots allowing to select a country and year and visualize how financial inclusion for the poor correlates with poverty. The second app is text process with the pdf file "Microfinance_poverty_trap.pdf", the research "CAN MICROFINANCE UNLOCK A POVERTY TRAP FOR SOME ENTREPRENEURS?". After loading the text from the pdf and turned into a dataframe, the app was created for line graphs showing keywords specific sentiment. The keywords were selected for the most 10 common words used in the paper. The app allows users to select one over 10 keywords, and shows its sentiment trend across page numbers, which is estimated by AFINN. The first page and reference pages are omitted in the graph.

model.R contains results of the fixed-effect panel regression. Due to year variances across countries, the model uses the dataset "inclusive_poverty_gdp_model" filtering countries having all 2014, 2017, and 2021 data only for the balance. The model analyzes the correlations between the poverty head count ratio and 4 financial inclusions indicators with control variable, the real GDP growth, the fixed effect and clustered standard error in country-level. The results show that a 10 percentage point increase in borrowing is associated with an increase of 0.3524 percentage points in the poverty rate at 10% significance level while coefficients for other indicators are not statistically significant. For futher research, text process was involved to explore how debt managment among the poor is negatively associated with the poverty.

Note: textprocess.R has no contant, as it is written in the shinyapp.R instead.

All R files should be run in order from top to bottom. Note that the current directory in R needs to be set to the directory containing the R-II_final folder.

Explanation of original data source: 

"DatabankWide.xlsx" is directly downloaded from the world bank homepage: https://www.worldbank.org/en/publication/globalfindex/Data, choosing country-level .xlsx file. 

"wdi_raw.csv" is retrieved from the package "WDI" in R.

imf_gdp_growth_raw.json" is retrieved from the API as the .json version from IMF DataMapper API documentation: https://www.imf.org/external/datamapper/api/v1/NGDP_RPCH

"ne_10m_admin_0_countries.zip" is directly downloaded from the natural earth homepage: https://www.naturalearthdata.com/downloads/10m-cultural-vectors/, choosing Admin o - Countries (version 5.1.1).

"Microfinance_poverty_trap.pdf" is directly downloaded from the NATIONAL BUREAU of ECONOMIC RESEARCH homepage: https://www.nber.org/papers/w26346

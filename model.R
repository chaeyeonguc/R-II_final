library(tidyverse)
library(styler)
style_file("/Users/yeong/Documents/GitHub/R-II_final/data.R")

# Load the final dataset
inclusive_poverty_gdp <- read_csv("data/inclusive_poverty_gdp.csv")

# For research design, create a table summarizing yearly country counts
# to decide either using panel data or cross sectional data

## the total number of countries
total_countries <- n_distinct(inclusive_poverty_gdp$`country name`)

# the number of countries by the number of year data each country has
all_years_countries <- inclusive_poverty_gdp %>%
  group_by(`country name`) %>%
  summarise(year_count = n_distinct(year)) %>%
  filter(year_count == 3) %>%
  nrow()

two_years_countries <- inclusive_poverty_gdp %>%
  group_by(`country name`) %>%
  summarise(year_count = n_distinct(year)) %>%
  filter(year_count == 2) %>%
  nrow()

one_year_countries <- inclusive_poverty_gdp %>%
  group_by(`country name`) %>%
  summarise(year_count = n_distinct(year)) %>%
  filter(year_count == 1) %>%
  nrow()

## count yearly country 
yearly_country_count <- inclusive_poverty_gdp %>%
  group_by(year) %>%
  summarise(
    yearly_countries = n_distinct(`country name`)
  ) %>%
  mutate(
    total_countries = total_countries,
    countries_missing_years = total_countries - yearly_countries,
    countries_all_years = all_years_countries,
    countries_two_years_only = two_years_countries,
    countries_one_year_only = one_year_countries
  )
view(yearly_country_count)


# Data cleaning to test fixed effect model fit 
## filter countries having 3 years
three_years_only <- inclusive_poverty_gdp %>%
  filter(n_distinct(year) == 3)
##


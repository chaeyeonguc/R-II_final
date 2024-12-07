library(tidyverse)
library(httr)
library(jsonlite)
library(WDI)
library(readxl)
library(sf)
library(styler)
style_file("data.R")

# Load and retrieve raw data
## Define data folder path
data_path <- "data/"

## Load Global Findex 2021 Database
path_global_findex <- paste0(data_path, "DatabankWide.xlsx")
global_findex_raw <- read_xlsx(path_global_findex,
  sheet = "Data"
)

## Retrieve World Development Indicators from package (Extract poverty headcount ratio)
retrieve_wdi <- function(indicator = "SI.POV.DDAY", start_year = 2010, end_year = 2021) {
  raw_file <- paste0(data_path, "wdi_raw.csv")

  if (!file.exists(raw_file)) {
    filtered <- WDI(indicator = indicator, start = start_year, end = end_year, extra = TRUE)
    write_csv(filtered, raw_file)
    wdi_raw <- read_csv(raw_file)
  } else {
    wdi_raw <- read_csv(raw_file)
  }
  return(wdi_raw)
}

wdi_raw <- retrieve_wdi()

## Retrieve IMF's GDP from API
retrieve_raw_json <- function() {
  raw_file <- paste0(data_path, "imf_gdp_growth_raw.json")

  if (!file.exists(raw_file)) {
    url <- "https://www.imf.org/external/datamapper/api/v1/NGDP_RPCH"
    response <- GET(url)
    writeLines(content(response, as = "text", encoding = "UTF-8"), raw_file)
    gdp_raw <- read_json(raw_file)
  } else {
    gdp_raw <- read_json(raw_file)
  }
  return(gdp_raw)
}

gdp_raw <- retrieve_raw_json()

## Load the downloaded a shapefile for the world map (used for shinyapp afterwords)
zipF <- paste0(data_path, "ne_10m_admin_0_countries.zip")
unzip(zipF, exdir = data_path)

# Data Cleaning
## Global Findex
financial_inclusion_poor <- c(
  "Account, income, poorest 40% (% ages 15+)",
  "Saved any money, income, poorest 40% (% ages 15+)",
  "Borrowed any money, income, poorest 40% (% ages 15+)",
  "Made or received a digital payment, income, poorest 40% (% ages 15+)"
)

global_findex_clean <- global_findex_raw %>%
  select(`Country name`, `Country code`, Year, `Income group`, all_of(financial_inclusion_poor)) %>%
  na.omit() %>%
  rename(
    per_account_ownership_poor = `Account, income, poorest 40% (% ages 15+)`,
    per_saving_poor = `Saved any money, income, poorest 40% (% ages 15+)`,
    per_borrowing_poor = `Borrowed any money, income, poorest 40% (% ages 15+)`,
    per_digital_payment_poor = `Made or received a digital payment, income, poorest 40% (% ages 15+)`
  ) %>%
  rename_all(tolower)

## World Development Indicator
wdi_clean <- wdi_raw %>%
  select(country, year, income, SI.POV.DDAY, latitude, longitude) %>%
  filter(!income %in% c("Aggregates")) %>%
  na.omit() %>%
  rename(poverty_headcount_ratio = SI.POV.DDAY) %>%
  rename_all(tolower)

## GDP from IMF (converting to csv file)
gdp_df <- as.data.frame(gdp_raw)
gdp_df_longer <- gdp_df %>%
  select(where(is.numeric)) %>%
  pivot_longer(
    cols = everything(),
    names_to = c("type", "indicator", "country code", "year"),
    names_sep = "\\."
  ) %>%
  rename(gdp = value)

gdp_clean <- gdp_df_longer %>%
  select(`country code`, year, gdp) %>%
  filter(year >= 2014) %>%
  na.omit()

# Merge those datasets
combined <- global_findex_clean %>%
  inner_join(wdi_clean, by = c(
    `country name` = "country",
    "year",
    `income group` = "income"
  ))

gdp_clean$year <- as.numeric(gdp_clean$year)

combined <- combined %>%
  inner_join(gdp_clean, by = c("country code", "year"))

# Reshape the combined dataset longer and write it for further plotting
inclusive_poverty_gdp_long <- combined %>%
  pivot_longer(cols = starts_with("per_"), names_to = "metric", values_to = "value") %>%
  group_by(`country name`) %>%
  mutate(avg_value = mean(value, na.rm = TRUE))

write_csv(inclusive_poverty_gdp_long, paste0(data_path, "inclusive_poverty_gdp_long.csv"))

# Further exploratory data analysis for the research design
## Create a table to look at yearly country counts for the research design
## to decide either using panel data or cross sectional data
total_countries <- n_distinct(combined$`country name`)

all_years_countries <- combined %>%
  group_by(`country name`) %>%
  summarise(year_count = n_distinct(year)) %>%
  filter(year_count == 3) %>%
  nrow()

two_years_countries <- combined %>%
  group_by(`country name`) %>%
  summarise(year_count = n_distinct(year)) %>%
  filter(year_count == 2) %>%
  nrow()

one_year_countries <- combined %>%
  group_by(`country name`) %>%
  summarise(year_count = n_distinct(year)) %>%
  filter(year_count == 1) %>%
  nrow()

yearly_country_count <- combined %>%
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

# Prepare data for the model fitting (fixed-effect panel regression model)
## Filter countries having 3 years
three_years_only <- combined %>%
  group_by(`country name`) %>%
  filter(n_distinct(year) == 3)

## Write the filtered dataset
write_csv(three_years_only, paste0(data_path, "inclusive_poverty_gdp_model.csv"))

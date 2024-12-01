library(tidyverse)
library(httr)
library(jsonlite)
library(WDI)
library(styler)
style_file("/Users/yeong/Documents/GitHub/R-II_final/data.R")

# Load and retrieve raw data
## Define data folder path
data_path <- "/Users/yeong/Documents/GitHub/R-II_final/data/"

## Load Global Findex 2021 Database
path_global_findex <- paste0(data_path, "DatabankWide.xlsx")
global_findex_raw <- read_xlsx(path_global_findex,
  sheet = "Data"
)

## Retrieve World Development Indicators from package (selecting poverty headcount ratio)
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
  select(country, year, income, SI.POV.DDAY) %>%
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

# Merge datasets
combined <- global_findex_clean %>%
  inner_join(wdi_clean, by = c(
    `country name` = "country",
    "year",
    `income group` = "income"
  ))

gdp_clean$year <- as.numeric(gdp_clean$year)

combined <- combined %>%
  inner_join(gdp_clean, by = c("country code", "year"))

# Write the final dataset
write_csv(combined, paste0(data_path, "final.csv"))

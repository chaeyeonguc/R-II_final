library(tidyverse)
library(httr)    
library(jsonlite)
library(WDI)

# Load and retrieve data
## Define data folder path
data_path <- "/Users/yeong/Documents/GitHub/R-II_final/data/"
raw_path <- paste0(data_path, "raw/")

## Load Global Findex 2021 Database
path_global_findex <- paste0(raw_path, "DatabankWide.xlsx")
global_findex <- read_xlsx(path_global_findex,
                           sheet = "Data")

## Retrieve World Development Indicators from package (extracting poverty headcount ratio)
retrieve_wdi <- function(indicator = "SI.POV.DDAY", start_year = 2010, end_year = 2021) {
  raw_file <- paste0(raw_path, "wdi_raw.csv")

  if (!file.exists(raw_file)) {
    wdi <- WDI(indicator = indicator, start = start_year, end = end_year, extra = TRUE)
    write_csv(wdi, raw_file)
  } 
  else {
    wdi <- read_csv(raw_file)
  }
  return(wdi)
}

wdi <- retrieve_wdi()

## Retrieve IMF's GDP from API
retrieve_raw_json <- function() {
  raw_file <- paste0(raw_path, "imf_gdp_growth_raw.json")
  
  if (!file.exists(raw_file)) {
    url <- "https://www.imf.org/external/datamapper/api/v1/NGDP_RPCH"
    response <- GET(url)
    writeLines(content(response, as = "text", encoding = "UTF-8"), raw_file)
    
  }
  else{
    gdp <- read_json(raw_file)
  }
  return(gdp)
}

gdp <- retrieve_raw_json()

# Data Wrangling
## Global Findex
financial_inclusion_poor <- c("Account, income, poorest 40% (% ages 15+)",
    "Coming up with emergency funds in 30 days: not possible, income, poorest 40% (% ages 15+)",
    "Most worrying financial issue: paying for medical costs in case of a serious illness or accident, income, poorest 40% (% ages 15+)")

global_findex <- global_findex %>%
  select(`Country name`,`Country code`, Year, `Income group`, all_of(financial_inclusion_poor)) %>%
  na.omit() %>%
  rename(per_account_ownership_poor = `Account, income, poorest 40% (% ages 15+)`,
         per_inaccessible_emergency_funds_poor = `Coming up with emergency funds in 30 days: not possible, income, poorest 40% (% ages 15+)`,
         per_medical_cost_poor = `Most worrying financial issue: paying for medical costs in case of a serious illness or accident, income, poorest 40% (% ages 15+)`) %>%
  rename_all(tolower)

## World Development Indicator
wdi <- wdi %>%
  select(country, year, income, SI.POV.DDAY) %>%
  filter(!income %in% c("Aggregates")) %>%
  na.omit() %>%
  rename(poverty_headcount_ratio = SI.POV.DDAY) %>%
  rename_all(tolower)

## GDP from IMF (Converting to csv file)
gdp_df <- as.data.frame(gdp)
gdp <- write.csv(gdp_df, file = "imf_gdp.csv", row.names = FALSE)

data <- content$CompactData$DataSet$Series %>%
    bind_rows() %>%
    rename(Country = @REF_AREA, Year = @TIME_PERIOD, GDP_per_capita = @OBS_VALUE)

write_csv(processed_data, processed_file)
summary(global_findex)
summary(wdi)
summary(undp)

# Standardize column names (if necessary)
findex <- findex %>% rename_all(tolower)
wdi <- wdi %>% rename_all(tolower)
undp <- undp %>% rename_all(tolower)

# Step 3: Merge Datasets
# Ensure you have common keys like `country` or `iso_code`
merged_data <- findex %>%
  full_join(wdi, by = c("country" = "country")) %>%
  full_join(undp, by = c("country" = "country"))

# Step 4: Reshape Data (if needed)
# Example: Pivoting data for time-series analysis
reshaped_data <- merged_data %>%
  pivot_longer(cols = starts_with("year_"), names_to = "year", values_to = "value") %>%
  mutate(year = str_remove(year, "year_"))  # Clean up year column

# Step 5: Save Cleaned Data
write_csv(merged_data, "processed_data.csv")
write_csv(reshaped_data, "reshaped_data.csv")

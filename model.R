library(tidyverse)
library(plm)
library(stargazer)
library(lmtest)
library(styler)
style_file("/Users/yeong/Documents/GitHub/R-II_final/data.R")

# Load the prepared dataset
data <- read_csv("data/inclusive_poverty_gdp_model.csv")

# Model fit (Fixed Effects Model)
fe_model <- plm(
  poverty_headcount_ratio ~ per_account_ownership_poor + per_saving_poor + 
    per_borrowing_poor + per_digital_payment_poor + gdp,
  data = data,
  index = c("country.name", "year"),  
  model = "within"
)

# Cluster standard error
clustered_se <- vcovHC(fe_model, method = "arellano", type = "HC0", cluster = "group")
se_clustered <- sqrt(diag(clustered_se))

# Create a summary table
stargazer(
  fe_model, 
  se = list(se_clustered),
  type = "html",
  out = "model_results.html",
  dep.var.labels = "Poverty Headcount Ratio", 
  covariate.labels = c(
    "Account Ownership (Income, poorest 40% (% ages 15+))", 
    "Savings (Income, poorest 40% (% ages 15+))", 
    "Borrowing (Income, poorest 40% (% ages 15+))", 
    "Digital Payments (Income, poorest 40% (% ages 15+))", 
    "Real GDP Growth"
  ),
  title = "Fixed Effects Model with Clustered Standard Errors",
  align = TRUE,
  no.space = TRUE
)

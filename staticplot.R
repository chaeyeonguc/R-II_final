library(tidyverse)
library(styler)
style_file("/Users/yeong/Documents/GitHub/R-II_final/staticplot.R")

inclusive_poverty_gdp <- read_csv("data/inclusive_poverty_gdp.csv")
colnames(inclusive_poverty_gdp)

# Creating a plot financial inclusion for the poor vs poverty headcount ratio across years
inclusive_poverty_gdp_long <- inclusive_poverty_gdp %>%
  pivot_longer(cols = starts_with("per_"), names_to = "metric", values_to = "value")

plot_financial_inclusion_by_poverty <- inclusive_poverty_gdp_long %>%
  ggplot(aes(x = poverty_headcount_ratio, y = value, color = metric)) +
  geom_smooth(method = "lm", se = FALSE, size = 1) +
  facet_wrap(~year) +
  labs(
    title = "Trends in Financial Inclusion vs Poverty across Years",
    x = "Poverty Headcount Ratio",
    y = "Financial Inclusion for income, poorest 40% (% ages 15+)",
    color = "Metric"
  ) +
  theme_minimal()

print(plot_financial_inclusion_by_poverty)

# Creating a plot analyzing natural language

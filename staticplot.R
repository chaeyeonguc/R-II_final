library(tidyverse)
library(sf)
library(styler)
style_file("/Users/yeong/Documents/GitHub/R-II_final/staticplot.R")

inclusive_poverty_gdp_long <- read_csv("data/inclusive_poverty_gdp_long.csv")

# Creating a plot estimating financial inclusion by poverty headcount ratio across years
plot_financial_inclusion_by_poverty <- inclusive_poverty_gdp_long %>%
  ggplot(aes(x = poverty_headcount_ratio, y = value, color = metric)) +
  geom_smooth(method = "lm", se = FALSE, size = 1) +
  facet_wrap(~year) +
  labs(
    title = "Trends in Financial Inclusion vs Poverty across Years",
    x = "Poverty Headcount Ratio",
    y = "Estimated Financial Inclusion (from LM)",
    color = "Metric"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 10),
    plot.title = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 10),
    legend.position = "bottom",
    legend.title = element_text(size = 8),
    legend.text = element_text(size = 7),
    legend.key.size = unit(0.5, "cm")
  ) +
  guides(
    color = guide_legend(nrow = 2, byrow = TRUE)
  )

ggsave("plot_financial_inclusion_by_poverty.png", plot = plot_financial_inclusion_by_poverty, path = "images")

# Creating choropleth for financial inclusion in the world
world_map <- st_read("data/ne_10m_admin_0_countries.shp")
inclusive_poverty_gdp_sf <- st_as_sf(inclusive_poverty_gdp_long,
  coords = c("longitude", "latitude"),
  crs = st_crs(world_map), remove = FALSE
)

choropleth_financial_inclusion <- ggplot() +
  geom_sf(data = world_map) +
  geom_sf(data = inclusive_poverty_gdp_sf, aes(fill = avg_value), shape = 21, size = 2) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(
    title = "Choropleth for Average Financial Inclusion in the World",
    fill = "Percent",
    x = "Longitude", y = "Latitude",
    caption = "Source: World Bank"
  ) +
  theme(
    strip.text = element_text(size = 10, face = "bold"),
    plot.title = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 10)
  ) +
  theme_minimal()

ggsave("choropleth_financial_inclusion.png", plot = choropleth_financial_inclusion, path = "images", width = 10, height = 10)

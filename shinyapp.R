library(tidyverse)
library(shiny)
library(plotly)

# Create bar graphs to select a country and year and visualize how financial inclusion 
# for the poor correlates with poverty
## Define ui
ui_1 <- fluidPage(
  titlePanel("Financial Inclusion for the Poor vs Poverty"),
  sidebarLayout(
    sidebarPanel(
      tags$img(src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
               height = 80,
               width = 220),
      selectInput(inputId = "country_input", label = "Country", choices = NULL),
      selectInput(inputId = "year_input", label = "Year", choices = NULL)
    ),
    mainPanel(
      plotlyOutput("country_plot")
    )
  )
)

## Define server logic
server_1 <- function(input, output, session) {
  inclusive_poverty_gdp <- read_csv("data/inclusive_poverty_gdp.csv")
  inclusive_poverty_gdp_long <- inclusive_poverty_gdp %>%
    pivot_longer(cols = starts_with("per_"), names_to = "metric", values_to = "value")
  
  observe({
    country_choices <- unique(inclusive_poverty_gdp_long$`country name`)
    updateSelectInput(session, "country_input", choices = country_choices)
  })
  
  ### Reactive filtered data based on user inputs
  filtered <- reactive({
    data <- inclusive_poverty_gdp_long
    
    # Filter by country
    if (!is.null(input$country_input) && input$country_input != "") {
      data <- data[data$`country name` == input$country_input, ]
    }
    
    # Filter by year
  if (!is.null(input$year_input) && input$year_input != "") {
    data <- data[data$year == as.numeric(input$year_input), ]
  }
    print(data)
    data
  })
  
  ### call the resulting dataframe filtered
  observeEvent(input$country_input, {
    filtered_data <- inclusive_poverty_gdp_long[inclusive_poverty_gdp_long$`country name` == input$country_input, ]
    year_choices <- unique(filtered_data$year)
    updateSelectInput(session, "year_input", choices = c("All Years" = "", year_choices))
  })
  
  ### Render the plot
  output$country_plot <- renderPlotly({
    plot_data <- filtered()
    
    if (nrow(plot_data) == 0) {
      return(NULL)
    }
    
    ggplotly(
      ggplot(data = plot_data) +
        geom_point(aes(poverty_headcount_ratio, value, fill = metric)) +
        labs(
          title = paste("Financial Inclusion for", input$country_input, "in", input$year_input),
          x = "Poverty Headcount Ratio",
          y = "Financial Inclusion for income, poorest 40% (% ages 15+)",
          caption = "Source: World Bank"
        ) +
        theme_minimal() +
        theme(
          axis.title.x = element_text(size = 10),
          axis.title.y = element_text(size = 10) 
        )
    )
  })
}

shinyApp(ui = ui_1, server = server_1)

# Create a world map to filter income group (low, middle, high-income level) 
# and compare financial inclusion across wealthier and poorer countries for the poor
## Define ui
ui_2 <- fluidPage(
  titlePanel("Financial Inclusion across Income Level in the World"),
  sidebarLayout(
    sidebarPanel(
      tags$img(src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
               height = 80,
               width = 220),
      selectInput(inputId = "income_input", label = "Income Level", choices = NULL),
      selectInput(inputId = "metric_input", label = "Metric", choices = NULL),
    ),
    mainPanel(
      plotlyOutput("income_plot")
    )
  )
)

## Define server logic
server_2 <- function(input, output, session) {
  world_map <- st_read("data/ne_10m_admin_0_countries.shp")
  inclusive_poverty_gdp_sf <- st_as_sf(inclusive_poverty_gdp_long, 
                                       coords = c("longitude", "latitude"), 
                                       crs = st_crs(world_map), remove = FALSE)
  
  observe({
    income_choices <- unique(inclusive_poverty_gdp_sf$`income group`)
    updateSelectInput(session, "income_input", choices = income_choices)
  })
  
  ### Reactive filtered data based on user inputs
  filtered <- reactive({
    data <- inclusive_poverty_gdp_sf
    
    # Filter by income level
    if (!is.null(input$income_input) && input$income_input != "") {
      data <- data[data$`income group` == input$income_input, ]
    }
    
    # Filter by year
    if (!is.null(input$metric_input) && input$metric_input != "") {
      data <- data[data$metric == input$metric_input, ]
    }
    print(data)
    data
  })
  
  ### call the resulting dataframe filtered
  observeEvent(input$income_input, {
    filtered_data <- inclusive_poverty_gdp_sf[inclusive_poverty_gdp_sf$`income group` == input$income_input, ]
    metric_choices <- unique(filtered_data$metric)
    updateSelectInput(session, "metric_input", choices = c("All Metrics" = "", metric_choices))
  })
  
  ### Render the plot
  output$country_plot <- renderPlotly({
    ggplot() +
      geom_sf(data = world_map) +
      geom_sf(
        data = if (input$income_input == "") {
          filtered() 
        } else {
          filtered() %>% filter(`income group` == input$income_input)  
        },
        aes(fill = value), shape = 21, size = 2
      ) +
      scale_fill_gradient(low = "white", high = "blue") +
      labs(
        title = "Financial Inclusion acoss Income Level in the World",
        x = "Longitude", y = "Latitude",
        fill = "Percent",
        caption = "Source: World Bank"
      ) +
      theme_minimal()
  })
}

## Run the app
shinyApp(ui = ui_2, server = server_2)
inclusive_poverty_gdp_sf
world_map

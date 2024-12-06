library(tidyverse)
library(shiny)
library(plotly)

# Create bar graphs to select a country and year and visualize how financial inclusion 
# for the poor correlates with poverty
## Define ui
ui <- fluidPage(
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
server <- function(input, output, session) {
  inclusive_poverty_gdp <- read_csv("data/inclusive_poverty_gdp_long.csv")

  observe({
    country_choices <- unique(inclusive_poverty_gdp_long$`country name`)
    updateSelectInput(session, "country_input", choices = country_choices)
  })
  
  ### Reactive filtered data based on user inputted country
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

shinyApp(ui = ui, server = server)

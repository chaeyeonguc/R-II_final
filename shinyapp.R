library(tidyverse)
library(sf)
library(shiny)
library(plotly)

# Create a world map to select a country and year and visualize how financial inclusion for the poor correlates
# with poverty in the world over time
## Define ui
ui <- fluidPage(
  titlePanel("Correlation Between Financial Inclusion for the Poor and Poverty in the World Over time"),
  sidebarLayout(
    sidebarPanel(
      tags$img(src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
               height = 90,
               width = 260),
      selectInput(inputId = "year_input", label = "Year", choices = NULL),
      selectInput(inputId = "country_input", label = "Country", choices = NULL)
    ),
    mainPanel(
      plotlyOutput("country_plot")
    )
  )
)

## Define server logic
server <- function(input, output, session) {
  inclusive_poverty_gdp <- read_csv("data/inclusive_poverty_gdp.csv")
  zip_codes <- st_read("geo_export_fb313970-5c89-4a00-8f7c-2f7e7ca8255d.shp")
  public_schools <- public_schools %>%
    select(`Safety Score`, `Name of School`, LONGITUDE, LATITUDE)
  public_schools_sf <- st_as_sf(public_schools, coords = c("LONGITUDE", "LATITUDE"), crs = st_crs(zip_codes), remove = FALSE)
  public_schools_sf <- filter(public_schools_sf, !is.na(`Safety Score`))
  
  
  ## Subset based on user-inputted safety score
  public_schools_sf_updated <- reactive({
    public_schools_sf %>% filter(`Safety Score` >= as.numeric(input$safety_input))
  })
  
  ## call the resulting dataframe public_schools_sf_updated
  observeEvent(public_schools_sf_updated(), {
    school_choices <- unique(public_schools_sf_updated()$`Name of School`)
    updateSelectInput(inputId = "school_input", choices = c("All Schools" = "", school_choices))
  })
  
  ## Render the plot
  output$school_plot <- renderPlotly({
    ggplot() +
      geom_sf(data = zip_codes) +
      geom_sf(
        data = if (input$school_input == "") {
          public_schools_sf_updated() 
        } else {
          public_schools_sf_updated() %>% filter(`Name of School` == input$school_input)  
        },
        aes(fill = `Safety Score`), shape = 21, size = 2
      ) +
      scale_fill_gradient(low = "white", high = "blue") +
      labs(
        title = "Location of Public School by Safety Scores and School Name in Chicago",
        x = "Longitude", y = "Latitude",
        fill = "Safety Score",
        caption = "Source: City of Chicago"
      ) +
      theme_minimal()
  })
}

# Run the app
shinyApp(ui = ui, server = server)


# Create a world map to filter income group (low, middle, high-income level) 
# and compare financial inclusion gaps across wealthier and poorer countries for the poor
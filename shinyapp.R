library(tidyverse)
library(pdftools)
library(tidytext)
library(udpipe)
library(igraph)
library(ggraph)
library(shiny)
library(plotly)
library(styler)
style_file("shinyapp.R")

# Create bar graphs to select a country and year and visualize how financial inclusion
# for the poor correlates with poverty
## Define ui
ui <- fluidPage(
  titlePanel("Financial Inclusion for the Poor vs Poverty"),
  sidebarLayout(
    sidebarPanel(
      tags$img(
        src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
        height = 80,
        width = 220
      ),
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
  inclusive_poverty_gdp_long <- read_csv("data/inclusive_poverty_gdp_long.csv")

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

# Text process: Create line graphs specific sentiment for the most common words used
## Load text from a PDF and turn into a dataframe
microfinance <- pdf_text("data/Microfinance_poverty_trap.pdf")

parsed <- udpipe(microfinance, "english")

## Define ui
ui_2 <- fluidPage(
  titlePanel("Keyword-specific Sentiment from Microfinance vs Poverty Research"),
  sidebarLayout(
    sidebarPanel(
      tags$img(
        src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
        height = 80,
        width = 220
      ),
      selectInput(inputId = "keyword_input", label = "Keywords", choices = NULL),
    ),
    mainPanel(
      plotlyOutput("dependency_plot")
    )
  )
)

## Define server
server_2 <- function(input, output, session) {
  
  ### Extract 10 keywords the most used
  keywords <- parsed %>%
    filter(!lemma %in% stop_words$word, !upos %in% c("PUNCT", "CCONJ")) %>%
    anti_join(stop_words, by = c("lemma" = "word")) %>%
    group_by(lemma) %>%
    count(sort = TRUE) %>%
    head(n = 10) %>%
    pull(lemma)
  
  # Populate keyword choices
  updateSelectInput(inputId = "keyword_input", choices = keywords)
  
  ### Reactive filtered data based on user inputted keyword
  filtered <- reactive({
    req(input$keyword_input)
    data <- parsed %>% filter(lemma == input$keyword_input)
    validate(
      need(nrow(data) > 0, "No data found for the selected keyword.")
    )
    data
  })
  
  ### Reactive keyword-specific sentiment
  sentiment <- reactive({
    req(filtered())
    
    filtered_data <- filtered() %>%
      mutate(
        doc_id = as.character(doc_id),                              
        page_number = as.numeric(gsub("[^0-9]", "", doc_id))       
      ) %>%
      arrange(page_number) %>%                                      
      distinct(doc_id, .keep_all = TRUE)                            
    
    sentiment_afinn <- get_sentiments("afinn") %>% rename(afinn = value)
    
    # Extract dependency of keyword and combine altogether
    children <- filtered_data %>%
      inner_join(
        parsed %>% select(doc_id, head_token_id, lemma),
        by = c("token_id" = "head_token_id", "doc_id" = "doc_id")
      ) %>%
      select(doc_id, page_number, lemma.y) %>% 
      rename(word = lemma.y)
    
    parents <- filtered_data %>%
      inner_join(
        parsed %>% select(doc_id, token_id, lemma),
        by = c("head_token_id" = "token_id", "doc_id" = "doc_id")
      ) %>%
      select(doc_id, page_number, lemma.y) %>% 
      rename(word = lemma.y)
    
    combined <- rbind(children, parents) %>%
      left_join(sentiment_afinn, by = "word") %>%
      group_by(doc_id, page_number) %>%
      summarise(afinn = mean(afinn, na.rm = TRUE)) %>%
      ungroup()
    
    combined
  })
  
  output$dependency_plot <- renderPlotly({
    req(sentiment())
    # Adjust page number by starting from 2 to be aligned with the paper's page number
    sentiment_data <- sentiment() %>%
      mutate(
        page_number = page_number - min(page_number[-1]) + 1
      )
    
    ggplotly(
      ggplot(sentiment_data, aes(x = page_number, y = afinn)) +
        geom_line(color = "steelblue", size = 1) +
        geom_point(aes(color = afinn), size = 3) +
        scale_x_continuous(
          breaks = seq(1, max(sentiment_data$page_number, na.rm = TRUE), by = 5),  # Every page number
          labels = seq(1, max(sentiment_data$page_number, na.rm = TRUE), by = 5)  # Match breaks
        ) +
        scale_color_gradient2(
          low = "red", mid = "white", high = "blue", midpoint = 0,
          name = "Sentiment Score"
        ) +
        labs(
          title = paste("Sentiment Trend of", input$keyword_input, "(AFINN)"),
          x = "Page Number",
          y = "Average Sentiment",
          caption = "Source: World Bank"
        ) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1) 
        )
    )
  })
}

## Run the app
shinyApp(ui = ui_2, server = server_2)

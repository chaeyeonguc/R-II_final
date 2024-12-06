library(tidyverse)
library(pdftools)
library(tidytext)
library(udpipe)
library(igraph)
library(ggraph)
library(shiny)
library(plotly)
library(styler)
style_file("textprocess.R")

# Load text from a PDF and turn into a dataframe
data_path <- "/Users/yeong/Documents/GitHub/R-II_final/data/"
microfinance <- pdf_text(paste0(data_path, "Microfinance_poverty_trap.pdf"))

parsed <- udpipe(microfinance, "english") %>%
  view()

# Create a shiny app showing keyword specific sentiment for the most common words used
## Define ui
ui_2 <- fluidPage(
  titlePanel("Keyword-specific Sentiment from Microfinance vs Poverty Research"),
  sidebarLayout(
    sidebarPanel(
      tags$img(src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
               height = 80,
               width = 220),
      selectInput(inputId = "keyword_input", label = "Keywords", choices = NULL),
    ),
    mainPanel(
      plotlyOutput("dependency_plot")
    )
  )
)

## Define server 
server_2 <- function(input, output, session) {
  
  ### Compute 10 keywords the most used 
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
    parsed %>% filter(lemma == input$keyword_input)
  })
  
  ### Reactive keyword-specific sentiment
  sentiment <- reactive({
    req(filtered())

    sentiment_afinn <- get_sentiments("afinn") %>% rename(afinn = value)   
    
    children <- filtered() %>%
      inner_join(
        parsed %>% 
          select(doc_id, head_token_id, lemma),
        by = c("token_id" = "head_token_id", "doc_id" = "doc_id")
      ) %>%
      select(doc_id, lemma.y) %>% rename(word = lemma.y)
    
    parents <- filtered() %>%
      inner_join(
        parsed %>% 
          select(doc_id, token_id, lemma),
        by = c("head_token_id" = "token_id", "doc_id" = "doc_id")
      ) %>%
      select(doc_id, lemma.y) %>% rename(word = lemma.y)

    combined <- rbind(children, parents) %>%
      left_join(sentiment_afinn, by = "word") %>% group_by(doc_id) %>%
      summarise(afinn = mean(afinn, na.rm = TRUE))
  })
  
  ### Render the Plot
  output$dependency_plot <- renderPlotly({
    req(sentiment())

    ggplotly(
      ggplot(sentiment(), aes(x = doc_id, y = afinn, group = 1)) + 
        geom_line(color = "steelblue", size = 1) + 
        geom_point(aes(color = afinn), size = 3) +
        scale_color_gradient2(
          low = "red", mid = "white", high = "blue", midpoint = 0,
          name = "Sentiment Score"
        ) +
        labs(
          title = paste("Sentiment Trend of", input$keyword_input, "(AFINN)"),
          x = "Document ID",
          y = "Average Sentiment"
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






  






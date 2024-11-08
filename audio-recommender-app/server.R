library(shiny)
library(spotifyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(cluster)
library(factoextra)
library(purrr)

# Define server logic required to draw a histogram
function(input, output, session) {

  # Add this inside the server function
  spotify_data <- reactive({
    req(input$submit)
    
    # Authenticate
    spotify_id <- Sys.getenv("SPOTIFY_CLIENT_ID")
    spotify_secret <- Sys.getenv("SPOTIFY_CLIENT_SECRET")
    access_token <- get_spotify_access_token()
    
    # Get genre artists
    genre_artists <- get_genre_artists(
      genre = input$genre,
      limit = 20,
      authorization = access_token
    )
    
    genre_artists
  })
  
  
  # Add these inside your server function
  output$status_message <- renderUI({
    if(input$submit == 0) {
      return(p("Enter a genre and click 'Get Artists' to start"))
    }
    p("Loading data...", class = "text-info")
  })
  
  output$artists_table <- DT::renderDataTable({
    data <- spotify_data()
    
    # Validate data
    validate(
      need(!is.null(data), "No data available for this genre")
    )
    
    # Convert data to display format
    DT::datatable(
      data,
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
  output$error_message <- renderText({
    if (inherits(try(spotify_data()), "try-error")) {
      "Error fetching data. Please check your genre input or try again later."
    }
  })

}

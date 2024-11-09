library(shiny)
library(spotifyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(cluster)
library(factoextra)
library(purrr)


# server.R
function(input, output, session) {
  ## Loading state
  loading <- reactiveVal(FALSE)
  
  ## Spotify data reactive
  spotify_data <- reactive({
    req(input$submit)
    loading(TRUE)
    
    result <- tryCatch({
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
    },
    error = function(e) {
      showNotification(
        paste("Error:", e$message),
        type = "error"
      )
      return(NULL)
    })
    
    loading(FALSE)
    return(result)
  })
  
  ## Processed tracks reactive
  processed_tracks <- reactive({
    req(spotify_data())
    
    withProgress(
      message = 'Analyzing tracks',
      value = 0,
      {
        # Get tracks for each artist
        tracks_data <- map_dfr(spotify_data()$id, function(artist_id) {
          incProgress(1/length(spotify_data()$id))
          artist_tracks <- get_artist_top_tracks(artist_id, "US")
          if(nrow(artist_tracks) > 0) {
            sample_n(artist_tracks, min(5, nrow(artist_tracks)))
          }
        })
        
        # Get audio features
        audio_features <- map_dfr(tracks_data$id, get_track_audio_features)
        
        # Join and process
        full_data <- tracks_data %>%
          left_join(audio_features, by = "id") %>%
          mutate(
            loudness_scaled = scale(loudness),
            tempo_scaled = scale(tempo),
            overall_mood = (danceability + energy + loudness_scaled + tempo_scaled)/4
          )
        
        full_data
      })
  })
  
  ## Output: Status Message
  output$status_message <- renderUI({
    if(loading()) {
      tags$div(
        class = "alert alert-info",
        tags$i(class = "fa fa-spinner fa-spin"),
        "Loading data..."
      )
    }
  })
  
  ## Output: Artist Table
  output$artists_table <- DT::renderDataTable({
    req(spotify_data())
    DT::datatable(
      spotify_data() %>%
        select(name, popularity, followers.total) %>%
        rename(
          Artist = name,
          Popularity = popularity,
          Followers = followers.total
        ),
      options = list(pageLength = 10)
    )
  })
  
  ## Output: Mood Plot
  output$mood_plot <- renderPlotly({
    req(processed_tracks())
    plot_ly(processed_tracks()) %>%
      add_trace(
        x = ~danceability,
        y = ~energy,
        color = ~overall_mood,
        text = ~name,
        type = "scatter",
        mode = "markers"
      ) %>%
      layout(
        title = "Track Mood Analysis",
        xaxis = list(title = "Danceability"),
        yaxis = list(title = "Energy")
      )
  })
  
  ## Output: Feature Distribution
  output$feature_distribution <- renderPlotly({
    req(processed_tracks())
    plot_ly(processed_tracks()) %>%
      add_histogram(x = as.formula(paste0("~", input$feature_view))) %>%
      layout(title = paste("Distribution of", input$feature_view))
  })
  
  
  
  
}
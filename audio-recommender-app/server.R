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
  
  ## Backend Data Transformation: Spotify data reactive
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
  
  ## Backend Data Transformation: Processed tracks reactive
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
  
  
  
  ## Statistical Analysis: Cluster Analysis
  clustered_tracks <- reactive({
    req(processed_tracks())
    
    # Prepare data for clustering
    cluster_data <- processed_tracks() %>%
      select(danceability, energy, valence, overall_mood) %>%
      scale()
    
    # Perform k-means clustering
    set.seed(123)
    kmeans_result <- kmeans(cluster_data, centers = 4)
    
    # Add cluster assignments
    processed_tracks() %>%
      mutate(
        cluster = kmeans_result$cluster,
        mood_type = case_when(
          cluster == 1 ~ "happy",
          cluster == 2 ~ "sad",
          cluster == 3 ~ "chill",
          cluster == 4 ~ "angry"
        )
      )
  })
  
  
  ## Backend Data Transformation: Filtered Tracks
  filtered_tracks <- reactive({
    req(clustered_tracks(), input$mood)
    
    clustered_tracks() %>%
      filter(mood_type == input$mood) %>%
      arrange(desc(overall_mood)) %>%
      head(10)
  })
  
  
  
  
  
  
  
  
  ##-----------------------------------------------------
  ## Outputs
  ##-----------------------------------------------------
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
  
  ## Output: Main scatter plot
  output$spotifyPlot <- renderPlotly({
    req(filtered_tracks())
    
    p <- ggplot(filtered_tracks(), 
                aes(x = valence, y = overall_mood, text = name)) +
      geom_point(aes(color = name)) +
      geom_vline(xintercept = 0.5) +
      geom_hline(yintercept = 0.5) +
      labs(x = "Valence", y = "Overall Mood", color = "Song Title") +
      theme_minimal() +
      scale_x_continuous(limits = c(0, 1)) +
      scale_y_continuous(limits = c(0, 1))
    
    ggplotly(p, tooltip = "text") %>%
      layout(
        showlegend = TRUE,
        legend = list(
          orientation = "h",
          xanchor = "center",
          x = 0.5,
          y = -0.2
        )
      )
  })
  
  ## Output: Cluster plot
  output$clusterPlot <- renderPlot({
    req(clustered_tracks())
    
    cluster_data <- clustered_tracks() %>%
      select(danceability, energy, valence, overall_mood)
    
    fviz_cluster(
      list(
        data = as.matrix(cluster_data),
        cluster = clustered_tracks()$cluster
      ),
      geom = "point",
      main = "Song Clusters by Audio Features"
    )
  })
  
  
  ## Output: Spotify Tracks Images
  output$spotifyTracks <- renderUI({
    req(filtered_tracks())
    
    spotifyURIs <- filtered_tracks()$uri
    
    trackEmbeds <- map(spotifyURIs, function(uri) {
      spotifyEmbedURL <- sprintf(
        "https://open.spotify.com/embed/track/%s",
        gsub("spotify:track:", "", uri)
      )
      tags$div(
        tags$iframe(
          src = spotifyEmbedURL,
          width = "300",
          height = "80",
          frameborder = "0",
          allowtransparency = "true",
          allow = "encrypted-media"
        ),
        style = "padding-bottom: 20px;"
      )
    })
    
    do.call(tagList, trackEmbeds)
  })
  
  ## Output: Selected Mood Text
  output$moodText <- renderText({
    paste("Selected Mood:", input$mood)
  })
  
  ## Output: Selected Genre Text
  output$genreText <- renderText({
    paste("Selected Genre:", input$genre)
  })
  
  
  
  
  ## Output: Analysis Stats
  observe({
    req(input$submit)
    if (is.null(filtered_tracks()) || nrow(filtered_tracks()) == 0) {
      showNotification("No tracks found for the selected criteria", type = "warning")
    }
  })
  
  
  ## Old :Not going to use
  
  
  
  
  
  
  
  
  
  
  
  
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
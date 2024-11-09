#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(plotly)
# ui.R
fluidPage(
  theme = bslib::bs_theme(version = 4),
  
  titlePanel("Spotify Genre Explorer & Track Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("genre", 
                "Enter Genre:",
                value = "rock",
                placeholder = "e.g., rock, jazz, hip-hop"),
      
      actionButton("submit", 
                   "Analyze Genre",
                   class = "btn-primary w-100 mb-3"),
      
      hr(),
      
      # Display analysis stats
      uiOutput("analysis_stats"),
      
      # Help text
      helpText("This app analyzes artists and tracks for a given genre,",
               "including audio features and mood analysis.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Artists",
                 uiOutput("status_message"),
                 DT::dataTableOutput("artists_table")
        ),
        tabPanel("Top Tracks",
                 plotlyOutput("mood_plot"),
                 DT::dataTableOutput("tracks_table")
        ),
        tabPanel("Audio Features",
                 plotlyOutput("audio_features_plot"),
                 selectInput("feature_view", 
                             "Select Feature to View:",
                             choices = c("danceability", "energy", "tempo", "valence", "loudness")),
                 plotlyOutput("feature_distribution")
        )
      )
    )
  )
)
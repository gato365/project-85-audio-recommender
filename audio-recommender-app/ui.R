library(shiny)
library(plotly)
library(DT)
library(bslib)

fluidPage(
  theme = bs_theme(version = 4),
  
  titlePanel("Spotify Genre Explorer & Mood Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("genre", 
                "Enter Genre:",
                value = "rock",
                placeholder = "e.g., rock, jazz, hip-hop"),
      
      # Add mood selection
      selectInput("mood",
                  "Select Mood:",
                  choices = c("happy", "sad", "chill", "angry"),
                  selected = "happy"),
      
      actionButton("submit", 
                   "Analyze Genre",
                   class = "btn-primary w-100 mb-3"),
      
      hr(),
      
      # Display mood and genre text
      textOutput("moodText"),
      textOutput("genreText"),
      
      hr(),
      
      # Add cluster analysis button
      actionButton("showCluster",
                   "Show Cluster Analysis",
                   class = "btn-info w-100 mb-3"),
      
      # Help text
      helpText("This app analyzes artists and tracks for a given genre,",
               "clustering them by mood based on audio features.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Mood Analysis",
                 br(),
                 # Main plot showing mood vs valence
                 plotlyOutput("spotifyPlot", height = "400px"),
                 br(),
                 # Spotify track embeddings
                 uiOutput("spotifyTracks")
        ),
        
        tabPanel("Cluster Analysis",
                 br(),
                 # Cluster visualization
                 plotOutput("clusterPlot", height = "500px"),
                 br(),
                 # Data table for cluster information
                 DT::dataTableOutput("clusterTable")
        ),
        
        tabPanel("Audio Features",
                 br(),
                 # Keep your existing audio features content
                 selectInput("feature_view", 
                             "Select Feature to View:",
                             choices = c("danceability", "energy", 
                                         "tempo", "valence", "loudness")),
                 plotlyOutput("feature_distribution"),
                 br(),
                 DT::dataTableOutput("featuresTable")
        ),
        
        tabPanel("Track Details",
                 br(),
                 # Detailed track information
                 DT::dataTableOutput("tracksTable"))
      )
    )
  )
)
#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# ui.R
fluidPage(
  titlePanel("Audio Recommender"),
  
  sidebarLayout(
    sidebarPanel(
      # Genre input
      textInput("genre", 
                "Enter Genre:", 
                value = "rock"),
      
      # Submit button
      actionButton("submit", 
                   "Get Artists",
                   class = "btn-primary",
                   width = "100%"),
      
      # Helper text
      helpText("Enter a music genre to discover artists.")
    ),
    
    mainPanel(
      # Status message
      uiOutput("status_message"),
      
      # Results panel
      wellPanel(
        h3("Artists in Selected Genre"),
        # Table output for artists
        DT::dataTableOutput("artists_table"),
        
        # Error message space
        textOutput("error_message")
      )
    )
  )
)
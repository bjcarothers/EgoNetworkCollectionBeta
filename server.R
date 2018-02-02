#****************************#
# Ego Network Colletion Test #
#           BETA             #
#     Bobbi Carothers        #
#         2/2/2018           #
#****************************#

library(shiny)
library(igraph)
library(visNetwork)
library(rdrop2) # access to Dropbox
library(rhandsontable) # users can enter data into a table

# NOTE: This app is NOT ready for prime-time. So far it's merely proof-of-concept that
# we can 1) collect ego network data with a reasonable user interface and 
# 2) upload it to a server for storage and retrieval. It's full of bugs and hasn't
# been fully tested. That said, if this comes across your desk and you have suggestions,
# please send them to bcarothers@wustl.edu 

# Setup ####

# Initialize ego network including only the ego node and no edges
EgoNode <- data.frame(id=1,
                      label="Me",
                      Gender="Undef",
                      color="#e41a1c")
EgoEdge <- data.frame(from=NA,
                      to=NA)

# Initialize data entry table
# Making gender a factor enables it as a drop-down for data entry later
AlterDF <- data.frame(id=2:6,
                      Name=NA,
                      Gender=factor(NA))
AlterDF$Name <- as.character(AlterDF$Name)
levels(AlterDF$Gender) <- c("Male","Female")

# Save function
outputDir <- "EgoNetworkTest"
saveData <- function(x) {
  NewVisNet <- x
  # Create a unique file name
  fileName <- sprintf("%s_%s.Rdata", as.integer(Sys.time()), digest::digest(NewVisNet))
  # Write the data to a temporary file locally. Think about adding code that deletes 
  # the local file once it's uploaded so we don't leave potentially sensitive data 
  # lying around
  filePath <- file.path(tempdir(), fileName)
  save(NewVisNet, file=filePath)
  # Upload the file to Dropbox
  drop_upload(filePath, path = outputDir)
}

 
# Start server ####
shinyServer(function(input, output, session){
  
  # Hide navbar tabs - this doesn't work yet. There are ways to do it
  # dynamically, but haven't found a way to set it as default
  #hideTab(inputId="TabVal", target="Ego Network Test")
 
  # Page 1: Alters ####
  
  # Blank data table where user enters names and characteristics
  # NOTE: gender dropdown on row 3 doesn't work properly on some displays. 
  # I think it can't decide whether to go up or down because it's in the middle
  output$AlterTable <- renderRHandsontable({
    rhandsontable(AlterDF) %>% 
      hot_context_menu(allowRowEdit=FALSE, allowColEdit=FALSE) %>%
      hot_col("id", width=1) %>% # Don't display id colum - confusing for users
      hot_col(c("Name","Gender"), width=100)
  })
  
  # Initial ego network with no ties
  output$EgoNet1 <- renderVisNetwork({
    visNetwork(EgoNode,EgoEdge)
  })
  
  # Record the data from the table
  value <- reactiveVal()
  observeEvent(input$SaveAlters,{
    df <- as.data.frame(hot_to_r(input$AlterTable))
    value(df)
  })
  
  # Set table data up as a nodes object 
  Enodes <- reactive({
    req(input$SaveAlters) # Put this and everything else on hold until submitted
    df <- value()
    df$color <- NA # Set up color for gender
    df$color[df$Gender=="Male"] <- "#377eb8"
    df$color[df$Gender=="Female"] <- "#984ea3"
    names(df)[2] <- "label" # Change "Name" to "label" for VisNetwork purposes
    df <- subset(df, !is.na(label)) # Select only rows where a name was entered
    df <- rbind(EgoNode,df) # Tack ego on at the top
    df
  })
  
  # Set up edgelist
  Eedges <- reactive({
    req(input$SaveAlters)
    df1 <- Enodes()
    df2 <- data.frame(from=1, # Plug in "me" id for all of the "from" cells
                      to=df1$id) # Copy ids from nodes to "to" in edges
    df2 <- subset(df2, to > 1) # remove the loop (to = 1)
    df2
  })
  
  # Working on a warning message - can't get the logic right
  #output$Warn1 <- renderText({"Oh, come on, write some people in."})
  # Need to insert code to delete nodes when names are removed
  
  # Draw ego network with alters
  output$EgoNet2 <- renderVisNetwork({
    visNetwork(Enodes(),Eedges()) %>%
      visIgraphLayout(physics=TRUE, type="full", layout="layout_as_star") 
  })
  
  # Go to next page
  observeEvent(input$SaveNet,{
    updateNavbarPage(session=session, inputId="TabVal", selected="2")
  })
  
  # Page 2: Connections between alters ####
  
  # Re-draw ego network with alters, include manipulation
  
  output$EgoNet3 <- renderVisNetwork({
    req(input$SaveNet)
    visNetwork(Enodes(),Eedges()) %>%
      visOptions(manipulation=TRUE) %>%
      visIgraphLayout(physics=TRUE, type="full", layout="layout_as_star")
  })

  
  # Pull data from edited network
  # Get nodes and edges
  observeEvent(input$SaveCon,{
    visNetworkProxy("EgoNet3") %>%
      visGetNodes() %>%
      visGetEdges()
  })
  # Get commands create lists. Need to format to new visNetwork dataframes
  # Nodes frame
  NewNodes <- reactive({
    req(input$SaveCon)
    lst <- input$EgoNet3_nodes
    # Convert to dataframe
    df <- data.frame(matrix(unlist(lst), nrow=length(lst), byrow=TRUE),
                     stringsAsFactors=FALSE)
    colnames(df) <- names(lst[[1]])
    # Remove xy coords
    df$x <- df$y <- NULL
    df
  })
  # Edges frame
  NewEdges <- reactive({
    req(input$SaveCon)
    lst <- input$EgoNet3_edges
    # Convert to data frame
    df <- data.frame(matrix(unlist(lst), nrow=length(lst), byrow=TRUE,
                            dimnames=list(NULL,names(lst[[1]]))), 
                     stringsAsFactors=FALSE)
    # Select needed vars
    df <- subset(df, select=c(from,to))
    df
  })
  
  # Page navigation
  # Go back
  observeEvent(input$Back1,{ 
    updateNavbarPage(session=session, inputId="TabVal", selected="1")
  })
  # Save & continue
  observeEvent(input$SaveCon,{
    updateNavbarPage(session=session, inputId="TabVal", selected="3")
  })
  
  # Page 3: Save to dropbox ####
  # Create a VisNet object: list of 2 dataframes
  DatOut <- reactive({
    lst <- list()
    lst$Nodes <- NewNodes()
    lst$Edges <- NewEdges()
    lst
  })
  
  # Page navigation: Go back
  observeEvent(input$Back2,{ 
    updateNavbarPage(session=session, inputId="TabVal", selected="2")
  })
  # When Save button is clicked, save the data and stop the app
  observeEvent(input$SaveEnd,{
    saveData(DatOut())
    stopApp()
  })
  
  
}
)
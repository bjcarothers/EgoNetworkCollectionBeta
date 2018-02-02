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

shinyUI(
  navbarPage(
    title="Ego Network Test",
    theme="bootstrap.css",
    id="TabVal",
    tabPanel("Nodes",
             value=1,
             wellPanel("Name some people who are important to you:"),
             fluidRow(
               column(width=6,
                      rHandsontableOutput("AlterTable"),
                      tags$h1(""),
                      actionButton("SaveAlters", "Update your network")
                      ),
               column(width=6,
                      conditionalPanel(condition="!input.SaveAlters",
                                       visNetworkOutput("EgoNet1")
                                       ),
                      conditionalPanel(condition="input.SaveAlters",
                                       #textOutput("Warn1"),
                                       visNetworkOutput("EgoNet2")
                                       )
                      )
               ),
             conditionalPanel(condition="input.SaveAlters",
                              wellPanel('Click "Next" when you are ready to move on'),
                              actionButton("SaveNet", "Next")
                              )
             ),
    tabPanel("Links",
             value=2,
             wellPanel("Add some connections between the people who are important to you"),
             visNetworkOutput("EgoNet3"),
             actionButton("Back1", "Back"),
             actionButton("SaveCon", "Next")
             ),
    tabPanel("End",
             value=3,
             "All done - thanks!",
             hr(),
             actionButton("Back2", "Back"),
             actionButton("SaveEnd", "Save to dropbox and end")
             )
  )
)
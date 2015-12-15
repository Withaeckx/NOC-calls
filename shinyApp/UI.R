

shinyUI(navbarPage("Downdetector",
                   
                   tabPanel("Full View"
                            
                            ,
                            headerPanel("Calls to Proximus"),
                      
                      fluidRow(
                        
                            sidebarPanel(
                              
                              # Proximus Logo
                              img(src='proximus_icon.png',
                                  width = 175, 
                                  style="display: block; margin-left: auto; margin-right: auto;"),
                            
                              # Input
                              dateRangeInput("dateRange_1", 
                                             label =  "Date Range:",
                                             min = min(input_table$MED_SEG_START_TS),
                                             max = max(input_table$MED_SEG_START_TS),
                                             start = min(input_table$MED_SEG_START_TS),
                                             end = max(input_table$MED_SEG_START_TS)),
                              sliderInput("aggregate_amount", 
                                          label = "Aggregate data for every:",
                                          min = 1,
                                          max = 30,
                                          value = 5),
                              selectInput("aggregate_unit", 
                                          label = "Time unit:",
                                          choices = c("minutes", "hours", "days"),
                                          selected = "minutes"),
                              div(strong("From: "), textOutput("from", inline = TRUE)),
                              div(strong("To: "), textOutput("to", inline = TRUE))
                            ),
                            
                            mainPanel(
                              dygraphOutput("dygraph_1", width = "100%", height = 500)
                            )
                            
                      )
                      
                      
                      , 
                            
                      fluidRow(
                            column(width = 12,
                                   titlePanel("All Calls"),
                                   dataTableOutput(outputId = "table_1")
                            )
                            
                            )
                        
                   )

                   
                   ,
                   
                   tabPanel("FOT Calls",
                            
                            fluidPage(
                              fluidRow(
                                
                                titlePanel("Calls to FOT")
                                , sidebarPanel(
                                  
                                  # Proximus Logo
                                  img(src='proximus_icon.png',
                                      width = 175, 
                                      style="display: block; margin-left: auto; margin-right: auto;"),
                                  
                                  sliderInput("history_amount", 
                                              label = "Show me data last:",
                                              min = 1,
                                              max = 30,
                                              value = 1),
                                  selectInput("history_unit", 
                                              label = "Time unit:",
                                              choices = c("minutes", "hours", "days"),
                                              selected = "hours")
                                  
                                )
                                
                                ,
                                
                                mainPanel(
                                  leafletOutput("mymap", width = "100%", height = 400),
                                  
                                  absolutePanel(
                                    id = "controls", class = "panel panel-default", 
                                    fixed = FALSE, draggable = TRUE, top = 12, left = "auto", right = 20, 
                                    bottom = "auto", width = 150, height = "auto",
                                    
                                    h2("  Call Map"),
                                    checkboxInput("group_cities", "Group Calls", FALSE)
                                    # , checkboxInput("by_callreason", "Show Call Reason", FALSE)
                                    )
                                  
                                )
                                
                              ))
                            
                            ,
                            
                            fluidRow(
                              
                              column(width = 6, 
                                     titlePanel("Calls Per City"),
                                     dataTableOutput(outputId = "table_2_city")
                              ),
                              
                              column(width = 6, 
                                     titlePanel("Calls Per Street"),
                                     dataTableOutput(outputId = "table_2_street")
                              )
                              
                              
                            ),
                            
                            fluidRow(
                              
                              column(width = 12,
                                     titlePanel("All Calls"),
                                     dataTableOutput(outputId = "table_2_all")
                              )
                            )
                            
                            
                            
                   )
                   
                   ,
                   
                   tabPanel("FOS Calls"
                            
                   )
                   
                   
))

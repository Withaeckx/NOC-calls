

shinyUI(navbarPage("Downdetector",
                   
                   tabPanel("Full View"
                            
                            ,
                            headerPanel("Calls to Proximus"),
                      
                      fluidRow(
                        
                            sidebarPanel(
                              
                              # Proximus Logo
                              img(src='proximus_icon.png',
                                  width = 220, 
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
                                          selected = "minutes")
                             # , renderPlot("pie")
                            ),
                            
                            mainPanel(
                              dygraphOutput("dygraph_all", width = "100%", height = 500)
                            )
                            
                      )
                      
                      
                      , 
                            
                      fluidRow(
                            column(width = 12,
                                   titlePanel("All Calls"),
                                   dataTableOutput(outputId = "table_all_incoming")
                            )
                            
                            )
                        
                   )

                   
                   ,
                   
                   tabPanel("FOT Calls",
                            
                            fluidPage(
                              fluidRow(
                                
                                titlePanel("Calls to FOT")
                                , sidebarPanel(
                                  
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
                                    bottom = "auto", width = "auto", height = "auto",
                                    
                                    h2("Call Map"),
                                    checkboxInput("group_cities", "Group Calls", FALSE),
                                    checkboxInput("by_callreason", "Show Call Reason", FALSE))
                                  
                                )
                                
                              ))
                            
                            ,
                            
                            fluidRow(
                              
                              column(width = 6, 
                                     titlePanel("Calls Per City"),
                                     dataTableOutput(outputId = "table1")
                              ),
                              
                              column(width = 6, 
                                     titlePanel("Calls Per Street_CD"),
                                     dataTableOutput(outputId = "table2")
                              )
                              
                              
                            ),
                            
                            fluidRow(
                              
                              column(width = 12,
                                     titlePanel("All Calls"),
                                     dataTableOutput(outputId = "table3")
                              )
                            )
                            
                            
                            
                   )
                   
                   ,
                   
                   tabPanel("FOS Calls"
                            
                   )
                   
                   
))

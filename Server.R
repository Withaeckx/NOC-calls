

shinyServer(function(input, output) {
  
  # Timeframe FOT_calls
  
  data_timeframe <- reactive({
    
    time_factor <- if(input$history_unit != "minutes") {
      ifelse(input$history_unit == "hours", 3600, 3600*24)
    } else {
      60}
    
    first_time <- max(input_table$MED_SEG_START_TS) - input$history_amount * time_factor
    data_timeframe <- subset(input_table, MED_SEG_START_TS > first_time)
    
    return(data_timeframe)
    
  })
  
  geo_calls <- reactive({
    
    #Only take valid geo codes
    geo_calls <- data_timeframe()
    geo_calls <- geo_calls[!is.na(geo_calls$lng),]
    
    #Group by zip-code
    byCity <- group_by(geo_calls, CITY_ZIP)
    geo_calls <- summarise(byCity, count = n())
    geo_calls <- geo_calls[order(-geo_calls$count),]
    
    # Quick fix
    geo_calls <- left_join(geo_calls, zips, by = "CITY_ZIP")
    geo_calls <- geo_calls[!is.na(geo_calls$lng),]
    
    return(geo_calls)
    
  })
  
  
  STREET_calls <- reactive({
    
    STREET_calls <- grouper_function(DF = data_timeframe(), group = "STREET_CD")
    return(STREET_calls)
    
  })
  
  #   FIRST_SELECTION_calls <- reactive({
  #     
  #     FIRST_SELECTION_calls <- grouper_function(data_timeframe(), "FIRST_SELECTION")
  #     return(FIRST_SELECTION_calls)
  #     
  #   })
  #   
  #   LAST_SELECTION_calls <- reactive({
  #     
  #     LAST_SELECTION_calls <- grouper_function(data_timeframe(), "LAST_SELECTION")
  #     return(LAST_SELECTION_calls)
  #     
  #   })
  
  
  
  ##################################  Dygraphs   ################################## 
  
  ### First pane
  
  
  output$dygraph_all <- renderDygraph({
    
    # Get only data defined in input
    
    dygraph_data <- subset(input_table, 
                           MED_SEG_START_TS >= as.POSIXct(input$dateRange_1[[1]]) & 
                             MED_SEG_START_TS <= as.POSIXct(input$dateRange_1[[2]]))
    
    # get_timeseries creates FOT & FOS timeseries of call-data
    
    timeseries <- get_timeseries(dygraph_data, input$aggregate_unit, input$aggregate_amount)
    timeseries_all <- cbind(timeseries$FOT_ts, timeseries$FOS_ts)
    
    ts_dygraph <- dygraph(timeseries_all) %>%
      dyRangeSelector(strokeColor = proximus_colors[1], fillColor = proximus_colors[2]) %>%
      dySeries("..1", label = "FOT") %>%
      dySeries("..2", label = "FOS")
    
    dyOptions(ts_dygraph, 
              connectSeparatedPoints = T,
              colors = c(proximus_colors[1], proximus_colors[2]))
    
    
  })    
  
  ### Second pane
  
  
  #   output$dygraph_FOT <- renderDygraph({
  #     
  #     # get_timeseries creates FOT timeseries of call-data
  #     
  #     timeseries <- get_timeseries(data_timeframe, "minutes", 5)
  #     
  #     ts_dygraph <- dygraph(timeseries$FOT_ts) %>%
  #       dySeries("V1", label = "FOT")
  #     dyOptions(ts_dygraph, connectSeparatedPoints = T)
  #     
  #   }) 
  
  
  ##################################  Mapping   ################################## 
  
  output$mymap <- renderLeaflet({
    
    # Make map
    
    if (input$group_cities == TRUE) {
      
      leaflet(data = geo_calls()) %>% 
        addTiles() %>%
        addCircleMarkers(~lng, ~lat, popup = ~paste(city, count),
                         clusterOptions = markerClusterOptions()) } else 
                           
                         {leaflet(data = geo_calls()) %>% 
                             addTiles() %>%
                             addCircleMarkers(~lng, ~lat, popup = ~paste(city, count)) }
    
    # Adapting view (in case of little input)
    # %>% setView(lng = -93.85, lat = 37.45, zoom = 4) 
    
  })
  
  ##################################  Reactive Tables   ################################## 
  
  output$table1 <- renderDataTable(geo_calls(), 
                                   options = list(pageLength = 5))
  
  output$table2 <- renderDataTable(STREET_calls(), 
                                   options = list(pageLength = 5))
  
  output$table3 <- renderDataTable(data_timeframe(), 
                                   options = list(pageLength = 5))
  
  ##################################  Reactive Charts   ################################## 
  
  
  #   output$pie <- renderPlot({
  #     
  #     # Take top 10 Call reasons
  #     pie_data <- subset(all_calls, ADIV == "COP" | ADIV == "CCA", select = c(ADIV, count))
  #     
  #     test_data <- grouper_function(pie_data, "ADIV")
  # 
  #     bp <- ggplot(test_data, aes(x="", y=count, fill=ADIV))+
  #       geom_bar(width = 1, stat = "identity") + 
  #       coord_polar(theta = "y", start = 0) + 
  #       scale_fill_manual(values= proximus_colors[1:2]) + 
  #       blank_theme  +
  #       geom_text(aes(y = count/3 + c(0, cumsum(count)[-length(count)]), 
  #                     label = percent(count/100)), size=10) 
  #     
  #     bp
  #     
  #   })
  
})
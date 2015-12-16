

shinyServer(function(input, output) {

  
  ### PANE 1 ### 
  
  # Timeframe FOT_calls
  
  data_TF_1 <- reactive({
    
    # Take all data in dygraph time-frame
    start_time <- input$dygraph_1_date_window[[1]]
    end_time <-input$dygraph_1_date_window[[2]]
    
    data_TF_1 <- input_table[which(input_table$MED_SEG_START_TS >= start_time & 
                                     input_table$MED_SEG_START_TS <= end_time),]

    data_TF_1 <- data_TF_1[order(data_TF_1$MED_SEG_START_TS, 
                                                   decreasing = T),]
    
    return(data_TF_1)
    
  })
  
  
  ### PANE 2 ### 
  
  data_TF_2 <- reactive({
    
    time_factor <- if(input$history_unit != "minutes") {
      ifelse(input$history_unit == "hours", 3600, 3600*24)
    } else {
      60}
    
    first_time <- max(input_table$MED_SEG_START_TS) - input$history_amount * time_factor
    
    call_data <- input_table[which(input_table$MED_SEG_START_TS > first_time 
                                   # Only take FOT calls
                                   & input_table$ADIV == "COP"),]
    
    # Joining with customer info
    
    # Temporarily we only took customers that have data that we need (Street, city, ...)
    # customer_available <- customer[!is.na(customer$CITY_ZIP),]
    
    # This line runs way too long
    #vdata_TF_2 <- left_join(call_data, customer_available, by = "CUST_ID")
    
    # Fixed with data.table
    dt1 <- data.table(call_data, key = "CUST_ID")
    dt2 <- data.table(customer_available, key = "CUST_ID")
    data_TF_2 <- as.data.frame(dt2[dt1, ])
    
    return(data_TF_2)
    
    })
  
  geo_calls <- reactive({
    
    # Only take locations we were able to find
    geo_calls <- data_TF_2()
    geo_calls <- geo_calls[!is.na(geo_calls$lng),]
    
    # Group by zip-code, lat and lon
    grp_cols <- c("CITY_NAME", "CITY_ZIP", "lng", "lat")
    
    # Convert character vector to list of symbols
    dots <- lapply(grp_cols, as.symbol)
    
    # Perform frequency counts
    geo_calls <- geo_calls %>%
      group_by_(.dots=dots) %>%
      summarise(count = n())
    
    geo_calls <- geo_calls[order(-geo_calls$count),]
    
    return(geo_calls)
    
  })
  
  
  STREET_calls <- reactive({
    
    # only take Street_cd's we were able to find
    STREET_calls <- data_TF_2()
    STREET_calls <- STREET_calls[!is.na(STREET_calls$STREET_CD),]
    
    # Group per street_cd
    STREET_calls <- grouper_function(DF = STREET_calls, group = "STREET_CD")
    merged <- left_join(STREET_calls, STREET_CD_count, by = "STREET_CD")
    merged$percentage <- merged$count.x / merged$count.y
    
    # Remove 1's in DB - probably because only 1 person having STREET_CD
    merged <- subset(merged, select = c(STREET_CD, percentage, count.x), 
                     subset = percentage != 1)
    merged <- merged[order(merged$percentage, decreasing = TRUE),]
    
    
    return(merged)
    
  })
  
  
  
  ##################################  Dygraphs   ################################## 
  
  
  output$dygraph_1 <- renderDygraph({
    
    # Get only data defined in input
    
    dygraph_data <- subset(input_table, 
                           MED_SEG_START_TS >= as.POSIXct(input$dateRange_1[[1]]) & 
                             MED_SEG_START_TS <= as.POSIXct(input$dateRange_1[[2]]))
    
    # get_timeseries creates FOT & FOS timeseries of call-data
    
    timeseries <- get_timeseries(dygraph_data, input$aggregate_unit, input$aggregate_amount)
    timeseries_all <- cbind(timeseries$FOT_ts, timeseries$FOS_ts)
    
    # Make Dygraph
    
    ts_dygraph <- dygraph(timeseries_all) %>%
      dyRangeSelector() %>%
      dySeries("..1", label = "FOT") %>%
      dySeries("..2", label = "FOS")
    
    dyOptions(ts_dygraph, 
              connectSeparatedPoints = T,
              colors = c(proximus_colors[1], proximus_colors[2]))
    
  })    
  
  output$from <- renderText({
    if (!is.null(input$dygraph_1_date_window))
      strftime(input$dygraph_1_date_window[[1]], "%D")      
  })
  
  output$to <- renderText({
    if (!is.null(input$dygraph_1_date_window))
      strftime(input$dygraph_1_date_window[[2]], "%D")
  })
  
  
  
  ##################################  Mapping   ################################## 
  
  output$mymap <- renderLeaflet({
    
    # Make map
    
    if (input$group_cities == TRUE) {
      
      leaflet(data = geo_calls()) %>% 
        addTiles() %>%
        addCircleMarkers(~lng, ~lat, popup = ~paste(CITY_NAME, " - ", count),
                         clusterOptions = markerClusterOptions()) } else 
                           
                         {leaflet(data = geo_calls()) %>% 
                             addTiles() %>%
                             addCircleMarkers(~lng, ~lat, popup = ~paste(CITY_NAME, " - ", count)) }

    
  })
  
  ##################################  Reactive Tables   ################################## 

  # Pane 1
  
  output$table_1 <- renderDataTable(subset(data_TF_1(), select = -count), 
                                   options = list(pageLength = 10))
  
  # Pane 2
  
  output$table_2_city <- renderDataTable(geo_calls(), 
                                   options = list(pageLength = 5))
  
  output$table_2_street <- renderDataTable(STREET_calls(), 
                                   options = list(pageLength = 5))
  
  output$table_2_all <- renderDataTable(subset(data_TF_2(), select = -c(ADIV, count, lng, lat)), 
                                   options = list(pageLength = 5))
  
  
  ##################################  Reactive Charts   ################################## 
  
  
    output$pie <- renderPlot({
      
#       # Take top 10 Call reasons
#       
#       pie_data <- data_TF_1()
#       pie_data <- subset(pie_data,
#                          , ADIV == "COP" | ADIV == "CCA", select = c(ADIV, count))
#       
#       test_data <- grouper_function(pie_data, "ADIV")
#   
#       bp <- ggplot(test_data, aes(x="", y=count, fill=ADIV))+
#         geom_bar(width = 1, stat = "identity") + 
#         coord_polar(theta = "y", start = 0) + 
#         scale_fill_manual(values= proximus_colors[1:2]) + 
#         blank_theme  +
#         geom_text(aes(y = count/3 + c(0, cumsum(count)[-length(count)]), 
#                       label = percent(count/100)), size=10) 
#       
#       bp
      
    })
  
})
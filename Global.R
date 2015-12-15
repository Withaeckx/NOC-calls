
############################### Loading Packages ############################### 


if (!require("dplyr")) install.packages("dplyr") ; library(dplyr)
if (!require("leaflet")) install.packages("leaflet") ; library(leaflet)
if (!require("lubridate")) install.packages("lubridate") ; library(lubridate)
if (!require("xts")) install.packages("xts") ; library(xts)
if (!require("dygraphs")) install.packages("dygraphs") ; library(dygraphs)
if (!require("shiny")) install.packages("shiny") ; library(shiny)
if (!require("scales")) install.packages("scales") ; library(scales)
if (!require("ggplot2")) install.packages("ggplot2") ; library(ggplot2)
if (!require("RColorBrewer")) install.packages("RColorBrewer") ; library(RColorBrewer)
if (!require("data.table")) install.packages("data.table") ; library(data.table)



############################### Loading tables ############################### 


### Get Call Table

    all_calls <- read.table("c:/Users/Andreas/Documents/Proximus Calls/Input_files/Calls_october.txt", 
                            header = T, sep = "\t", as.is = T, fill = T)
    
    all_calls$MED_SEG_START_TS <- as.POSIXct(all_calls$MED_SEG_START_TS, 
                                             format="%d/%m/%Y %H:%M:%S")
    
    # Get data every 60 seconds
    # Necessary to plot FOS vs FOT in one point in time
    all_calls$MED_SEG_START_TS <- align.time(all_calls$MED_SEG_START_TS, 60)
    
    # Make counter
    all_calls$count <- 1

### Get Xplay table

    xplay <- read.table("c:/Users/Andreas/Documents/Proximus Calls/Input_files/xplay.txt", 
                        header = T, sep = "\t")

### Get Address Table (only residential customers?)

    address <- read.table("c:/Users/Andreas/Documents/Proximus Calls/Input_files/Address.txt", 
                        header = T, sep = "\t", as.is = T)

### Get location ZIP-codes - Vanessa file
    
    zips <- read.csv("C:\\Users\\Andreas\\Documents\\Proximus Calls\\Input_files\\postal_codes_centroids.csv", header = T)
    names(zips) <- c("CITY_ZIP", "city_NL", "city_FR", "lng", "lat")
    zips$CITY_ZIP <- as.character(zips$CITY_ZIP)
    
    ############################### Composing tables ############################### 
    
    
### Merge address related-stuff
    
    # Xplay & address
    xplay_address <- left_join(xplay, address, by = "CUST_ID")

    # & zips (latitude & longitude)
    customer <- left_join(xplay_address, zips, by = "CITY_ZIP")
    
    # How many addresses have been found?
    # table(is.na(customer$lat))
    # only found 1/3 of all customers...
    
    # Only select relevant columns
    
    customer <- subset(customer, select = 
                         c(CUST_ID, XPlay_Main, STREET_CD, CITY_ZIP, CITY_NAME, lng, lat))
    
    # Subset speed benchmark
#     system.time(customer_available <- customer[!is.na(customer$CITY_ZIP),])
#     system.time(customer_available <- subset(customer, subset = !is.na(customer$CITY_ZIP)))
#     system.time(customer_available <- customer[which(!is.na(customer$CITY_ZIP)),])
    # Which = twice as fast as subset!!!
    
    customer_available <- customer[which(!is.na(customer$CITY_ZIP)),]
    
### Computing statistics
    
    # Number of customers per STREET_CD
    byCITY_ZIP <- group_by(customer_available, CITY_ZIP)
    CITY_ZIP_count <- summarise(byCITY_ZIP, count = n())
    
    # Number of customers per CITY_ZIP
    bySTREET_CD <- group_by(customer_available, STREET_CD)
    STREET_CD_count <- summarise(bySTREET_CD, count = n())
    
    
### Compute full table if necessary
# full_table <- left_join(all_calls, customer, by = "CUST_ID")
    
    
    
    
    
############################### Global functions ############################### 
    
    
### Timeseries making 
# Create function to make timeseries
# unit = "hours", "minutes", "days"
    
    get_timeseries <- function(calls, unit, amount) {
      
      # Split between FOT and FOS
      FOT_calls <- calls[calls$ADIV == 'COP',]
      FOS_calls <- calls[calls$ADIV == 'CCA',]
      
      # Make Time Objects
      time_FOS <- xts(FOT_calls$count, FOT_calls$MED_SEG_START_TS)
      time_FOT <- xts(FOS_calls$count, FOS_calls$MED_SEG_START_TS)
      
      # Aggregate
      FOS_ts <- period.apply(x = time_FOS, endpoints(x = time_FOS, unit, amount), sum)
      FOT_ts <- period.apply(x = time_FOT, endpoints(x = time_FOT, unit, amount), sum)
      
      # Return list
      timeseries_list <- list("FOS_ts" = FOS_ts, "FOT_ts" = FOT_ts)
      return(timeseries_list)
      
    }

### Group data (& keep top x)
    
    grouper_function <- function(DF, group, keep_number = nrow(DF)) {
      
      by_group <- group_by_(DF, group)
      output <- summarise(by_group, count = n())
      output <- output[order(-output$count),]
      output <- head(output, keep_number)
      
      return(output)
      
    }
    
############################### Layout Plots ############################### 
    
    
    blank_theme <- theme_minimal() +
      theme(
        axis.title.x = element_blank(),
        # axis.text = element_blank(),
        axis.title.y = element_blank(),
        panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.ticks = element_blank(),
        plot.title=element_text(face = "plain")
      )
    
    proximus_colors <- c("#5C2D92", "#4C9DDD", "#EE2E5D")

    
    
    
############################### Testing Purposes ############################### 
    
    
### Temporary solution
    
# input_table <- subset(full_table, 
#                       select = c(CUST_ID, ADIV, STREET_CD, CITY_ZIP, CITY_NAME, 
#                                  MED_SEG_START_TS, lng, lat, count))
    
### Waarom worden er zo weinig adressen gevonden?

# table(test$CUST_ID == -1)
# FALSE   TRUE 
# 105196  71372 

    test <- full_table[is.na(full_table$lng), "CITY_ZIP"]
    table(is.na(test))
          
    test <- test[!is.na(test)]
    test <- as.data.frame(table(test))
    testII <- test[order(test$Freq, decreasing = T),]
    
    by_group <- group_by(test, "CITY_ZIP")
    output <- summarise(by_group, count = n())
    output <- output[order(-output$count),]
    output <- head(output, keep_number)


### Joining benchmark

# Data table way

    if (!require("rbenchmark")) install.packages("rbenchmark") ; library(rbenchmark)
    
nrow(input_table)
nrow(customer_available)

    benchmark(replications = 1, order = "elapsed",
              merge = merge(input_table, customer_available, all.x = TRUE),
              plyr = left_join(input_table, customer_available, by = "CUST_ID"),
              data.table =  { 
                dt1 <- data.table(input_table, key = "CUST_ID")
                dt2 <- data.table(customer_available, key = "CUST_ID")
                Result <- as.data.frame(dt2[dt1,])
              }
    )






  
  # Set WD & Load Packages
  
  setwd('C:\\Users\\Andreas\\Desktop\\Wishlist_plotter')
  
  library(RCurl)
  library(ggmap)
  library(leaflet)
  library(shiny)
  library(ggplot2)
  library(devtools)
  library(shinyapps)
  
  shinyapps::setAccountInfo(name='withaeckx', token='E49EA53AADA74668DA3F2EFB1687A7D4', secret='HZcIHfiHu1ZfR+Li2MZWBTDBZTjcbQm8z1DYixif')
  
  
  # Get Update Google Docs
  
  URL <- "https://docs.google.com/spreadsheets/d/18UKxK4OvvoU4WBmygW7Rt09mzAbt7X5WMRiGu4793EE/pub?gid=0&single=true&output=csv"
  myCsv <- getURL(URL)
  locaties <- read.csv(textConnection(myCsv))
  locaties
  locaties[, "Fullname"] <- paste0(locaties[, "Destination"], ", ", locaties[, "Country"] )
  
  # Matching with existing file
  
  travelwishlist <- read.csv('C:\\Users\\Andreas\\Desktop\\Wishlist_plotter\\Travel_wishlist.csv')
  new_entries <- locaties[!(locaties[, "Fullname"] %in% travelwishlist[, "Fullname"]),]
  
  # Adding new entries
  
  if (nrow(new_entries) > 0) {
  
      # Looking for locations new entries
      
      print("Searching for locations new entries... ")
      
      for (i in (1:nrow(new_entries))) {
        searchword <- new_entries[i, "Fullname"]
        print (searchword)
        new_entries[i,"Longitude"] <- geocode(searchword, source = "google")[1]
        new_entries[i,"Latitude"] <- geocode(searchword, source = "google")[2]  
      }
      
      # Adding new entries to existing excel-file and saving it
      
      false_locations <- new_entries[is.na(new_entries$Longitude),]
      
      if (nrow(false_locations) > 0) {
        cat("Pay attention human!\nsome destinations have not been found:\n")
        print(as.character(new_entries[is.na(new_entries$Longitude),]))
      }
      
      travelwishlist <- rbind(travelwishlist, new_entries[!is.na(new_entries$Longitude),])
      write.csv(travelwishlist, 'file = C:\\
                Users\\Andreas\\Desktop\\Wishlist_plotter\\Travel_wishlist.csv')
  
  } # end adding new locations
  
  
  ## SHINY
  
  
  runApp()

  # shinyapps::deployApp('C:\\Users\\Andreas\\Desktop\\Wishlist_plotter')
  
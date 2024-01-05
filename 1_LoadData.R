# Install necessary packages
#install.packages(c("ggplot2", "ggmap", "sf", "dplyr", "shiny", "leaflet", "shinythemes"))

# Load required libraries
library(dplyr)
library(ggplot2)
library(shiny)
library(sf)
library(leaflet)
library(shinythemes)
library(leaflet.extras)


# Extract and convert the latitude and longitude from the IGC paragliding records
# from the Skytraxx variometer.
extract_lat_lon_alt <- function(record) {
  lat_deg <- as.numeric(substr(record, 8, 9))
  lat_min <- as.numeric(substr(record, 10, 14)) / 1000
  lat <- lat_deg + lat_min / 60
  if (substr(record, 15, 15) == "S") {
    lat <- -lat
  }

  lon_deg <- as.numeric(substr(record, 16, 18))
  lon_min <- as.numeric(substr(record, 19, 23)) / 1000
  lon <- lon_deg + lon_min / 60
  if (substr(record, 24, 24) == "W") {
    lon <- -lon
  }

  alt <- as.numeric(substr(record, 32, 35))

  return(data.frame(lat, lon, alt))
}



read_igc_files <- function(directory) {
  filenames <- list.files(directory, pattern = "\\.igc$", full.names = TRUE)
  
  # Function to extract coordinates from a single file
  extract_coords_from_file <- function(filename) {
    lines <- readLines(filename)
    b_records <- grep("^B", lines, value = TRUE)
    coords_list <- lapply(b_records, extract_lat_lon_alt)  # Updated this line
    do.call(rbind, coords_list)
  }
  
  # Apply the function to each file
  all_coords_list <- lapply(filenames, extract_coords_from_file)
  
  # Combine all results
  coords <- do.call(rbind, all_coords_list)
  
  # Calculate altitude difference
  coords$alt <- c(0, diff(coords$alt))
  
  # Filter rows where the altitude difference is positive
  coords <- coords[(coords$alt > -5.5) & (coords$alt < 10), ]
  
  # Discretize latitude and longitude
  coords$lat <- floor(coords$lat * 1000) / 1000
  coords$lon <- floor(coords$lon * 1000) / 1000
  
  # Calculate mean altitude difference for each grid cell
  #mean_alt_diff <- aggregate(alt ~ lat + lon, data = coords, mean)
  # Calculate mean altitude difference and counts for each grid cell
  aggregated_data <- aggregate(cbind(alt, counts = 1) ~ lat + lon, 
                               data = coords, 
                               FUN = function(x) {
                                 c(mean = mean(x), count = sum(x))
                               })
  
  # Split the aggregated columns into separate columns
  aggregated_data$alt <- aggregated_data$alt[, "mean"]
  aggregated_data$count <- aggregated_data$counts[, "count"]
  aggregated_data$counts <- NULL
  
  
  
  return(aggregated_data)
}

# Read all the files and save them
df <- read_igc_files("./AllFlights/")
save(df, file = "./thermals_data.RData")


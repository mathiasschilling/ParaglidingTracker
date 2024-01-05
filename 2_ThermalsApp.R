# Install necessary packages
# Uncomment the line below to install the required packages for data manipulation, visualization, and Shiny app creation.
#install.packages(c("ggplot2", "ggmap", "sf", "dplyr", "shiny", "leaflet", "shinythemes"))

# Load required libraries
# These libraries are used for data processing, creating visualizations, and building the Shiny web application.
library(dplyr)
library(ggplot2)
library(shiny)
library(sf)
library(leaflet)
library(shinythemes)
library(leaflet.extras)

# Load the processed data for visualization in the Shiny app
load(file = "./thermals_data.RData")

# Calculate the bounding box (extent) of your data points
# This is used to set the initial view of the map in the Shiny app.
bbox <- st_bbox(st_as_sf(df, coords = c("lon", "lat"), crs = 4326))

## Define the Shiny app UI
# The user interface of the app, including layout and content.
ui <- fluidPage(
  theme = shinytheme("slate"),  # Applying a theme for better visual appeal
  
  headerPanel("Where to find thermals"),
  p("This Shiny app visualizes altitude changes from paragliding flights to identify potential thermals. IGC flight data were processed to highlight areas with significant altitude variations on a map. Colored rectangles on the map represent aggregated data from specific locations, with color intensity showing altitude differences. Hovering over these rectangles displays average altitude change and data point counts, offering insights for pilots to find favorable flying conditions."),
  
  fluidRow(
    column(12,
           leafletOutput("heatmapPlot", height = 900)  # Leaflet plot output with specified height for better visualization
    )
  )
)

# Define the server logic
# This function defines how the server will process data and react to user inputs.
server <- function(input, output, session) {
  output$heatmapPlot <- renderLeaflet({
    grid_size <- 0.001  # Setting the size of each grid cell for the heatmap
    
    # Calculate boundaries for each grid cell
    # This step is crucial for the heatmap visualization.
    df$lat_min <- df$lat
    df$lat_max <- df$lat + grid_size
    df$lon_min <- df$lon
    df$lon_max <- df$lon + grid_size
    
    # Create labels for altitude differences
    # These labels will be displayed when hovering over the heatmap rectangles.
    labels <- paste("Avg. height gain: ", round(df$alt, 2), "m/s, ",
                    "Counts:", df$count)
    
    # Create a continuous color palette
    # The palette visually differentiates the altitude differences.
    pal <- colorBin(palette = c("red", "darkorange", "aquamarine", "chartreuse", "darkgreen"),
                    domain = df$alt, bins = c(-Inf, -1.5, -0.5, 0.1, 1.1, Inf))
    
    leaflet() %>%
      addTiles() %>%
      # Additional tile layers commented out below can be used for different map backgrounds.
      # addProviderTiles(providers$Esri.WorldImagery) %>%  
      # addProviderTiles(providers$Esri.DeLorme) %>%  
      addProviderTiles(providers$Esri.WorldTopoMap) %>%  # Default tile layer for the map
      
      addRectangles(lng1 = df$lon_min, lat1 = df$lat_min, lng2 = df$lon_max, lat2 = df$lat_max,
                    color = pal(df$alt), fillColor = pal(df$alt), opacity = 0.1, fillOpacity = 0.3,
                    label = labels,
                    labelOptions = labelOptions(direction = "auto")) %>%
      
      addLegend(pal = pal, values = df$alt, title = "Altitude difference / (m/s)") %>%
      
      setView(lng = mean(c(bbox$xmin, bbox$xmax)),
              lat = mean(c(bbox$ymin, bbox$ymax)),
              zoom = 8)  # Setting the initial view of the map based on the data extent
  })
}

# Run the Shiny app
# This command initiates the app with the defined UI and server logic.
shinyApp(ui, server)


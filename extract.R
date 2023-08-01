# Load packages
library(terra)
library(dplyr)
library(tidyr)

# Takes in common resolution and extent climate and crop raster files
# and obtains crop area weighted climate variables by polygons for given geography
# runs for US counties in first example, then states following

# Read in boundaries set geo names
boundaries <- readRDS("Data/gadm/gadm41_USA_2_pk.rds")
boundaries$NAME_1
geo_names <- data.frame(ID = 1:length(boundaries$NAME_2), 
                        NAME_2=paste(boundaries$NAME_1,boundaries$NAME_2))
geo_var<-quote(NAME_2)

# Read raster input data
input <- list.files("Data/processed", pattern="\\.tif$", full.names = TRUE)
l <- as.list(input) 
crop <- rast("Data/CroplandPastureArea2000_Geotiff/Cropland2000_5m.tif")

#Other params
def_extent <- c(-125, -66.5, 24, 49) #US extent
desired_months <- 4:10
desired_years <- 1980:2020
fx <- mean

# Function to extract seasonal weather weighted by crop area
grab_seasonal_weather <- function(data, desired_years, desired_months, fx, boundaries, geo_names, geo_var) {
  wd <- rast(data)  # Read weather data
  wd <- crop(wd, def_extent)  # Set to US extent
  var <- substr(data, 16, 18)
  crop_us <- crop(crop, def_extent)
  cropex<-terra::extract(crop_us, boundaries, cells=T, ID=F)

  filtered_dates <- time(wd)[format(time(wd), "%Y") %in% desired_years & 
                               as.numeric(format(time(wd), "%m")) %in% desired_months]
  
  wd <- subset(wd, which(time(wd) %in% filtered_dates))  # Retain those cells
  wd <- tapp(wd, factor(format(time(wd), "%Y")), fx, na.rm = TRUE)  # Get mean year for each pixel

  ext <- terra::extract(wd, boundaries, cells = TRUE, ID = TRUE)  # Get all pixels in each state (pkg conflict)
  merged_df <- merge(ext, cropex, by = "cell", all.x = TRUE)  # Merge with crop area
  
  merged_df <- merge(merged_df, geo_names, by = "ID", all.x = TRUE)  # Add in state id


  # Compute weighted average of pixels in state
  ####something wrong with this fun!£#####
  ####s####s####s####s####s####s####s####s####s

merged_df %>%
    mutate(Cropland2000_5m = replace_na(Cropland2000_5m, 0)) %>%
    group_by(ID) %>%
    mutate(totalcrop = sum(Cropland2000_5m)) %>%
    mutate(weight = Cropland2000_5m / totalcrop) %>%
    ungroup() %>%
    pivot_longer(., cols = min(names(wd)):max(names(wd)), values_to = "value") %>%
    mutate(weightedval = value * weight) %>%
    group_by(state = !!geo_var, name) %>%
    summarize(summary = sum(weightedval, na.rm = TRUE)) %>%
    mutate(year = as.numeric(substr(name, 2, 5))) %>%
    select(-name) %>%
    rename(!!var := summary)%>%
     print() %>%
     write.csv(., paste("Data/processed/", var,"_", paste(geo_var), ".csv", sep = ""))
}



#Run
lapply(l, function(x) grab_seasonal_weather(x, desired_years, desired_months, fx,
                                            boundaries, geo_names, geo_var))

# Modify boundaries and geo names to state and re-run 
boundaries <- readRDS("Data/gadm/gadm41_USA_1_pk.rds")
geo_names <- data.frame(ID = 1:length(boundaries$NAME_1), 
                        NAME_1=boundaries$NAME_1)
geo_var<-quote(NAME_1)
lapply(l, function(x) grab_seasonal_weather(x, desired_years, desired_months, fx, 
                                            boundaries, geo_names, geo_var))



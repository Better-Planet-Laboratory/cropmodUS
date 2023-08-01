## Stack data
# stacks data in different raster files separated in different folders by date
# using dates in file names to stack
# additional functions also crop to AOI 
# and reproject/resample to ref grid for project reqs
# writes output to single stacked raster

# Load packages
library(terra)

stack_fun<-function(main_folder,var, extension,files,yrstart,mstart, nan){

  # Loop through each file
  for (file in  files) {
    
    # Read in
    layer <- rast(file)
    #Set any nan values to na
    layer[layer==nan] <-NA
  
    # Reproject
    # NB results from project map on to a crop, resample combo
    if (crs(layer) !=crs(crop_us) | ext(layer) !=ext(crop_us)) { 
      layer<-project(layer, crop_us, method="average")
    }
    
    # Extract the year and month from the filename
    year <- substr(file, yrstart, yrstart+3)
    month <- substr(file,mstart, mstart+1)
    
    # Set the time slot of the raster
    time(layer) <- as.Date(paste(year, month, "01", sep = "-"))

    # Add the layer to the list
    layer_list[[file]] <- layer

  }

# Sort the layers based on dates
sorted_layers <- layer_list[order(gsub(paste(".*/|\\",extension,""), "", names(layer_list)))]

# Stack all layers
stacked_layers <- rast(sorted_layers)

# Set the variable name, unit, and filename
filename <- paste(var, ".tif", sep="")

# Save the final result
output_folder <- "Data/processed"
writeRaster(stacked_layers, filename = file.path(output_folder, filename),overwrite=TRUE)

}

# Run for mean temp

# Get crop mask to match res.
crop<-rast("Data/CroplandPastureArea2000_Geotiff/Cropland2000_5m.tif")
us_extent <- c(-125, -66.5, 24, 49)
crop_us <- crop(crop, us_extent)

# Set the path to the main folder containing the subdirectories
main_folder <- "Data/PRISM/temp"
var<-"tmean"
extension<-".bil"

# Create an empty list to store processed layers
layer_list <- list()

# List files
files <-  list.files(main_folder, pattern = paste("PRISM_",var, 
                                                  "_stable_4kmM3_\\d{6}_bil\\.bil$",
                                                  sep=""),
                     full.names = TRUE, 
                     recursive =T )

#Date params
yrstart<-57
mstart<-61

#numeric NAN values if applicable
nan<--999 

stack_fun(main_folder,var, extension,files,yrstart,mstart, nan)


# Update params for ppt mean and run
main_folder <- "Data/PRISM/ppt"
var<-"ppt"
layer_list <- list()
yrstart<-54
mstart<-58
files <-  list.files(main_folder, pattern = paste("PRISM_",var, 
                                                  "_stable_4kmM3_\\d{6}_bil\\.bil$",
                                                  sep=""),full.names = TRUE, recursive =T )

stack_fun(main_folder,var, extension,files,yrstart,mstart, nan)


# Update params for CHC data and run
main_folder <- "Data/CHC"
var<-"tx30"
extension<-".tif"
layer_list <- list()
files <-  list.files(main_folder, pattern = paste("\\.tif",
                                                  sep=""),
                     full.names = TRUE, 
                     recursive =T )
yrstart<-24
mstart<-29
nan<--9999

stack_fun(main_folder,var, extension,files,yrstart,mstart,  nan)



## Get data with basic url/doi

# Get crop data time-series
#https://github.com/eblondel/zen4R/wiki
zen4R::download_zenodo(path = "Data/", "10.5281/zenodo.7332106")
unzip(zipfile = "Data/Stability_Crop_Diversity-2.0.zip", exdir = "Data/")

# Download files function if needed for multiple files.
options(timeout=1e10)
download_files <- function(url_list, path) {
  for (url in url_list) {
    file_name<-paste(path,basename(url), sep="")
    download.file(url, destfile = file_name, mode = "wb",method = "curl")
    cat("Downloaded:", file_name, "\n")
  }
}

# Get crop data    
download_files("https://s3.us-east-2.amazonaws.com/earthstatdata/CroplandPastureArea2000_Geotiff.zip",
               "Data/")  
unzip(zipfile = "Data/CroplandPastureArea2000_Geotiff.zip", exdir = "Data/")

# US state boundaries
library(geodata)
US_shape_1 <- gadm("USA", level=1, path="Data/")
US_shape_2 <- gadm("USA", level=2, path="Data/")

# SPEI nCLIM
download_files("https://www.ncei.noaa.gov/pub/data/nidis/indices/nclimgrid-monthly/spei-gamma/nclimgrid-spei-gamma-03.nc",
               "Data/nCLIMGRID/")  

# Look up tables 
# specific to plot line project. 
# "scd-final_crop_names-crosswalk.csv" the only non-public data 
# update this file to download when made public.


# Calenders
#simplest approach is to use two vars, April-Oct for most annuals, and full annual summary
#for all other crops.... https://ipad.fas.usda.gov/rssiws/al/crop_calendar/us.aspx


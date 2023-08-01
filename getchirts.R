## Get CHIRTS extremes data
#https://data.chc.ucsb.edu/experimental/CHC_CMIP6/Data_Descriptor_CHC_CMIP6_climate_projection_dataset.pdf

# Load packages
library(httr)
library(stringr)

base_url <- "https://data.chc.ucsb.edu/experimental/CHC_CMIP6/extremes/Tmax/observations/"
local_directory <- "Data/CHC/"

# Function to download a file
download_file <- function(url, destination) {
  GET(url, write_disk(destination, overwrite = TRUE))
}

# Function to retrieve files with the specified pattern from a directory
retrieve_files <- function(url, destination_dir) {
  response <- GET(url)
  if (status_code(response) == 200) {
    files <- str_match_all(content(response, "text"), "Daily_Tmax_\\d+_\\d+_cnt_Tmaxgt30C\\.tif")
    files <- unlist(files)
    if (length(files) > 0) {
      for (file in files) {
        file_url <- paste0(url, file)
        destination <- paste0(destination_dir, file)
        download_file(file_url, destination)
      }
    }
  }
}

# Main function to download files from the base URL and subdirectories
download_files <- function() {
  if (!dir.exists(local_directory)) {
    dir.create(local_directory, recursive = TRUE)
  }
  
  for (i in 1:12) {
    subdir <- sprintf("%02d", i)
    subdir_url <- paste0(base_url, subdir, "/")
    destination_dir <- paste0(local_directory, subdir, "/")
    
    if (!dir.exists(destination_dir)) {
      dir.create(destination_dir, recursive = TRUE)
    }
    
    retrieve_files(subdir_url, destination_dir)
  }
}

# Call the main function to start downloading the files
download_files()

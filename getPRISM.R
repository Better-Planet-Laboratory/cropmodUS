## Get PRISM monthlies data

# Load packages
library(httr)
library(stringr)

base_url <- "https://ftp.prism.oregonstate.edu/monthly/tmean/"
local_directory <- "Data/PRISM/temp/"
range<-1980:2020
textstring<-"PRISM_tmean_stable_4kmM3_\\d+_all_bil.zip"

# Function to download a file
download_file <- function(url, destination) {
  GET(url, write_disk(destination, overwrite = TRUE))
}

# Function to retrieve files with the specified pattern from a directory
retrieve_files <- function(url, destination_dir) {
  response <- GET(url)
  if (status_code(response) == 200) {
    files <- str_match_all(content(response, "text"),textstring)
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
  
  for (i in 1980:2020) {
    subdir <- sprintf("%02d", i) #
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

# Update and run for ppt
base_url <- "https://ftp.prism.oregonstate.edu/monthly/ppt/"
local_directory <- "Data/PRISM/ppt/"
range<-1980:2020
textstring<-"PRISM_ppt_stable_4kmM3_\\d+_all_bil.zip"
download_files()



# Unzip PRISM
unzip_all_files <- function(base_directories) {
  for (base_dir in base_directories) {
    years <- 1980:2020
    for (year in years) {
      # Construct the current directory path
      directory <- file.path(base_dir, as.character(year))
      
      # Get list of zip files in the current directory
      zip_files <- list.files(path = directory, pattern = ".zip$", full.names = TRUE)
      
      if (length(zip_files) > 0) {
        # Create a new folder for extracted files if it doesn't exist
        extracted_folder <- file.path(directory, "extracted")
        if (!file.exists(extracted_folder)) {
          dir.create(extracted_folder)
        }
        
        # Unzip each zip file in the current directory
        for (zip_file in zip_files) {
          unzip(zip_file, exdir = extracted_folder)
        }
        
        cat(paste("Successfully extracted files from", length(zip_files), "zip file(s) in", directory, "\n"))
      } else {
        cat(paste("No zip files found in", directory, "\n"))
      }
    }
  }
}

# Unzip
base_directories <- c("data/PRISM/ppt", "data/PRISM/temp")
unzip_all_files(base_directories)


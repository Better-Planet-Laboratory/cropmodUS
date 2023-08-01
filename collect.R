# Collect

# Here we summarize the bootstrap results
# to show the effect of weather on yields for each crop in each year in each state relative to mean climatology
# we take 99% confidence intervals to show uncertainty in the effects
# adjust as required (the output data allows for a lot of comparisons to be made!)

# Load libraries
library(data.table)
library(dplyr)
library(parallel)


# Get state list
process_state_data <- function(state_name, directory_path) {
  filenames <- list.files(path = directory_path, pattern = paste0(state_name, "\\d+\\.csv"), full.names = TRUE)
  state_data <- rbindlist(lapply(filenames, fread), use.names = TRUE, fill = TRUE)
  
  # Calculate percentiles for the "loss" variable
  # Note, multiple of same crops may exist per county, due to grouping, this takes the full distribution of all effects.
  result <- state_data %>%
    group_by(county_crop_id, year) %>%
    summarize(
      lower = round(quantile(loss, probs = 0.01, na.rm = TRUE), digits = 1),
      upper = round(quantile(loss, probs = 0.99, na.rm = TRUE), digits = 1),
      average = round(quantile(loss, probs = 0.5, na.rm = TRUE), digits = 1)
    )
  
  # Write the result to a CSV file for the state
  state_filename <- paste0("Data/modout/summary/",state_name, "_result.csv")
  fwrite(result, file = state_filename)
  
  # Remove the data to free up memory for the next state
  rm(state_data, result)
  
  return(invisible(NULL))  # To suppress unnecessary output in mclapply
}

state_names <- unique(dat_pred_county$state_abb)
directory_path <- "Data/modout/raw"
num_cores <- detectCores()  # Number of CPU cores available for parallel processing
mclapply(state_names, process_state_data, directory_path, mc.cores = num_cores)


# Read all
directory_path<-"Data/modout/summary"
output_filename<-"Data/modout/end/county_loss.csv"
combine_state_results <- function(output_filename, directory_path) {
  # Get the list of state result files
  state_files <- list.files(path = directory_path, pattern = "_result.csv", full.names = TRUE)
  
  # Read and combine all state result files
  state_data_list <- lapply(state_files, fread)
  combined_data <- rbindlist(state_data_list, use.names = TRUE, fill = TRUE)
  
  # Write the combined data to a CSV file
  fwrite(combined_data, file = output_filename)
}
combine_state_results(output_filename,directory_path)


# Join with look up
dat_pred_county<-readRDS("Data/processed/dat_pred_county.rds")
dat<-read.csv("Data/modout/end/county_loss.csv")

dat_pred_county %>% select(state_abb,county, interpolated, Final.Name, state_county, year)%>%
  mutate(county_crop_id = as.numeric(as.factor(paste(state_county, Final.Name,sep=" "))),
         county_crop_id_year=paste(county_crop_id, year, sep="")) %>%
  distinct(county_crop_id_year,.keep_all = T)  %>%
  left_join(dat, by=c("county_crop_id", "year")) %>%
  rename(crop=Final.Name, state=state_abb) %>%
  select(state,county, crop, year, average, upper, lower, interpolated ) %>%
  mutate_at(c('state', 'county'), as.factor)%>%
  write.csv("Data/modout/end/county_loss_id.csv", row.names = F) 
  




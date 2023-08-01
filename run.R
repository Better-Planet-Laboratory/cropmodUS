library(progress)

# List of script files
script_files <- c(
  "directoryadd.R",
  "renvsetup.R",
  "extrafunctions.R",
  "geturls.R",
  "getPRISM.R",
  "getchirts.R",
  "stack.R",
  "speiclean.R",
  "extract.R",
  "combine.R",
  "checkmod.R",
  "inference.R",
  "collect.R",
  "demo.R"
)

# Initialize a progress bar
pb <- progress_bar$new(total = length(script_files))

# Counter for completed scripts
completed_scripts <- 0

# Loop through the script files
for (script_file in script_files) {
  tryCatch({
    source(script_file)
    # Update progress bar and indicator
    completed_scripts <- completed_scripts + 1
    pb$tick()
    cat(paste0("\rProgress: [", rep("#", completed_scripts), rep(".", length(script_files) - completed_scripts), "] ", completed_scripts, "/", length(script_files),
               " ", script_file
    ))
  }, error = function(e) {
    # If an error occurs, show a failed message in the progress output and stop the loop
    completed_scripts <- completed_scripts + 1
    pb$tick()
    cat(paste0("\rProgress: [", rep("!", completed_scripts), rep(".", length(script_files) - completed_scripts), "] ", completed_scripts, "/", length(script_files),
               " ", script_file, " (FAILED", ")"
    ))
    stop(e$message, ". Script needs fixing.")
  })
}

# Line break after the loop finishes
cat("\n")

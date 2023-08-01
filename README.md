# CropmodUS

# Overview

This repository allows you to estimate the impacts of weather (main growing season temperature, precipitation, standardized precipitation index and days >30C) on 20+ crops within the USA over the time series 1983-2016. Statistical crop yield models are fit using state level observations and the yearly impact of weather is predicted at the county level.We compare the predicted yields for a given crop and county for a given year and weather observation to the predicted yield under the mean climate observed in that county. Running the scripts will result in a database that contains the annual yield anomaly due to weather for each crop and county. Uncertainty for the  estimates are given via residual bootstrapping.

![Alt Text](https://github.com/Better-Planet-Laboratory/cropmodUS/assets/demo.png)


# Requirements

All dependencies and software tools required to run this analysis is included in a Dockerfile and the renv.lock file. The build as currently set up uses 8 CPU cores for parallel processing, 32 GB Memory, and utilizes around 45 GB of disk space. Due to data download requirements from the internet, a stable internet connection and Ethernet cable is recommended.

# Script contents

- `directoryadd.R` adds the necessary folders to your local environment.

- `renvsetup.R` will download all the required package versions.

- The `get`  scripts download all the necessary data from the internet and unzip if required. 

- `stack.R` formats weather data which comes in different formats. For convenience this scripts also clips the data to the AOI, and set geospatial resolution and extent for the project.

-  `extract.R`  extracts the weather data by each state and county polygon, over the defined time series, and specified growing season.

- `combine.R`  takes all the different data sets (weather, production, irrigation coverage etc) and combines them. It also creates dataframes for prediction.

-  `checkmod.R`  fits the basic model used, it examines the fit, the partial plots, and saves other assets which allow you to inspect the model. To be found in `Data/modcheck/`

- `inference.R`  fits the state level model, and does prediction of the impact of weather on yields at the county level, and compares the yield in each year to that expected yield in that year under average climatology. It uses residual bootstrapping to estimate uncertainty.

- `collect.R` collects the results. It uses the bootstrap runs to compute the 50th, 1st and 99th percentiles of the effects. 

- `demo.R` reads the data and plots the effects over time by crop.

- `run.R` runs through all the scripts listed above in sequence.

# Running

Download this repo. Install [Docker][docker] and launch it. And then run the below bash commands in the project directory. They will build the image and run all of the scripts in the order they need to be executed.

``` bash
docker build cropmodus:v0.1 .
docker run cropmodus:v0.1
```

If you don't want to use Docker, you can also just run the following script within R, which will run the pipeline using the specified package versions. The R version used for this analysis is included in the renv.lock file.

``` r
source("run.R"")
```

# Main output 

The key output file for this program is a file found at `Data/modout/end/county_loss_id.csv`, which can be used to yield insights (see `demo.R`). The variables for this file includes:

- year: integer, identifying the year of estimated impact
- county: factor, the county 
- state:  factor, two letter state code
- crop: factor, crop 
- average: numeric, 50th percentile of impact
- lower: numeric, 1st percentile of impact
- upper: numeric,  99th percentile of impact
- interpolated: logical, T/F flag to identify if predictions are made for years outside USDA records (e.g. hind casts for minor or specialty crops prior to national reporting)

Note: these are predicted impacts for counties for crops where state level production was reported. Intersecting with additional data, e.g. the USDA cropland data layer would allow you to identify counties that actually grew the crop within the state, if such additional filtering is required for your application.

# Getting help

If you encounter a  bug, please file an issue with a minimal reproducible example on GitHub. For questions and other discussion, feel free to contact me.

# License

The data product is distributed is under a [Creative Commons Attribution 4.0 International License][cc-by].

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[docker]: https://www.docker.com/products/docker-desktop/


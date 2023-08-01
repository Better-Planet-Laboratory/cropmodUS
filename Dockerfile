# Use an official R runtime as a base image
FROM rocker/r-base:4.2.1

# Install system dependencies (if needed) for the R packages in your scripts
# For example, if your R scripts require specific system libraries, install them here
RUN apt-get update -y && apt-get install -y  libcurl4-openssl-dev libssl-dev libnode-dev  libxml2-dev  libxml2-dev libsodium-dev libsecret-1-dev libicu-dev librdf0-dev pandoc libcurl4-openssl-dev libssl-dev libnode-dev make  make  libcurl4-openssl-dev libssl-dev  zlib1g-dev  cmake make  libgdal-dev gdal-bin libgeos-dev libproj-dev libsqlite3-dev  libsodium-dev libsecret-1-dev libssl-dev  pandoc  libssl-dev  libicu-dev librdf0-dev pandoc libcurl4-openssl-dev libssl-dev libxml2-dev libnode-dev make  libicu-dev librdf0-dev pandoc libxml2-dev make  git  libicu-dev pandoc libxml2-dev make  libsodium-dev  libicu-dev && rm -rf /var/lib/apt/lists/*

# Set the environment variable to automatically download static libv8 
ENV DOWNLOAD_STATIC_LIBV8 1


# Set the working directory to /app
WORKDIR /app


# Add your R scripts and renv.lock to the container, see dockerignore
COPY . .

# Set permissions to execute the R scripts
RUN chmod +x /app/*.R

# Install renv
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv')"

RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Restore renv environment
RUN R -e "renv::restore()"

# Execute the entry script to run the R scripts in sequence
CMD ["/app/run.R"]
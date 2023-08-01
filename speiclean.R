# Clean spei
# to get in same format as other data.

# Load packages
library(terra)

# Get spei in right format
spei_i<-rast("Data/nCLIMGRID/nclimgrid-spei-gamma-01.nc")
spei_i<- subset(spei_i,which(time(spei_i) > "1980-01-01"))
spei<-aggregate(spei_i, 2,fun="mean")
time(spei)<-time(spei_i)
us_extent <- c(-125, -66.5, 24, 49)
spei<-crop(spei,us_extent)

writeRaster(spei, "Data/processed/spei.tif", overwrite=T)


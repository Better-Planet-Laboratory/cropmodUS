#Create directories
listofdirs<-list("Data", "Data/CHC","Data/gadm", 
                 "Data/nCLIMGRID", "Data/PRISM","Data/crosswalks",  
                 "Data/modout","Data/modout/raw","Data/modout/summary","Data/modout/end",
                 "Data/processed", "Data/modcheck")

lapply(listofdirs, function(x) dir.create(x, file.path(paste(x))))

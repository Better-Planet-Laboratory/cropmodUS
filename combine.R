# Combine all data for model

# Load packages and look ups
library(dplyr)
library(purrr)
library(terra)
library(datasets)
data(state)

# Read all data in 
ppt<-read.csv("Data/processed/ppt_NAME_1.csv")
temp<-read.csv("Data/processed/tme_NAME_1.csv")
prod<-read.csv("Data/Stability_Crop_Diversity-2.0/Data/Outputs/Intermediate_Data/Clean_Data.csv")
irr<-read.csv("Data/Stability_Crop_Diversity-2.0/Data/Inputs/Model_covariates/irrigation_model_input.csv")
tx<-read.csv("Data/processed/tx3_NAME_1.csv")
spei<-read.csv("Data/processed/spe_NAME_1.csv")

#interpolate irrigation
yearstate<-expand.grid(state_name=unique(irr$state_name), year=1980:2020)
irr<-left_join(yearstate,irr, c("state_name", "year"))%>% group_by(state_name)%>%
  mutate(prop.irr.i=zoo::na.approx(prop_irr,na.rm = FALSE))

# Get vars ready
tx$state_abb<-state.abb[match(tx$state,state.name)]
spei$state_abb<-state.abb[match(spei$state,state.name)]
ppt$state_abb<-state.abb[match(ppt$state,state.name)]
temp$state_abb<-state.abb[match(temp$state,state.name)]
irr$state_abb<-state.abb[match(stringr::str_to_title(irr$state_name),state.name)]
prod$yield<-(prod$Production_kg/1000)/prod$Crop_Area_ha
prod$year<-prod$Year
prod$state_abb<-prod$State_Abbr

# Combine
m<-c("year","state_abb" )
result <- prod %>%
  select(year,Crop_Area_ha,yield,Production_kg, Crop_Name,state_abb) %>%
  left_join(ppt %>%
              select(year, state_abb, ppt),
            by = m) %>%
  left_join(temp %>%
              select(year, state_abb, tme),
            by = m) %>%
  left_join(tx %>%
              select(year, state_abb, tx3 ),
            by = m) %>%
  left_join(spei %>%
              select(year, state_abb, spe ),
            by = m) %>%
  left_join(irr %>%
              select(year, state_abb, prop.irr.i),
            by = m) 

  
# save without look up finalized
write.csv(result,"Data/processed/dat_state.csv")

# Function to extend the dates for prediction
extend_years <- function(data, start_year, end_year) {
  valid_combinations <- data %>%
    group_by(Crop_Name, state_abb) %>%
    filter(!is.na(yield)) %>%
    summarize(has_data = any(!is.na(yield))) %>%
    filter(has_data) %>%
    select(-has_data)%>% 
    group_by(Crop_Name, state_abb) %>%
    tidyr::uncount(34)%>%
    mutate(year=1983:2016)%>%
    left_join(irr %>% select(year, state_abb, prop.irr.i),
              by = m) %>%
    mutate(yield= 1)
  nrow(valid_combinations)
  
data$interpolated<-ifelse(is.na(data$yield), T, F)
valid_combinations<-data %>% select(year, state_abb,  Crop_Name,interpolated) %>%
  right_join(valid_combinations, by=c("state_abb", "year", "Crop_Name"))%>%
  mutate(interpolated=ifelse(is.na(interpolated),T, F))
}

#extend the data
extended_data <- extend_years(result, start_year = 1983, end_year = 2016)
# Now get the county level df
ppt_county<-read.csv("Data/processed/ppt_NAME_2.csv")
temp_county<-read.csv("Data/processed/tme_NAME_2.csv")
tx_county<-read.csv("Data/processed/tx3_NAME_2.csv")
spei_county<-read.csv("Data/processed/spe_NAME_2.csv")

# Join to state
boundaries <- readRDS("Data/gadm/gadm41_USA_2_pk.rds")
geo_names <- data.frame(ID = 1:length(boundaries$NAME_2), 
                        state_county=paste(boundaries$NAME_1,boundaries$NAME_2), 
                        state_name=boundaries$NAME_1,
                        county=paste(boundaries$NAME_2))

ndf<-ppt_county %>% 
  left_join(temp_county,by=c("state", "year")) %>% #NB during extract these state vars are both state/county combined
  left_join(tx_county,by=c("state", "year"))%>%
  left_join(spei_county,by=c("state", "year"))%>%
  left_join(geo_names,by = c("state" = "state_county"))  %>%
  select(!c(X.x,X.y,X.x.x,X.y.y))%>% 
  rename(state_county=state)

ndf$state_abb<-state.abb[match(ndf$state_name,state.name)]

ndf <- extended_data %>%
  right_join(ndf, by=c("year", "state_abb")) %>%
  select(!c(ID,state_name.y)) %>%
  rename(state_name=state_name.x) %>%
  mutate(Crop_Area_ha=NA, Production_kg=NA)

state_county<-ndf$state_county
county<-ndf$county
interpolated<-ndf$interpolated
column_order <- colnames(result)
ndf <- ndf[column_order]
ndf$state_county<-state_county
ndf$county<-county
ndf$interpolated<-interpolated

write.csv(ndf,"Data/processed/dat_county.csv")

# And the get the null df, i.e. average by state.
means<-ndf %>% filter(year %in% 1983:2016)%>%group_by(state_county) %>%
  summarise_at(vars(ppt:spe), mean, na.rm = TRUE) 
  
ndf_null<-ndf %>%  select(!c( ppt,   tme,  tx3,    spe)) %>%
  left_join(means, by="state_county")
column_order <- colnames(ndf)
ndf_null <- ndf_null[column_order]

write.csv(ndf_null,"Data/processed/dat_county_null.csv")


# Final clean

#Get crop crosswalks and clean
cross<-read.csv("Data/crosswalks/scd-final_crop_names-crosswalk.csv")
cross[which(cross$Final.Name =="Tomatoes"),"Final.Category"]<- "Vegetables" #tomatoes group missing

# Function to clean/prep data for model and add in final crop names
cleandat<-function(dat, state) {
  
  dat<- dat %>%left_join(., cross, by=c("Crop_Name"="SCD_NAME")) %>%
    filter(Final.Name != "drop")
  dat$log.yield<-log(dat$yield) #new vars for modelling
  dat$statecrop<-paste(dat$state_abb, dat$Final.Name, "") 
  dat$Final.Name<-as.factor(dat$Final.Name)
  dat$statecrop<-as.factor(dat$statecrop)
  dat<-dat%>% filter(.,!(Final.Name %in% c("Onions", "Radishes")))%>% #not many of these
    filter(!is.na(yield))
  dat<-dat %>% filter(.,year %in% 1983:2016) #get dates with feature coverage
  
  if(state==T){
    dat_sub<-dat %>% select( c("log.yield", "statecrop","Final.Name","year",  "state_abb" ,         
                               "prop.irr.i",  "tme", "tx3", "spe" , "ppt"))}
  else{
    dat_sub<-dat %>% select( c("log.yield", "statecrop","Final.Name","year",  "state_abb" ,         
                               "prop.irr.i",  "tme", "tx3", "spe" , "ppt", "state_county", "county",
                               "interpolated"))
  }
  dat_sub<-as.data.frame(dat_sub)
}

# Prep data
dat_mod<-cleandat(dat=read.csv("Data/processed/dat_state.csv"), state=T)
dat_pred_county<-cleandat(dat=read.csv("Data/processed/dat_county.csv"), state=F)
dat_pred_null<-cleandat(dat=read.csv("Data/processed/dat_county_null.csv"), state=F)

# Write
saveRDS(dat_mod, "Data/processed/dat_mod.rds")
saveRDS(dat_pred_county, "Data/processed/dat_pred_county.rds")
saveRDS(dat_pred_null, "Data/processed/dat_pred_null.rds")

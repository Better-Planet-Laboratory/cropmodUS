# Inference

# estimate the effect of weather on yields for each crop in each year in each state relative to mean climatology
# re-sample residuals to estimate uncertainty in the differences
# looking at plots (see Data/modcheck/), normal approximations unlikely to hold
# lmer output close to rlmer for most crops, with greater deviations for some states in Berries, Broccoli/Cauliflower, Oranges, Other citrus, Stone-fruits and Tree nuts
# future sensitivity with alternative methods e.g. lmrob and FRB https://github.com/msalibian/FRB  a good idea
# for historical reconstructions we follow similar approach, might be worth checking uncertainty in hindcasts where data absent, e.g. using time-series analysis https://otexts.com/fpp2/, depending on application

# Load libs
library(lme4)
library(dplyr)
library(lme4)
library(nloptr)
library(parallel)
library(data.table)

# Get data
dat_mod<-readRDS( "Data/processed/dat_mod.rds")
dat_pred_county<-readRDS( "Data/processed/dat_pred_county.rds")
dat_pred_null<-readRDS( "Data/processed/dat_pred_null.rds")
dat_pred_county$log.yield<-NA
dat_pred_null$log.yield<-NA

# Optimizer set
nlopt <- function(par, fn, lower, upper, control) {
  .nloptr <<- res <- nloptr(par, fn, lb = lower, ub = upper,
                            opts = list(algorithm = "NLOPT_LN_BOBYQA", print_level = 1,
                                        maxeval = 1000, xtol_abs = 1e-6, ftol_abs = 1e-6))
  list(par = res$solution,
       fval = res$objective,
       conv = if (res$status > 0) 0 else res$status,
       message = res$message
  )
  
}

# Bootstrapping function to sample residuals in each geographic location.
sampfun <- function(model, data,idvar) {
  pp <- predict(model)
  rr <- residuals(model)
  dd <- data.frame(data, pred=pp,res=rr)
  dlist<- split(dd, idvar)
  bsamp <- lapply(dlist,
                  function(x) {
                    x$log.yield <- x$pred+ #hard code
                      sample(x$res,size=nrow(x),replace=TRUE)
                    return(x)
                  })
  res <- do.call(rbind,bsamp)  ## collect results
  return(res)
}


lossfun<-function(base, alt){ 
  difference <- exp(alt-base )
  percentage_difference = (difference - 1) * 100
  return(percentage_difference)
}


# Fit base model
model<-lmer(log.yield~
              poly(year,1)*Final.Name+
              poly(tme,2)*Final.Name+
              poly(tx3,1)*Final.Name+
              poly(spe,2)*Final.Name+ 
              poly(ppt,2)*Final.Name+
              prop.irr.i*Final.Name+
              (1|statecrop),
            control = lmerControl(optimizer = "nlopt", calc.derivs = T),
            dat_mod)

# Function to perform one iteration of the bootstrap and save the result
run_bootstrap <- function(i) {
  m1 <- lmer(log.yield ~
               poly(year, 1) * Final.Name +
               poly(tme, 2) * Final.Name +
               poly(tx3, 1) * Final.Name +
               poly(spe, 2) * Final.Name + 
               poly(ppt, 2) * Final.Name +
               prop.irr.i * Final.Name +
               (1|statecrop), 
             control = lmerControl(optimizer = "nlopt", calc.derivs = FALSE),
             data = sampfun(model, dat_mod, dat_mod$statecrop))
  
  dat_pred_county$log.yield <- NA
  dat_pred_null$log.yield <- NA
  
  county <- predict(m1, dat_pred_county) # observed effects
  county_null <- predict(m1, dat_pred_null)  # effects for mean climatology

  # bind into a database
  yield_dat <- data.frame(loss = round(lossfun(county_null, county), digits = 1),
                          bootid = paste(i),
                          state = dat_pred_county$state_abb,
                          county_crop_id = as.numeric(as.factor(paste(dat_pred_county$state_county, dat_pred_county$Final.Name))),
                          year = dat_pred_county$year)
  
  # split and save each for memory savings
  yr_split <- split(yield_dat, yield_dat$state)
  file_out <- paste0("Data/modout/raw/", names(yr_split), i, ".csv")
  yr_split <- lapply(yr_split, function(x) { x["state"] <- NULL; x })
  
  mapply(
    function(x, y) fwrite(x, y, row.names = FALSE), 
    yr_split, 
    file_out
  )
  
  rm.list<-c(yield_dat,yr_split,file_out, county, county_null, m1) #clear things generated in the loop
  gc() #collect garbage in memory
}

# Number of cores to use for parallel processing (you can adjust this as needed)
num_cores <- 6

# Run the bootstraps in parallel
nresamp <- c(1:1000) # set bootstrap samples times

# Run the loop iterations in parallel
mclapply(nresamp, run_bootstrap, mc.cores = num_cores)


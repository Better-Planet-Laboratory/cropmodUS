# Fit model
library(dplyr)
library(lme4)
library(robustlmm)
library(ggplot2)
library(effects)
library(gridExtra)
source("./extrafunctions.R")

# Read file
dat<-readRDS("Data/processed/dat_mod.rds")
  
# Check VIF
write.csv(corvif(data.frame(dat$year,
                   dat$ppt,
                  dat$tme,
                  dat$tx3,
                  dat$spe
                  )), "Data/modcheck/vif.csv")

# Check temporal coverage 
checktemp<-function(dat){
  df_long <- tidyr::pivot_longer(dat, cols = c("log.yield","tme","ppt",  "spe", "tx3"))
  
p<-ggplot(df_long, aes(x = year, y = name)) +
    geom_tile(color = "white") +
    facet_grid(Final.Name~., scales = "free", space = "free") +
    theme_minimal() +
    theme(axis.text.y = element_text(angle = 0, hjust = 1)) +
    theme(strip.text.y = element_text(angle = 360)) +
    labs(x = "Year", y = "Variables", title="Temporal coverage")
  
  ggsave("coverage.png", path="Data/modcheck/", device = png, width = 40, height = 30, units = "cm")
  
}

checktemp(dat)

#Check obs by crop
count<-dat %>% group_by(Final.Name) %>%
  count()  %>% 
  write.csv("Data/modcheck/cropn.csv")


# Check the distribution of yields logged
ggplot(dat, aes(log.yield))+
  geom_histogram()+
  facet_wrap(~Final.Name)
  ggsave("yielddist.png", path="Data/modcheck/", device = png, width = 20, height = 15, units = "cm")


# Fit model
m1<-lmer(log.yield~
           poly(year,1)*Final.Name+
           poly(tme,2)*Final.Name+
           poly(tx3,1)*Final.Name+
           poly(spe,2)*Final.Name+ 
           poly(ppt,2)*Final.Name+
           prop.irr.i*Final.Name+
           (1|statecrop),
         dat)

saveRDS(m1, "Data/modcheck/mod.rds")

# Diagnostics
a<-plot(m1, type=c("p","smooth"), col.line=1)
b<-plot(m1, 
        sqrt(abs(resid(.)))~fitted(.),
        type=c("p","smooth"), col.line=1)
c<-plot(m1, rstudent(.) ~ hatvalues(.))
d<-lattice::qqmath(m1)

residall<-grid.arrange(a,b,c, d, ncol=2)
ggsave("modresid.png",residall,path="Data/modcheck/", device = png, width = 15, height = 15, units = "cm")

png("Data/modcheck/ranefres.png", pointsize = 12, res=300,  width = 10, height = 10, units='cm')
lattice::qqmath(ranef(m1))
dev.off()

# Check the predictor effects
checkeffects<-function(variable, mod, y){
  plot(predictorEffect(variable,mod,  partial.residuals = TRUE),
       partial.residual=list(pch=".", col="#FF00FF80"),
       axes=list(x=list(rotate=45)), ylim=y ,confint=T, id=list(n=1))}

tx<-checkeffects("tx3", m1,c(-4, 5))
spe<-checkeffects("spe", m1,c(-2, 5))
ppt<-checkeffects("ppt", m1,c(-2, 5))
tme<-checkeffects("tme",m1,c(-2, 5))
year<-checkeffects("year",m1,c(-2,5))
irr<-checkeffects("prop.irr.i",m1)

alleff_plot<-list(tx, spe, ppt, tme, year, irr)
names(alleff_plot)<-c("tx", "spe", "ppt", "tme", "year", "irr")
for(i in 1:length(alleff_plot)){
  file<-paste("Data/modcheck/",names(alleff_plot[i]),"_effects.png", sep="")
  png(file, pointsize = 12, 
      res=300,  width = 20, height = 20, units='cm')
 print(alleff_plot[i])
  dev.off()
}
paste("Data/modcheck/",names(alleff_plot[i]),"_effects.png", sep="")


# Check estimate robustness
# Re-fit mod with rlmer 
m2<-rlmer(log.yield~
           poly(year,1)*Final.Name+
           poly(tme,2)*Final.Name+
           poly(tx3,1)*Final.Name+
           poly(spe,2)*Final.Name+ 
           poly(ppt,2)*Final.Name+
           prop.irr.i*Final.Name+
           (1|statecrop),
         dat)

saveRDS(m2, "Data/modcheck/modrobust.rds")


rcheck<-data.frame(rlmer=predict(m2), lmer=predict(m1), crop=dat$Final.Name, state=dat$state_abb)
rcheckplot<-ggplot(rcheck, aes( exp(lmer),exp(rlmer), color=state))+
  geom_point()+
  facet_wrap(~crop, scales="free")+
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "blue")
ggsave("rcheck.png", rcheckplot,path="Data/modcheck/", device = png, width = 30, height = 20, units = "cm")

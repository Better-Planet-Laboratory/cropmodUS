# Plot
library(ggplot2)

# Get model output
dat<-read.csv("Data/modout/end/county_loss_id.csv")
dat$id<-paste(dat$county, dat$crop, dat$state)

# Run 
demo<-ggplot(dat, aes(year,average, by=id))+
  geom_line(alpha=0.0065, color="blue")+
  facet_wrap(~crop, scales="free_y")+
  theme_minimal()+
  ylab("Yield delta due to weather (%)")
ggsave("demo.jpg", demo,path="assets", device = jpeg, width = 25, height = 20, units = "cm",dpi=200 )

  
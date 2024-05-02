#All the best#

##Effects of political partisanship in COVID 19 cases and deaths across US counties##

## This file contains the code that collects and cleans the data for this project##

setwd("~/Downloads/Source Data")
library(readxl)
industry <- read_excel("Industry_Concen_by_County.xlsm", 
                         +     col_types = c("text", "text", "skip", 
                                             +         "skip", "skip", "skip", "text", "text", 
     
                                                                                  +         "numeric"))
library(dplyr)
industry %>% 
  group_by(GeoName) %>%
  mutate(mfg_share = industry$Year2020[industry$Description == 'Manufacturing']/industry$Year2020[industry$Description == 'Private nonfarm earnings'])
  

#####  ISE 298 Project Analysis Code by Vinithra Nagaraj --------
# April 30 2022

setwd("~/Downloads/Source Data")

# The following packages are presumed to be installed before performing the 
# following code. httr, jsonlite, lubridate, devtools, usmap, mapdata, urbnmapr, 
# tidyverse, RSocrata, scales, vtable, dagitty, ggdag, jtools, huxtable,ggstance,
# broom.mixed,officer,flextable,openxlsx,psych

#Sec  1: Data Description------------------------------------------------------

library(readxl)
COVIDfirst <- read_excel("COVIDfirst.xlsx")

# COVID First has the following variables at the County Level 
# County Identifiers 
# TotalCOVIDDeaths: COVID Deaths as of 21 December 2021
# Population: County Population
# DeathsPer100K: County level COVID deaths divided by Population * 100k
# RVotes: Number of Votes for Donald Trump in 2020 Presidential Election
# RVotesPer100K: Votes for Donald Trump Divided by County Population * 100k
# RShare: Republican Share of Total Votes
# ALAND: Land area of County [##Put unit]
# County Population Density: County population divided by land area
# Rvotes_16: Number of Votes for Donald Trump in 2016 Presidential Election
# RShare_16: Republican Share of Total Votes 2016
# Percentage_change_Rshare: Percentage increase/decrease of Republicans From 2016 to 2020

#Sec  2: Adding Vaccinations at County Level----------------------------------- 

# Connecting to CDC Database 

library(httr)
library(jsonlite)
library(lubridate)
library("RSocrata")
vaccine_county_data <- read.socrata(
  "https://data.cdc.gov/resource/8xkx-amqh.json",
  app_token = "okVoj18RCuayHktuIbiJftOvY",
  email     = "vinithra.nagaraj@sjsu.edu",
  password  = "1Rajini100Kamal!"
)

#Selecting for Vaccine Completeness as of Jun 2021, Sep 2021, Jan 2022, and April 2022
vaccine_data_jun01 <- vaccine_county_data[ which(vaccine_county_data$date == '2021-06-01'), ]
vaccine_data_sep01 <- vaccine_county_data[ which(vaccine_county_data$date == '2021-09-01'), ] 
vaccine_data_jan01 <- vaccine_county_data[ which(vaccine_county_data$date == '2022-01-01'), ] 
vaccine_data_apr13 <- vaccine_county_data[ which(vaccine_county_data$date == '2022-04-13'), ] 

#Encoding as Factors
vaccine_data_jun01$series_complete_pop_pct <- as.factor(vaccine_data_jun01$series_complete_pop_pct)
vaccine_data_sep01$series_complete_pop_pct <- as.factor(vaccine_data_sep01$series_complete_pop_pct)
vaccine_data_jan01$series_complete_pop_pct <- as.factor(vaccine_data_jan01$series_complete_pop_pct)
vaccine_data_apr13$series_complete_pop_pct <- as.factor(vaccine_data_apr13$series_complete_pop_pct)

#Getting Rid of Subgroup Columns
vaccine_columnsjun01 <- vaccine_data_jun01[c(1,2,4,5,18)]
vaccine_columnssep01 <- vaccine_data_sep01[c(1,2,4,5,18)]
vaccine_columnsjan01 <- vaccine_data_jan01[c(1,2,4,5,18)]
vaccine_columnsapr13 <- vaccine_data_apr13[c(1,2,4,5,18)]

#Renaming
vaccine_columnsjun01$jun01completenesspct <- vaccine_columnsjun01$series_complete_pop_pct 
vaccine_columnssep01$sep01completenesspct <- vaccine_columnssep01$series_complete_pop_pct 
vaccine_columnsjan01$jan01completenesspct <- vaccine_columnsjan01$series_complete_pop_pct 
vaccine_columnsapr13$apr13completenesspct <- vaccine_columnsapr13$series_complete_pop_pct 

#Deleting Duplicate Columns (for merging)
vaccine_columnsjun01 <- vaccine_columnsjun01[c(-5)]
vaccine_columnssep01 <- vaccine_columnssep01[c(-1, -3, -4, -5)]
vaccine_columnsjan01 <- vaccine_columnsjan01[c(-1, -3, -4, -5)]
vaccine_columnsapr13 <- vaccine_columnsapr13[c(-1, -3, -4, -5)]

#Deleting Unknown FIPS Rows
vaccine_columnsjun01 <- subset(vaccine_columnsjun01, fips != "UNK")
vaccine_columnssep01 <- subset(vaccine_columnssep01, fips != "UNK")
vaccine_columnsjan01 <- subset(vaccine_columnsjan01, fips != "UNK")
vaccine_columnsapr13 <- subset(vaccine_columnsapr13, fips != "UNK")

#Merging
vaccine_columns <- merge(x=vaccine_columnsjun01, y=vaccine_columnsjan01, by="fips", all.x=TRUE)
vaccine_columns <- merge(x=vaccine_columns, y=vaccine_columnssep01, by="fips", all.x=TRUE)
vaccine_columns <- merge(x=vaccine_columns, y=vaccine_columnsapr13, by="fips", all.x=TRUE)

vaccine_columns$countyFIPS <- as.numeric(vaccine_columns$fips)  

#Sec  3: Merging for Final Dataset -------------------------------------------

library(dplyr)
library(tidyverse)

#Vaccine_Columns<- vaccine_columns[,c(9,3,4,5,7,6,8)]
ISAFinalDataset <- left_join(COVIDfirst, vaccine_columns, by = "countyFIPS")

#Sec  4: Mapping Variables at the County Level--------------------------------

library(maps)
library(ggplot2)
library(mapdata)
require(devtools)
library(urbnmapr)
library(gridExtra)

#        1 Vaccination Trends------------------------------------------------

counties$fips <- counties$county_fips
vaccine_map <- left_join(vaccine_columns, counties, by = "fips")
vaccine_map$jun01completenesspct <- as.numeric(as.character(vaccine_map$jun01completenesspct))
vaccine_map$sep01completenesspct <- as.numeric(as.character(vaccine_map$sep01completenesspct))
vaccine_map$jan01completenesspct <- as.numeric(as.character(vaccine_map$jan01completenesspct))
vaccine_map$apr13completenesspct <- as.numeric(as.character(vaccine_map$apr13completenesspct))

Map1<-vaccine_map %>%
  ggplot(aes(long, lat, group = group, fill=jun01completenesspct)) +
  scale_fill_gradientn(colours=rainbow(2), limits=c(0,100), name="%Vaccinated") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title="June 2021 Vaccine Penetration",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0), 
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'), 
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

Map2<-vaccine_map %>%
  ggplot(aes(long, lat, group = group, fill=sep01completenesspct)) +
  scale_fill_gradientn(colours=rainbow(2), limits=c(0,100),name="%Vaccinated") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="Sep 2021 Vaccine Penetration",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'),
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

Map3<-vaccine_map %>%
  ggplot(aes(long, lat, group = group, fill=jan01completenesspct)) +
  scale_fill_gradientn(colours=rainbow(2), limits=c(0,100),name="%Vaccinated") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="Jan 2022 Vaccine Penetration",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'),
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

Map4<-vaccine_map %>%
  ggplot(aes(long, lat, group = group, fill=apr13completenesspct)) +
  scale_fill_gradientn(colours=rainbow(2), limits=c(0,100),name="%Vaccinated") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="April 2022 Vaccine Penetration",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'),
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

grid.arrange(Map1,Map2,Map3,Map4)


#        2 Republican Vote Share ----------------------------------------------

# counties$countyFIPS <- counties$county_fips
# counties$countyFIPS <- as.numeric(counties$countyFIPS)
COVIDfirst_map <- left_join(COVIDfirst, counties, by = "countyFIPS")

COVIDfirst_map %>%
  ggplot(aes(long, lat, group = group, fill=RShare)) +
  scale_fill_gradient(low="#001DE8",high="#D9310F", limits=c(0,1),name="R Votes/Total Votes") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="2020 Republican Vote Share",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        panel.background = element_blank())

# Republican Votes Per 100K 

COVIDfirst_map %>%
  ggplot(aes(long, lat, group = group, fill=RVotesPer100K)) +
  scale_fill_gradientn(colours=topo.colors(10),name="R Votes per 100K") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="2020 Republican Votes Per 100K",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        panel.background = element_blank())

#Republican Share 2016
COVIDfirst_map %>%
  ggplot(aes(long, lat, group = group, fill=Rshare_16)) +
  scale_fill_gradient(low="#001DE8",high="#D9310F", limits=c(0,1),name="R Votes/Total Votes") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="2016 Republican Vote Share",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        panel.background = element_blank())

#Percentage difference in Republican Share
COVIDfirst_map %>%
  ggplot(aes(long, lat, group = group, fill=Percentage_change_Rshare)) +
  scale_fill_gradient(low="#001DE8",high="#D9310F",name="R Votes/Total Votes") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title ="Percentage difference in Republican Vote Share 2016 to 2020",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0),
        panel.background = element_blank())

#        3 COVID Deaths ------------------------------------------------------

# COVID Deaths

COVIDfirst_map %>%
  ggplot(aes(long, lat, group = group, fill=DeathsPer100K)) +
  scale_fill_gradientn(colors = c("#CFE8F3", "#A2D4EC", "#73BFE2",
                                  "#46ABDB", "#1696D2", "#12719E", "#0A4C6A", "#062635"),
                       name="DeathsPer100K") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  labs(title="COVID Deaths Per 100K",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0), 
        panel.background = element_blank())

#        4 Other Demographics -------------------------------------------------

# Population Density

Map_D1<-COVIDfirst_map%>%
  ggplot(aes(long, lat, group = group, fill=density)) +
  scale_fill_gradientn(colors = rainbow(8), name="Scaled Values") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) + 
  labs(title="Population Density",
     y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0), 
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'), 
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

#Per Capita Income

Map_D2<-COVIDfirst_map%>%
  ggplot(aes(long, lat, group = group, fill=log(personalincomepercaptia))) +
  scale_fill_gradientn(colors = rainbow(8), name="Scaled Values") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) + 
  labs(title="Personal Per Capita Income",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0), 
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'), 
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

#Age 65 years and plus

Map_D3<-COVIDfirst_map%>%
  ggplot(aes(long, lat, group = group, fill=`Population Aged 65 Years and Older (%)`)) +
  scale_fill_gradientn(colors = rainbow(8), limits=c(5,53),name="% Older adults") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) + 
  labs(title="Percentage Population of older adults \n age 65years and plus",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0), 
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'), 
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

#White population

Map_D4<-COVIDfirst_map%>%
  ggplot(aes(long, lat, group = group, fill=`Percentage of Population - White alone, Not Hispanic or Latino`)) +
  scale_fill_gradientn(colors = rainbow(8), name="% White") +
  geom_polygon(color = "#ffffff", size = 0.05) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) + 
  labs(title="Percentage White Population",
       y="", x="") +
  theme(plot.title = element_text(face = "bold",hjust = 0.5 ),
        legend.justification = c(1, 0), legend.position = c(1, 0), 
        legend.key.height = unit(0.25, 'cm'),
        legend.key.width = unit(0.25, 'cm'), 
        legend.title = element_text(size=7),
        legend.text = element_text(size=7),
        panel.background = element_blank())

grid.arrange(Map_D1,Map_D2,Map_D3,Map_D4)

#Sec  5: Normalization of Key Variables in Regressions -----------------------

# We want to find out if vaccination percentages on specific dates in specific
# counties are above or below the national average. This will give us the 
# relative position of the county to the country, i.e., how hesitant the
# population might be. We will then plot this to see if there are correlations
# with vote shares.

# Converting from factor to numeric


ISAFinalDataset$jun01completenesspct <- as.numeric(as.character(ISAFinalDataset$jun01completenesspct)) 
ISAFinalDataset$sep01completenesspct <- as.numeric(as.character(ISAFinalDataset$sep01completenesspct))
ISAFinalDataset$jan01completenesspct <- as.numeric(as.character(ISAFinalDataset$jan01completenesspct))
ISAFinalDataset$apr13completenesspct <- as.numeric(as.character(ISAFinalDataset$apr13completenesspct))


ISAFinalDataset$vac_jun21 <- as.numeric(as.character(ISAFinalDataset$jun01completenesspct)) 
ISAFinalDataset$vac_sep21 <- as.numeric(as.character(ISAFinalDataset$sep01completenesspct))
ISAFinalDataset$vac_jan22 <- as.numeric(as.character(ISAFinalDataset$jan01completenesspct))
ISAFinalDataset$vac_apr22 <- as.numeric(as.character(ISAFinalDataset$apr13completenesspct))

# Normalization of Variables
# Example Normalization of Vaccination Rates: 
# Normalized Rate = (Vaccine Rate - Mean(Vaccine Rate)) / Standard Deviation(Vaccine Rate)
# Now Vaccination Rates for all four dates will have a mean of 0, and a standard deviation of 1

library(dplyr)
ISAFinalDataset <- ISAFinalDataset %>% 
  mutate_at(c("vac_jun21", "vac_sep21", "vac_jan22", "vac_apr22"), ~(scale(.) %>% as.vector))


# Normalization of Deaths Per 100K, Rshare, Population Density, per capita income, age and Ethnicity
ISAFinalDataset$DeathsPer100K_n <- ISAFinalDataset$DeathsPer100K
ISAFinalDataset$RShare_n <-ISAFinalDataset$RShare
ISAFinalDataset$Density_n <-ISAFinalDataset$density
ISAFinalDataset$personalincomepercaptia_n<-ISAFinalDataset$personalincomepercaptia
ISAFinalDataset$Pop_65Yrs_Plus_Pct_n<-ISAFinalDataset$`Population Aged 65 Years and Older (%)`
ISAFinalDataset$Pop_White_Pct_n<-ISAFinalDataset$`Percentage of Population - White alone, Not Hispanic or Latino`
ISAFinalDataset$Rshare_16_n<-ISAFinalDataset$Rshare_16
ISAFinalDataset$Percentage_change_Rshare_n<-ISAFinalDataset$Percentage_change_Rshare

ISAFinalDataset <- ISAFinalDataset %>% 
  mutate_at(c("DeathsPer100K_n","RShare_n","Density_n","personalincomepercaptia_n",
              "Pop_65Yrs_Plus_Pct_n","Pop_White_Pct_n","Rshare_16_n",
              "Percentage_change_Rshare_n"), ~(scale(.) %>% as.vector))

# Evaluating and eliminating NAs from the main dataset
FinalDataset<-na.omit(ISAFinalDataset)

#Sec  6: Correlation plots --------------------

#What's the relationship between COVID Vaccine Penetration and COVID Deaths?
plot(FinalDataset$DeathsPer100K_n, FinalDataset$vac_jan22,
     xlab = "Covid Deaths per 100k population",
     ylab = "Vaccination Percentage as on Jan 2022",
     main="Relationship between COVID Vaccine penetration \n and COVID Deaths")
abline(lm(FinalDataset$vac_jan22~FinalDataset$DeathsPer100K_n))

#What's the relationship between COVID Vaccine Penetration and R Share?
plot(FinalDataset$RShare_n, FinalDataset$vac_jan22,
     xlab = "Republican Share in each county",
     ylab = "Vaccination percentage as on Jan 2022",
     main="Relationship between COVID Vaccine penetration \n and Republican Share")
abline(lm(FinalDataset$vac_jan22~FinalDataset$RShare_n))

#What's the relationship between R Share and COVID Deaths?
plot(FinalDataset$RShare_n,FinalDataset$DeathsPer100K_n,
     xlab = "Republican Share in each county",
     ylab = "COVID Deaths per 100K population",
     main="Relationship between Republican Share \n and COVID Deaths")
abline(lm(FinalDataset$DeathsPer100K_n~FinalDataset$RShare_n))

#What's the relationship between percentage difference in R Share and COVID Deaths?
plot(TestCor$Percentage_change_Rshare_n,TestCor$DeathsPer100K_n,
     xlab = "Percentage change in Republican Share",
     ylab = "COVID Deaths per 100K",
     main="Relationship between % change in Republican Share \n and COVID Deaths")
abline(lm(FinalDataset$DeathsPer100K_n~FinalDataset$Percentage_change_Rshare_n))

#        COR PLOTS DATA SECTION  ############

library(psych)

# FinalDataset$Deaths_by_RVotes <- FinalDataset$TotalCovidDeaths/FinalDataset$RVotes
# FinalDataset$Deaths_by_RVotes_n <- FinalDataset$Deaths_by_RVotes
# FinalDataset <- FinalDataset %>% 
#   mutate_at("Deaths_by_RVotes_n", ~(scale(.) %>% as.vector))

CorrelationPlots<-FinalDataset[c(34,35,36,37,38,39,40,41)]
CorrelationPlots$Deaths<-CorrelationPlots$DeathsPer100K_n
CorrelationPlots$RShare<-CorrelationPlots$RShare_n
CorrelationPlots$Density<-CorrelationPlots$Density_n
CorrelationPlots$Income<-CorrelationPlots$personalincomepercaptia_n
CorrelationPlots$old<- CorrelationPlots$Pop_65Yrs_Plus_Pct_n
CorrelationPlots$White<-CorrelationPlots$Pop_White_Pct_n
CorrelationPlots$RShare16<-CorrelationPlots$Rshare_16_n
CorrelationPlots$Change_per_RShare<-CorrelationPlots$Percentage_change_Rshare_n
CorrelationPlots<-CorrelationPlots[c(-1,-2,-3,-4,-5,-6,-7,-8)]

cor.plot(CorrelationPlots,cex=0.9)

TestCor<- FinalDataset[ which(FinalDataset$Percentage_change_Rshare_n < 3), ]

#Population density and White population
DS1<-plot(TestCor$Density_n, TestCor$Pop_White_Pct_n,
     xlab = "Population Density",
     ylab = "Percentage population of Whites",
     main="Relationship between Population Density \n and Percentage Whites")
abline(lm(TestCor$Pop_White_Pct_n~TestCor$Density_n))

cor(FinalDataset$Density_n, FinalDataset$Pop_White_Pct_n)

#per capita income and population density
DS2<-plot(FinalDataset$personalincomepercaptia_n, FinalDataset$Density_n,
     xlab = "Per Capita Income",
     ylab = "Population Density",
     main="Relationship between Per Capita Income \n and Population Density")
abline(lm(FinalDataset$Density_n~FinalDataset$personalincomepercaptia_n))

cor(FinalDataset$personalincomepercaptia_n, FinalDataset$Density_n)

#Density and COVID Deaths
DS3<-plot(FinalDataset$Density_n, FinalDataset$DeathsPer100K_n,
     xlab = "Population Density",
     ylab = "COVID Deaths per 100K",
     main="Relationship between Population Density \n and COVID Deaths per 100K")
abline(lm(FinalDataset$DeathsPer100K_n~FinalDataset$Density_n))

cor(FinalDataset$Density_n, FinalDataset$DeathsPer100K_n)

#Density and Deaths / republican share
plot(FinalDataset$Density_n, FinalDataset$Deaths_by_RVotes_n,
     xlab = "Population Density",
     ylab = "Deaths to Republican share ratio",
     main="Relationship between Population Density \n and Deaths to Republican share ratio")
abline(lm(FinalDataset$Deaths_by_RVotes_n~FinalDataset$Density_n))

cor(FinalDataset$Density_n, FinalDataset$Deaths_by_RVotes_n)

#White population and Deaths / Republican share
plot(FinalDataset$Pop_White_Pct_n, FinalDataset$Deaths_by_RVotes_n,
     xlab = "Percentage Whites",
     ylab = "Deaths to Republican share ratio",
     main="Relationship between Percentage Whites \n and Deaths to Republican share ratio")
abline(lm(FinalDataset$Deaths_by_RVotes_n~FinalDataset$Pop_White_Pct_n))

cor(FinalDataset$Pop_White_Pct_n, FinalDataset$Deaths_by_RVotes_n)

#Age 65+ and Deaths / Republican share
plot(FinalDataset$Pop_65Yrs_Plus_Pct_n, FinalDataset$Deaths_by_RVotes_n,
     xlab = "Population aged 65+",
     ylab = "Deaths to Republican share ratio",
     main="Relationship between Population age 65+ \n and Deaths to Republican share ratio")
abline(lm(FinalDataset$Deaths_by_RVotes_n~FinalDataset$Pop_65Yrs_Plus_Pct_n))

cor(FinalDataset$Pop_65Yrs_Plus_Pct_n, FinalDataset$Deaths_by_RVotes_n)


#Sec  7: Summary Statistics ---------------------------------------------------

#Summary statistics table
library(vtable)
st(FinalDataset, vars = c('Population', 'DeathsPer100K','RVotes','personalincomepercaptia','jun01completenesspct',
                          'sep01completenesspct', 'jan01completenesspct', 'apr13completenesspct', 'density',
                          'Population Aged 65 Years and Older (%)',
                          'Percentage of Population - White alone, Not Hispanic or Latino'))

#Sec  8:Ordinary Least Squares Models and Regression Tables---------

#Vaccine Penetration Reduces COVID Deaths
Deaths_Sep2021 <- lm(DeathsPer100K_n~vac_sep21+Density_n+personalincomepercaptia_n+
                     Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)
Deaths_Jan2022<- lm(DeathsPer100K_n~vac_jan22+Density_n+personalincomepercaptia_n+
                      Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)
Deaths_April2022 <- lm(DeathsPer100K_n~vac_apr22+Density_n+personalincomepercaptia_n+
                         Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)


#Republican Vote Shares Reduces Vaccine Penetration
Sep2021_Rshare <- lm(vac_sep21~RShare_n+Density_n+personalincomepercaptia_n+
                       Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)
Jan2022_Rshare <- lm(vac_jan22~RShare_n+Density_n+personalincomepercaptia_n+
                       Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)
April2022_Rshare <- lm(vac_apr22~RShare_n+Density_n+personalincomepercaptia_n+
                         Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)

#Republican Vote Shares Increases COVID Deaths

Deaths_Rshare <- lm(DeathsPer100K_n~RShare_n+Density_n+personalincomepercaptia_n+
                      Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n,data = FinalDataset)


Diff_Diff_RShare<-lm(DeathsPer100K_n~RShare_n+Density_n+personalincomepercaptia_n+
                      Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n + vac_jan22+
                      RShare_n*vac_jan22,data = FinalDataset)
Diff_Diff_ChangePer<-lm(DeathsPer100K_n~Percentage_change_Rshare_n+Density_n+personalincomepercaptia_n+
                          Pop_65Yrs_Plus_Pct_n+Pop_White_Pct_n + vac_jan22+
                          Percentage_change_Rshare_n*vac_jan22,data = FinalDataset)


#Summary of the regression
summary(Deaths_Rshare)
summary(Diff_Diff_RShare)
summary(Diff_Diff_ChangePer)

#Regression table, Deaths per 100k ~ various vaccination dates + all others
library(jtools)
library(huxtable)
library(officer)
library(flextable)
library(openxlsx)

export_summs(Deaths_Sep2021, Deaths_Jan2022, Deaths_April2022, scale = TRUE,
             model.names = c("Sep 2021","Jan 2022","April 2022"),
             coefs = c("% Vaccinated Sep 21"="vac_sep21",
                       "Population Density"="Density_n",
                       "Per capita income"="personalincomepercaptia_n" ,
                       "% Vaccinated Jan 22"="vac_jan22",
                       "% Vaccinated April 22"="vac_apr22",
                       "% Population 65 and + "="Pop_65Yrs_Plus_Pct_n",
                       "% White Population"="Pop_White_Pct_n"),
             to.file="xlsx", file.name="RegTable1.xlsx")

summary(Deaths_Rshare)
#Regression table, Various Vaccination Dates ~ Republican Share + all others
export_summs(Sep2021_Rshare, Jan2022_Rshare, April2022_Rshare, scale = TRUE,
             model.names = c("Sep 2021","Jan 2022","April 2022"),
             coefs = c("Republican share"="RShare_n",
                       "Population Density"="Density_n",
                       "Per capita income"="personalincomepercaptia_n",
                       "% Population 65 and + "="Pop_65Yrs_Plus_Pct_n",
                       "% White Population"="Pop_White_Pct_n"),
             to.file="xlsx", file.name="RegTable2.xlsx")

#Regression table, Deaths per 100k ~ Republican Share + all others
export_summs(Deaths_Rshare, scale = TRUE,
             model.names = "Deaths vs RShare",
             coefs = c("Republican share"="RShare_n",
                       "Population Density"="Density_n",
                       "Per capita income"="personalincomepercaptia_n",
                       "% Population 65 and + "="Pop_65Yrs_Plus_Pct_n",
                       "% White Population"="Pop_White_Pct_n"),
             to.file="xlsx", file.name="RegTable3.xlsx")

#Regression table, for difference in difference models
export_summs(Diff_Diff_RShare, Diff_Diff_ChangePer, scale = TRUE,
             model.names = c("Diff&Diff RShare","Diff&Diff PerChange"),
             coefs = c("Republican share"="RShare_n",
                       "% Change in RShare"="Percentage_change_Rshare_n",
                       "Population Density"="Density_n",
                       "Per capita income"="personalincomepercaptia_n",
                       "% Population 65 and + "="Pop_65Yrs_Plus_Pct_n",
                       "% White Population"="Pop_White_Pct_n",
                       "% Vaccinated Jan 2022"="vac_jan22"),
             to.file="xlsx", file.name="RegTable4.xlsx")
#Combined plots
library(broom.mixed)
plot_summs(Deaths_Sep2021, Deaths_Jan2022, Deaths_April2022, scale = TRUE,
           model.names = c("Sep 2021","Jan 2022","April 2022"),
           plot.distributions = TRUE)

plot_summs(Sep2021_Rshare, Jan2022_Rshare, April2022_Rshare, scale = TRUE,
           model.names = c("Sep 2021","Jan 2022","April 2022"),
           plot.distributions = TRUE)


#Sec  9: Causal Inference with DAGs------------------------------------

library(dagitty)
library(ggdag)

deaths_dag <- dagify(cd ~ vh,
                     vh~pb,
                     pb~fn+tsm+crp,
                     cd~pb,
                     labels = c("cd"="Covid Deaths",
                                "pb"="Votes for Republican \n Party in 2020",
                                "vh"="Continued Vaccine Hesitancy",
                                "fn"="Fake News",
                                "tsm"="COVID-19 Skepticism from \n Official Republican Leadership",
                                "crp"="Mistrust in US Government \n and Medical Research"),
                      latent="pb",
                      exposure="vh",
                      outcome="cd")
ggdag_dseparated(deaths_dag, controlling_for = "cd", 
                 text = FALSE, use_labels = "label")

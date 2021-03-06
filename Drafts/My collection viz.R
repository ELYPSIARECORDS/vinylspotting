setwd("~/Documents/R bobs/Discogs API")

###### CONNECT TO DISCOGS API & TEST REQUESTS ######

library(jsonlite)
library(httr)
library(RCurl)

#consumer key + consumer secret
# Your consumer key and consumer secret generated by discogs when an application is created
# and registered . See http://www.discogs.com/settings/developers . These credentials
# are assigned by application and remain static for the lifetime of your discogs application.
consumer_key <- "BEKNNZckQTZGTkinGrSE"
consumer_secret <-"CeJArzdbkbYRuRiJETWtTWEqXDdqLTZC"

#oauth end-points  
# The following oauth end-points are defined by discogs.com staff. These static endpoints
# are called at various stages of oauth handshaking.
Request_Token_URL	<- "https://api.discogs.com/oauth/request_token"
Authorize_URL	<- "https://www.discogs.com/oauth/authorize"
Access_Token_URL <- "https://api.discogs.com/oauth/access_token"

#create unique user agent id
user_agent <-  'DiscogsViz/1.0'


##### RETRIEVE MY COLLECTION ######

#adding the folder/releases suffix
ewen <- getURL("https://api.discogs.com//users/ewen_henderson/collection/folders/0/releases", httpheader = c('User-Agent' = user_agent))
ewen <- fromJSON(ewen)
#This works! but only retrieves one page of results i.e. 50 records

#Pagination - this is how to retrieve more than one page of data
baseurl <- "https://api.discogs.com//users/ewen_henderson/collection/folders/0/releases"
pages <- list()
for(i in 1:20){
  mydata <- fromJSON(paste0(baseurl, "?page=", i), flatten=TRUE)
  message("Retrieving page ", i)
  pages[[i+1]] <- mydata$releases
}

#pagination request success, now binding these requests into one df
library(plyr)
my.collection <- rbind.pages(pages)
library(data.table)
my.collection<- as.data.table(my.collection)


###### CLEANING ######

library(dplyr)
glimpse(my.collection)

#getting date added into a proper format
library(lubridate)
my.collection$date_added <- ymd_hms(my.collection$date_added)

#mopping up the rest

labels <- rbindlist(my.collection$basic_information.labels, fill=TRUE)
formats <- rbindlist(my.collection$basic_information.formats, fill=TRUE)
artists <-  as.data.frame(rbindlist(my.collection$basic_information.artists, fill=TRUE))

ldply(my.collection$basic_information.labels, data.frame)

#joining the data together


##### EXPLORING THE RECS #####

require(ggplot2)

#most freq artist
top_artists <- count(artists$name) %>%
  arrange(desc(freq)) %>%
  filter(x != "Various") %>%
  top_n(10)

ggplot(top_artists, aes(x, freq)) +
  geom_bar(stat = "identity")

#most freq label
top_labels <- count(labels$name) %>%
  arrange(desc(freq)) %>%
  top_n(10)

ggplot(top_labels, aes(x, freq)) +
  geom_bar(stat = "identity")

#How many recs am I buying over time?
my.collection.time <- my.collection %>%
  mutate(month_add = format(date_added, "%m"), year_add = format(date_added, "%Y"), date_add = as.Date(date_added))

ggplot(my.collection.time, aes(date_add)) +
  geom_point(stat = "count")
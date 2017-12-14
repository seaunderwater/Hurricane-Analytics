# Imports ----------------------------------------------------------------------
#install.packages("devtools")
#library(devtools)
#devtools::install_github("dgrtwo/gganimate")
# Also install imageMagick and add to path

x <- c("plyr", "dplyr", "ggplot2", "maps", "gganimate", "ggthemes")
#install.packages(x)
lapply(x, library, character.only = TRUE)

# Variables --------------------------------------------------------------------
rm(list=ls())
options(stringsAsFactors = FALSE)
#Geographic bounds to plot in
coord_xmin <- -122
coord_xmax <- -60
coord_ymin <- 13
coord_ymax <- 50
nhc_prefix <- "http://www.nhc.noaa.gov/archive/2016/al14/al142016.fstadv."
max_forecast_n <- 47

# Web Scraping -----------------------------------------------------------------
# create empty dataframes
track.df <- data.frame(forecast_n = numeric(),
                       forecast_date = character(),
                       lat = numeric(),
                       long = numeric(),
                       winds = numeric())
prediction.df <- data.frame(forecast_n = numeric(),
                            forecast_date = character(),
                            prediction_date = character(),
                            lat = numeric(),
                            long = numeric())
for(forecast_n in 1:max_forecast_n){
  #remove special forecast #8
  if(forecast_n == 8) next
  if(forecast_n > 8) forecast_n <- forecast_n - 1
  # load NOAA forecast
  forecast <- readLines(paste0(nhc_prefix, formatC(forecast_n, width=3,
                                                   format="d", flag="0"), 
                               ".shtml?"))
  
  # current winds
  current_winds <- grep("MAX SUSTAINED WINDS .*", forecast, value=T) %>%
    gsub("MAX SUSTAINED WINDS *([0-9]*) KT.*", "\\1", .) %>%
    as.numeric
  
  # current track
  current_track <- grep("REPEAT...CENTER LOCATED NEAR .*", forecast, 
                        value=T) %>%
    gsub(".* NEAR ([0-9\\.]*)(N|S) *([0-9\\.]*)(E|W) AT ([0-9/Z]*)", "\\5_\\1_\\
         2_\\3_\\4", .) %>%
    strsplit("_") %>%
    unlist
  # convert to dataframe
  current_track.df <- data.frame(forecast_n = forecast_n,
                                 forecast_date = current_track[1], 
                                 lat = as.numeric(current_track[2])*
                                   ifelse(current_track[3]=="N", 1, -1),
                                 long = as.numeric(current_track[4])*
                                   ifelse(current_track[5]=="E", 1, -1),
                                 winds = current_winds)
  track.df <- rbind(track.df, current_track.df)
  
  # add current location to prediction data frame
  current_track.df$prediction_date <- current_track.df$forecast_date
  prediction.df <- rbind(prediction.df, current_track.df[c("forecast_n",
                                                           "forecast_date",
                                                           "prediction_date",
                                                           "lat", "long")])
  
  # get date
  display_date <- grep("([0-9]{3,4}) UTC ([A-Z]*) ([A-Z]*) ([0-9]*) ([0-9]{4})",
                       forecast, value=T) %>%
    gsub("([0-9]{1,2})00 UTC (.*) ([0-9]{4})", "\\2 \\1:00 UTC", .)
  # get current prediction and convert to data frame
  current_prediction.df <- grep("FORECAST VALID .*|OUTLOOK VALID .*", forecast,
                                value=T) %>%
    gsub(".*VALID ([0-9/Z]*) ([0-9\\.]*)(N|S) *([0-9\\.]*)(E|W).*", "\\1_\\2_\\
         3_\\4_\\5", .) %>%
    strsplit("_") %>%
    do.call(rbind.data.frame, .)
  colnames(current_prediction.df) <- c("prediction_date","lat","n_s","long",
                                       "e_w")
  current_prediction.df$lat <- as.numeric(current_prediction.df$lat) * 
    ifelse(current_prediction.df$n_s=="N", 1, -1)
  current_prediction.df$long <- as.numeric(current_prediction.df$long) * 
    ifelse(current_prediction.df$e_w=="E", 1, -1)
  current_prediction.df$forecast_n <- forecast_n
  current_prediction.df$forecast_date <- current_track.df$forecast_date
  current_prediction.df <- current_prediction.df[c("forecast_n", 
                                                   "forecast_date",
                                                   "prediction_date",
                                                   "lat", "long")]
  
  # add current prediction to predictions data frame
  prediction.df <- rbind(prediction.df, current_prediction.df)
}

# Hurricane Plotter ------------------------------------------------------------
plot_hurricane <- function(hurricane){
  world <- map_data("world")
  p <- ggplot(data=hurricane, aes(x=long.y, y=lat.y, size=winds,
                                  group=forecast_n, frame=forecast_n)) +
    borders("world", colour=rgb(95,95,95, maxColorValue = 255), size=0.1, 
            fill=rgb(99,99,99, maxColorValue = 255)) +
    borders("lakes", colour=rgb(112,128,144, maxColorValue = 255), 
            fill=rgb(112,128,144, maxColorValue = 255)) +
    borders("state", colour=rgb(115,115,115, maxColorValue = 255), 
            fill=rgb(149,149,149,maxColorValue = 255)) +
    geom_path(aes(x=long.y, y=-lat.y), color = 'yellow', size=2.5,alpha=.5) +
    geom_point(aes(x=long.x, y=-lat.x), alpha = .9) +
    scale_size_area(guide = guide_legend(title = "Category")) +
    coord_cartesian(xlim = c(coord_xmin, coord_xmax),
                    ylim = c(coord_ymin, coord_ymax)) +
    ggtitle("Date: ") +
    theme_map() +
    theme(panel.background = element_rect(fill = "#708090",
                                          colour = "#708090"),
          panel.grid.major = element_blank(),
          legend.background = element_rect(fill = rgb(112,128,144,
                                                      maxColorValue = 255),
                                           colour = rgb(112,128,144,
                                                        maxColorValue = 255)))
  
  return(p)
}

# Twitter Data -----------------------------------------------------------------
twitter2 <- read.csv("finalResult2.csv")
twitter1 <- read.csv("finalResult.csv")
twitter <- rbind(twitter2, twitter1)

#Takes off the degrees and converts to numeric in a lazy way
twitter[,2] <- as.numeric(substr(as.character(twitter[,2]),start=1,stop=7))
twitter[,3] <- as.numeric(substr(as.character(twitter[,3]),start=1,stop=7))

#Logitude and Latitude were reversed
twitter[,2:3] <- twitter[,3:2]
twitter[,2] <- -twitter[,2]
#Groups every 6 hours to correspond with forecast announcements
twitter[,1] <- round(twitter[,1]/6) + 1
names(twitter) <- c("date", "long", "lat", "sentiment")

#Gets average city sentiment for each frame
twitter1 <- data.frame()
for(i in 1:max(twitter$date)) {
  temp <- twitter[twitter$date==i,]
  twitter1 <- rbind(twitter1, ddply(temp, 'long', numcolwise(mean)))
}
twitter <- twitter1
# Excluding outliers
Q1 <- quantile(twitter$sentiment, .25)
Q3 <- quantile(twitter$sentiment, .75)
upper <- Q3+4*(Q3-Q1)
lower <- Q1-4*(Q3-Q1)

plot(twitter$sentiment)
abline(a=upper,b=0,col='red')
abline(a=lower,b=0,col='red')

twitter <- twitter[-c(which(twitter$sentiment < lower),
                        which(twitter$sentiment > upper)),]
a <- data.frame(twitter$sentiment)
ggplot(a) +
  stat_density(aes(x=twitter.sentiment), geom='area', fill = 'red',
               color = 'red', alpha = .3)

# Data Cleaning ----------------------------------------------------------------
track.df <- track.df[complete.cases(track.df),]
prediction.df <- prediction.df[complete.cqases(prediction.df),]

hurricane <- merge(track.df,prediction.df[,c(1,4,5)],by="forecast_n")

category <- function(winds) {
  if(winds < 73) return(0)
  else if(winds < 95) return(1)
  else if(winds < 110) return(2)
  else if(winds < 129) return(3)
  else if(winds < 156) return(4)
  else if(winds >= 156) return(5)
  else return(NA)
}

hurricane$winds <- sapply(hurricane$winds, category)

# Twitter Plotter --------------------------------------------------------------
twitterMap <- function(p, twitter){
  p <- p +
    geom_point(data=twitter, aes(x=long, y=lat, color = sentiment, size = 10, 
                                 frame = date), alpha = 1) +
    scale_color_gradient2(low=rgb(0.758, 0.214, 0.233), 
                          mid=rgb(0.865, 0.865, 0.865),
                          high=rgb(0.085, 0.532, 0.201),
                          midpoint = mean(twitter$sentiment))

  return(p)
}

# Animation --------------------------------------------------------------------
p <- plot_hurricane(hurricane)
p <- twitterMap(p, twitter)
gganimate(p, 'hurricane.gif', interval = .75, ani.width=1100, ani.height=900, 
          ani.res=200)
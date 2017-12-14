
library(jsonlite)
library(plyr)
library(data.table)
args <- commandArgs(TRUE)
dir <- args[1]
output <- args[2]

files <- list.files(dir,recursive=T, full.names = TRUE)
file.create(output, overwrite=TRUE)

#output csv


for(i in 1:length(files)) {
  data = data.frame()
  filename <- files[i]
  input = file(filename, "r")
  while ( TRUE ) {
    
    line <-try(readLines(input, n = 1))
    if ( length(line) == 0 ) {
      break
    }
   
   jObj <- try(fromJSON(line))
   try({
   if(jObj$lang == "en" && !is.null(jObj$user$location) && !is.null(jObj$user$time_zone)) {
     myList <- lapply(jObj, lapply, function(x) if (is.null(x)) {NA} else {x})
     date <- myList$created_at
     tweet <- myList$text
     location <- myList$user$location
     time_zone <- myList$user$time_zone
     user <- myList$user$screen_name
     info<-data.frame(date,tweet,location,time_zone,user)
     colnames(info) <- c('date', 'tweet', 'location', 'time_zone', 'user')
     data <- rbind(data, info)
   }
   }) 
  }
  
  #fwrite is much faster than write.csv
  try(fwrite(data, file = output, sep = ",", append=TRUE))
  close(input)
  
}


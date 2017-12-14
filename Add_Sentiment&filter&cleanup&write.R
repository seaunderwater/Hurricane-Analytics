install.packages("syuzhet")
install.packages("tidyr");

library(syuzhet)
library(dplyr)
library(tidyr)
library(data.table)
#create an output file path
output <- '/Users/Shuqi/Downloads/bigFile2.csv'
#working directory
dir <- '/Users/Shuqi/Downloads/data_for_analysis'
#list of files
files <- list.files(dir,recursive=T, full.names = TRUE)
#create the output file and make if overwritable
file.create(output, overwrite=TRUE)
#loop through all files in the fileList, we skipped DS_Store file by skipping i = 73 and i = 217
for(i in 218:255) {
  filename <- files[i]
  input = file(filename, "r")
  data <- read.csv(filename)
  #add column names
  colnames(data) <- c("time", "twt", "location", "time_zone", "user")
  #subset of timezone to reduce the number of data
  asdf = subset(data, time_zone=="Pacific Time (US & Canada)" | time_zone=="Eastern Time (US & Canada)" | time_zone=="Central Time (US & Canada)" | time_zone=="Mountain Time (US & Canada)")
  #separate the twitter location by comma in order to find the exact match
  temp <- asdf %>%
    separate(location, c("foo", "bar"), ",")
  #analyze twit to add sentiment
  temp$sentiment = get_sentiment(as.character(temp[,2]), method="syuzhet")
  #remove twts, timezone, and usernames
  temp = temp[,c(-2, -4, -5, -6)]
  #write to the output file
  fwrite(temp, file = output, sep = ",", append=TRUE)
  #close input file
  close(input)
}
#close output file
 close(output)


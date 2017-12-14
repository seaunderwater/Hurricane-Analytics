library(data.table)
output <- '/Users/mbhatia4336/Downloads/bigFile.csv'
dir <- '/Users/mbhatia4336/Downloads/data_for_analysis'
files <- list.files(dir,recursive=T, full.names = TRUE)
file.create(output, overwrite=TRUE)

for(i in 1:4) {
  filename <- files[i]
  input = file(filename, "r")
  data <- read.csv(filename)
  fwrite(data, file = output, sep = ",", append=TRUE)
  close(input)
}

close(output)
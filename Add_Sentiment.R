#install.packages("syuzhet")
library(syuzhet)

asdf = read.csv("C:\\Users\\Pete\\Documents\\RStudio\\input.csv")
asdf$sentiment = get_sentiment(as.character(asdf[,2]), method="syuzhet")
write.csv(asdf, file="C:\\Users\\Pete\\Documents\\RStudio\\output_with_sentiment.csv")

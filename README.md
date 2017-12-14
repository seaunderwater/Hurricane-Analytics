# Hurricane-Analytics

The scripts in this repository are used to plot the path and predicted path of Hurricane Matthew (Sep.28,2016- Oct.9,2016), and perform sentiment analysis on twitter data for the 100 most populated cities in the United States. Results of the analysis are plotted on a blank map of the northwestern hemisphere.

<img src="https://github.com/seaunderwater/Hurricane-Analytics/blob/master/hurricane.gif" style="width:300px;height:300px;"/>

* 36.json: sample file containing 1 minute of tweets from October 27, 2016.
* test.sh: shell script for our deployment on DigitalOceans. The script untar's data, decompresses bzip2 via bunzip2, and runs our data cleaning script. 
* jsonParser.R: recursively reads folders containing .json files and uses the jsonlite R package to clean the data. fwrite() from the data.table package is used to create an output.csv containing the cleaned data. 
* US_filter.R: 
* Add_Sentiment&filter&cleanup&write.R: filters tweets to preserve only those that occurred in the United States and performs sentiment analysis on those tweets using the syuzhet R package. Creates an output.csv with the results of sentiment analysis. 
* myHurricane.R: contains code to plot the path and predicted path of Hurricane Matthew, and the sentiment for top 100 most populated U.S. cities.

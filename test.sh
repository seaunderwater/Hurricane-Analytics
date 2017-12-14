tar -xvf $1
wait
find -name "*.bz2" | xargs bunzip2 
wait
Rscript jsonParser.R $2 $2.csv
wait
rm $1
wait
rm -rf $2
wait

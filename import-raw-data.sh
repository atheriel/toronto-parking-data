#!/bin/bash

# This script unzips any downloaded files, converts them to UTF-8 if necessary,
# and then imports those files into the staging table using an R script.

# Unzip files.

# for file in raw-data/parking_tickets_*.zip; do
#     echo "[`date`] Unzipping $file"
#     unzip $file -d raw-data/ && rm $file
# done;

# 2010 and 2008 appear to be UTF-16LE encoded, so use iconv to rewrite them.

echo "[`date`] Converting some files to UTF-8."

if [ -e "raw-data/Parking_Tags_data_2008.csv"]; then
    iconv -f UTF-16LE -t UTF-8 "raw-data/Parking_Tags_data_2008.csv" > "raw-data/Parking_Tags_data_2008.csv.utf8"
    mv "raw-data/Parking_Tags_data_2008.csv.utf8" "raw-data/Parking_Tags_data_2008.csv"
fi

if [ -e "raw-data/Parking_Tags_data_2010.csv"]; then
    iconv -f UTF-16LE -t UTF-8 "raw-data/Parking_Tags_data_2010.csv" > "raw-data/Parking_Tags_data_2010.csv.utf8"
    mv "raw-data/Parking_Tags_data_2010.csv.utf8" "raw-data/Parking_Tags_data_2010.csv"
fi

echo "[`date`] UTF-8 conversion finished."

# Compress CSV files for safekeeping.

for file in raw-data/*.csv; do
    ( echo "[`date`] Compressing $file"
      bzip2 -z "$file" ) &
done;
wait

echo "[`date`] Compression finished."

# Read compressed CSV files into the database.

for file in raw-data/*.csv.bz2; do
    echo "[`date`] Reading $file into staging table."
    Rscript copy-csv-to-db.R "$file" && rm "$file"
done;

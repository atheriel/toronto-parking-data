#!/bin/bash

# This script unzips any downloaded files, converts them to UTF-8 if necessary,
# and then imports those files into the staging table using an R script.

# Unzip files.

# for file in raw-data/parking_tickets_*.zip; do
#     echo "[`date`] Unzipping $file."
#     unzip $file -d raw-data/
# done;

# 2010 and 2008 appear to be UTF-16LE encoded, so use iconv to rewrite them.

# echo "[`date`] Converting some files to UTF-8."

# iconv -f UTF-16LE -t UTF-8 "raw-data/Parking_Tags_data_2008.csv" > "raw-data/Parking_Tags_data_2008.csv.utf8"
# iconv -f UTF-16LE -t UTF-8 "raw-data/Parking_Tags_data_2010.csv" > "raw-data/Parking_Tags_data_2010.csv.utf8"

# mv "raw-data/Parking_Tags_data_2008.csv.utf8" "raw-data/Parking_Tags_data_2008.csv"
# mv "raw-data/Parking_Tags_data_2010.csv.utf8" "raw-data/Parking_Tags_data_2010.csv"

# Read CSV files into the database.

for file in raw-data/*.csv; do
    echo "[`date`] Reading $file into staging table."
    Rscript copy-csv-to-db.R "$file"
done;

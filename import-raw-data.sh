#!/bin/bash

# This script unzips any downloaded files, converts them to UTF-8 if necessary,
# and then imports those files into the staging table using an R script.

# 2014 and 2015 use a different format, and must be handled separately.

unzip raw-data/parking_tickets_2014.zip -d raw-data/
unzip raw-data/parking_tickets_2015.zip -d raw-data/
rm raw-data/parking_tickets_2014.zip
rm raw-data/parking_tickets_2015.zip

for file in raw-data/Parking_Tags_Data_*.csv; do
    echo "`date`: reading $file into staging table"
    Rscript copy-csv-to-db.R "$file"
done;

# Handle the older files.

for file in raw-data/parking_tickets_*.zip; do
    echo "`date`: unzipping $file"
    unzip $file -d raw-data/
done;

for file in raw-data/parking_tickets_*.csv; do
    echo "`date`: converting $file to UTF-8"
    iconv -f UTF-16LE -t UTF-8 "$file" > "$file.utf8"
    mv "$file.utf8" "$file"
    echo "`date`: reading $file into staging table"
    Rscript copy-csv-to-db.R "$file"
done;

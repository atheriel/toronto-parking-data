#!/bin/bash

cat raw-data-urls.txt | xargs -n 1 -P 1 wget -c -P raw-data/

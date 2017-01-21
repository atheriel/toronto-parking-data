#!/bin/bash

tail +2 data/iso-3166-2.csv | sqlite3 -csv tickets.sqlite ".import /dev/stdin iso3166"


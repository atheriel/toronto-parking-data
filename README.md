# Complete Toronto Parking Ticket Database

This repository contains scripts for cleaning up and collating all of the City
of Toronto's parking tickets into a SQLite database. The approach is based on
Todd Schneider's [nyc-taxi-data](https://github.com/toddwschneider/nyc-taxi-data)
repository.

There are 22,977,863 tickets in the database at the time of writing. The data
contains the time and place each ticket was issued, the province or state of the
license plate, as well as the infraction and the associated fine.

## Building the Database

You will require the basic unix tools, `sqlite3` and `R` to build the database
from scratch.

``` shell
$ ./download-raw-data.sh
$ ./create-database.sh
$ ./import-raw-data.sh
$ ./clean-entries.sh
$ ./populate-infractions.sh
$ ./populate-tickets.sh
```

You can optionally run `./import-iso-3166-2-table.sh` to add a table mapping the
abbreviations used in the plate data to their likely jurisdictions.

## Updating the Database

The database is designed to be updated in-place with new years by using a
"staging" table containing entries that have to be cleaned up before they are
inserted into the main table. You can even edit `raw-data-urls.txt` and re-run
`download-raw-data.sh` to get the new data. After that, re-run

``` shell
$ ./import-raw-data.sh
$ ./clean-entries.sh
$ ./populate-tickets.sh
```

to insert the new tickets.

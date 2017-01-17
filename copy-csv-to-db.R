# Read the raw parking ticket CSV files into the staging table of the database.

library(methods)
library(readr)
library(dplyr, warn.conflicts = FALSE)

# Ensure that we get a valid filename as an argument.

args <- commandArgs(trailingOnly = TRUE)

if (!length(args) > 0) {
  stop("--- script expects a CSV file as an argument")
} else if (!file.exists(args[1])) {
  stop(paste("--- CSV file does not exist"))
}

# Read the CSV file in the standard format.

df <- readr::read_csv(
  file = args[1],
  col_types = cols(tag_number_masked = col_character(), # tag
                   date_of_infraction = col_character(),
                   infraction_code = col_integer(),
                   infraction_description = col_character(),
                   set_fine_amount = col_integer(),
                   time_of_infraction = col_character(),
                   location1 = col_character(),
                   location2 = col_character(),
                   location3 = col_character(),
                   location4 = col_character(),
                   province = col_character())
)

if (!exists("df")) {
  stop("--- failed to read CSV data")
}

# Connect to the SQL database and write the data to the staging table.

db <- dplyr::src_sqlite("tickets.sqlite")

if (!dplyr::db_has_table(db$con, "tickets_staging")) {
  stop("--- can't find staging table in the database")
} else if (dplyr::db_insert_into(db$con, "tickets_staging", values = df)) {
  print(paste("--- entries from", args[1], "copied to database"))
} else {
  stop("--- failed to write entries to database")
}

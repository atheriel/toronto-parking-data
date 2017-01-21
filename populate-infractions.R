# Create an infractions table in the database.

library(methods)
library(dplyr, warn.conflicts = FALSE)

db <- dplyr::src_sqlite("tickets.sqlite")

print("--- extracting infractions from staging table")

# Extract code, description, and fine combinations from the staging table.
infractions <- tbl(db, "tickets_staging") %>%
  select(code = infraction_code, desc = infraction_description,
         fine = set_fine_amount) %>%
  group_by(code, desc, fine) %>%
  summarise(freq = n()) %>%
  ungroup() %>%
  collect()

# Take the most common fine and description combinations for each code.
df <- infractions %>%
  arrange(code, desc(freq)) %>%
  group_by(code) %>%
  summarise(desc = first(desc), fine = first(fine)) %>%
  ungroup()

if (dplyr::db_insert_into(db$con, "infractions", values = df)) {
  print("--- infractions table copied to database")
} else {
  stop("--- failed to write infraction table to database")
}

-- Populates the tickets table from the staging table.

INSERT INTO tickets (date, infraction, location1, location2, province)
SELECT
-- Construct a datetime string from the two components.
  substr(`date`, 1, 4) || '-' || substr(`date`, 5, 2) || '-' ||
  substr(`date`, 7, 2) || ' ' || substr(`time`, 1, 2) || ':' ||
  substr(`time`, 3, 2),
  infraction_code,
  location2,
  location4,
  province
FROM (
  SELECT
    date_of_infraction AS date,
    time_of_infraction AS time,
    infraction_code,
    location2,
    location4,
    province
  FROM tickets_staging
  LIMIT 10000
);

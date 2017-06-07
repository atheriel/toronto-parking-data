-- Populates the tickets table from the staging table.

CREATE TEMPORARY TABLE tmp_tickets AS
SELECT
-- Construct a datetime string from the two components.
  CASE WHEN (`date` IS NOT NULL AND `time` IS NOT NULL) THEN
  (substr(`date`, 1, 4) || '-' || substr(`date`, 5, 2) || '-' ||
   substr(`date`, 7, 2) || ' ' || substr(`time`, 1, 2) || ':' ||
   substr(`time`, 3, 2))
  ELSE NULL END AS dt,
  infraction_code,
  set_fine_amount,
  location2,
  location4,
  province
FROM (
  SELECT
    date_of_infraction AS `date`,
    time_of_infraction AS `time`,
    infraction_code,
    set_fine_amount,
    location2,
    location4,
    province
  FROM tickets_staging
--  LIMIT 1000000
);

INSERT INTO tickets (`date`, infraction, fine, location1, location2, plate)
SELECT * FROM tmp_tickets
ORDER BY datetime(dt);

-- Remove staged data from the staging table.

-- DELETE FROM tickets_staging;

-- Defines the table schemas.

-- Raw data is imported into the "staging" table, and then cleaned up before
-- insertion into final table.

CREATE TABLE tickets_staging (
  tag_number_masked varchar,
  date_of_infraction varchar,
  infraction_code integer,
  infraction_description varchar,
  set_fine_amount integer,
  time_of_infraction varchar,
  location1 varchar,
  location2 varchar,
  location3 varchar,
  location4 varchar,
  province varchar
);

-- This is the "clean" table.

CREATE TABLE tickets (
  date datetime,
  infraction integer,
  location1 varchar,
  location2 varchar,
  province varchar
);

-- This table holds infraction codes and the fines associated with them.

CREATE TABLE infractions (
  code integer primary key,
  desc varchar,
  fine integer
);

-- This table holds the ISO 3166-2 codes for Canadian provinces and US states.

CREATE TABLE iso3166 (
  code varchar primary key,
  place varchar,
  country varchar
);

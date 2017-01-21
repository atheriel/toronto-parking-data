-- Update entries with clearly erroneous Quebec and Newfoundland province codes,
-- as well as the suspected no-value "XX" entry.

UPDATE tickets_staging SET province = 'QC' WHERE province = 'PQ';
UPDATE tickets_staging SET province = 'NL' WHERE province = 'NF';
UPDATE tickets_staging SET province = NULL WHERE province = 'XX';

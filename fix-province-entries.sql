-- Update entries with clearly erroneous Quebec and Newfoundland province codes.

UPDATE tickets_staging SET province = 'QC' WHERE province = 'PQ';
UPDATE tickets_staging SET province = 'NL' WHERE province = 'NF';

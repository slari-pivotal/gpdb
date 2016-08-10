create database db_test_bed;
\c db_test_bed
CREATE OR REPLACE FUNCTION int4(boolean)
  RETURNS int4 AS
$BODY$

SELECT CASE WHEN $1 THEN 1 ELSE 0 END;

$BODY$
  LANGUAGE 'sql' IMMUTABLE;

-- start_ignore
CREATE CAST (boolean AS int4) WITH FUNCTION int4(boolean) AS ASSIGNMENT;

CREATE CAST (varchar AS text) WITHOUT FUNCTION AS IMPLICIT;
-- end_ignore

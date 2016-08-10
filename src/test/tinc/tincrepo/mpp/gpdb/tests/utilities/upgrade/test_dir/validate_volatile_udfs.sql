DROP TABLE IF EXISTS newfoo;
DROP TABLE IF EXISTS newbar;
CREATE TABLE newfoo (a int, b int);
CREATE TABLE newbar (c int, d int);
INSERT INTO newfoo select i, i+1 from generate_series(1,10) i;
INSERT INTO newbar select i, i+1 from generate_series(1,10) i;
DROP FUNCTION IF EXISTS udf_mod_int_vol(x int);
CREATE FUNCTION udf_mod_int_vol(x int) RETURNS int AS $$
BEGIN
UPDATE newbar SET d = d+1 WHERE c = $1;
RETURN $1 + 1;
END
$$ LANGUAGE plpgsql VOLATILE;
SELECT d FROM newbar WHERE c = 1;
SELECT udf_mod_int_vol(1);
SELECT d FROM newbar WHERE c = 1;

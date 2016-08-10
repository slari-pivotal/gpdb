DROP TABLE IF EXISTS foo;
DROP TABLE IF EXISTS bar;
CREATE TABLE foo (a int, b int);
CREATE TABLE bar (c int, d int);
INSERT INTO foo select i, i+1 from generate_series(1,10) i;
INSERT INTO bar select i, i+1 from generate_series(1,10) i;

DROP FUNCTION IF EXISTS udf_nosql_vol(x int);
CREATE FUNCTION udf_nosql_vol(x int) RETURNS int AS $$
BEGIN
RETURN $1 + 1;
END
$$ LANGUAGE plpgsql IMMUTABLE;

DROP FUNCTION IF EXISTS udf_sql_int_vol(x int);
CREATE FUNCTION udf_sql_int_vol(x int) RETURNS int AS $$
DECLARE
    r int;
BEGIN
    SELECT $1 + 1 INTO r;
    RETURN r;
END
$$ LANGUAGE plpgsql IMMUTABLE;

DROP FUNCTION IF EXISTS udf_read_int_vol(x int);
CREATE FUNCTION udf_read_int_vol(x int) RETURNS int AS $$
DECLARE
    r int;
BEGIN
    SELECT d FROM bar WHERE c = $1 ORDER BY 1 LIMIT 1 INTO r;
    RETURN r;
END
$$ LANGUAGE plpgsql STABLE;
